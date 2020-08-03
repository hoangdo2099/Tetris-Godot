extends CenterContainer

enum {STOPPED, PLAYING, PAUSED, STOP, PLAY, PAUSE}
enum {ROTATE_LEFT, ROTATE_RIGHT}

const DISABLED = true
const ENABLED = false
const MAX_LEVEL = 10
const START_POS = 5
const END_POS =  25
const TICK_SPEED = 1.0
const FAST_MULTIPLE = 10
const WAIT_TIME = 0.15
const REPEAT_DELAY = 0.05
const HARD_DROP_TICK = 0.01
const FILE_NAME = "user://tetris.json"


var gui
var state = STOPPED
var grid = []
var cols
var shape: ShapeData
var next_shape: ShapeData
var pos = 0
var count = 0
var bonus = 0
var harddrop_pos

func _ready():
	gui = $GUI
	gui.connect("button_pressed",self,"_button_pressed")
	cols = gui.grid.get_columns()
	gui.reset_stats()
	load_game()
	randomize()

func clear_grid():
	grid.clear()
	grid.resize(gui.grid.get_child_count())
	for i in  grid.size():
		grid[i] = false
	gui.clear_all_cells()

func rotate(dir):
	match dir:
		ROTATE_LEFT:
			shape.rotate_left()
			dir = ROTATE_RIGHT
		ROTATE_RIGHT:
			shape.rotate_right()
			dir = ROTATE_RIGHT
	return dir

func move_shape(new_pos, dir = null):
	remove_shape_from_grid()
	dir = rotate(dir)
	var ok = place_shape(new_pos)
	if ok:
		pos = new_pos
	else:
		rotate(dir)
	add_shape_to_grid()
	return ok
	
func add_shape_to_grid():
	place_shape(pos, true, false, shape.color)
	
func remove_shape_from_grid():
	place_shape(pos, true)

func lock_shape_to_grid():
	place_shape(pos, false, true)
	

func place_shape(index, add_tiles = false, lock = false, color = Color(0)):
	var ok = true
	var size = shape.coors.size()
	var offset = shape.coors[0]
	var y = 0
	while y < size and ok:
		for x in size:
			if shape.grid[y][x]:
				var grid_pos = index + (y + offset) * cols + x + offset
				#print(grid_pos)
				if lock:
					grid[grid_pos] = true
				else:
					var gx = index % cols + x + offset
					if gx < 0 or gx >= cols or grid_pos >= grid.size() or grid_pos >= 0 and grid[grid_pos]:
						ok = !ok
						break
					if add_tiles and grid_pos >= 0:
						gui.grid.get_child(grid_pos).modulate = color
		y += 1
	return ok
	
func _button_pressed(button_name):
	match button_name:
		"Play":
			gui.set_button_states(DISABLED)
			gui.disable_slider()
			_start_game()
		
		"Pause":
			if state == PLAYING:
				gui.set_button_text("Pause", "Resume")
				state = PAUSED
				pause() # Also, set pause mode of GUI to Process
			else:
				gui.set_button_text("Pause", "Pause")
				state = PLAYING
				pause(false)
		"Control":
			gui.set_button_state("Control", DISABLED)


func _input(event):
	if state == PLAYING:
		if event.is_action_pressed("ui_down"):
			bonus = 1
			soft_drop()
		if event.is_action_released("ui_down"):
			bonus = 0
			normal_drop()
		if event.is_action_pressed("ui_accept"):
			hard_drop()
			bonus = 10
		if event.is_action_pressed("ui_left"):
			move_left()
			$LeftTimer.start(WAIT_TIME)
		if event.is_action_released("ui_left"):
			$LeftTimer.stop()
		if event.is_action_pressed("ui_right"):
			move_right()
			$RightTimer.start(WAIT_TIME)
		if event.is_action_released("ui_right"):
			$RightTimer.stop()
		if event.is_action_pressed("ui_up"):
			if event.shift:
				move_shape(pos, ROTATE_RIGHT)
			else:
				move_shape(pos, ROTATE_LEFT)
		if event.is_action_pressed("ui_cancel"):
			_game_over()
		if event is InputEventKey:
			get_tree().set_input_as_handled()


func _start_game():
	print("Game playing")
	state = PLAYING
	clear_grid()
	gui.reset_stats(gui.high_score)
	new_shape()

func new_shape():
	if next_shape:
		shape = next_shape
	else:
		shape = Shapes.get_shape()
	next_shape = Shapes.get_shape()
	gui.set_next_shape(next_shape)
	pos = START_POS
	add_shape_to_grid()
	normal_drop()

func pause(value = true):
	get_tree().paused = value

func level_up():
	if gui.lines > gui.level * 5:
		increase_level()


func increase_level():
	if gui.level < MAX_LEVEL:
		gui.level += 1
		$Ticker.set_wait_time(TICK_SPEED / gui.level)


func normal_drop():
	$Ticker.start(TICK_SPEED / gui.level)


func soft_drop():
	$Ticker.stop()
	$Ticker.start(TICK_SPEED / gui.level / FAST_MULTIPLE)


func hard_drop():
	$Ticker.stop()
	$Ticker.start(HARD_DROP_TICK)


func _game_over():
	$Ticker.stop()
	$LeftTimer.stop()
	$RightTimer.stop()
	gui.set_button_states(ENABLED)
	gui.enable_slider()
	state = STOPPED
	print("Game stopped")
	save_game()

func add_to_score(rows):
	gui.lines += rows
	level_up()
	var score = 100 * int(pow(2, rows - 1))
	print("Added %d to score" % score)
	gui.score += score
	update_high_score()	

func update_high_score():
	if gui.score > gui.high_score:
		gui.high_score = gui.score


func move_left():
	if pos % cols > 0:
		move_shape(pos - 1)


func move_right():
	if pos % cols < cols - 1:
		move_shape(pos + 1)


func _on_Ticker_timeout():
	var new_pos = pos + cols
	print(new_pos)
	if move_shape(new_pos):
		gui.score += bonus
		bonus = 0
		update_high_score()
	else:
		if new_pos <= END_POS:
			_game_over()
		else:
			lock_shape_to_grid()
			check_rows()
			new_shape()


func _on_LeftTimer_timeout():
	$LeftTimer.wait_time = REPEAT_DELAY
	move_left()


func _on_RightTimer_timeout():
	$RightTimer.wait_time = REPEAT_DELAY
	move_right()


func check_rows():
	var i = grid.size() -1
	var x = 0
	var row_number = 19
	var rows = []
	while i >= 0:
		if grid[i]:
			x += 1
			i -= 1
			if x == cols: # complete row found
				rows.append(row_number)
				x = 0
				row_number -= 1
		else:
			# empty cell found
			i += x # set i to right-most column
			x = 0
			i -= cols # move i to next row
			row_number -= 1
	if rows.empty() == false:		
		remove_rows(rows)

func remove_rows(rows):
	var rows_moved = 0
	add_to_score(rows.size())
	pause()
	yield(get_tree().create_timer(0.3), "timeout")
	pause(false)	
	remove_shape_from_grid()
	for row_count in rows.size():	
		# Hide cells
		for n in cols:
			gui.grid.get_child((rows[row_count] + rows_moved) * cols + n).modulate = Color(0)
		# Move cells
		var to = (rows[row_count] + rows_moved) * cols + cols - 1
		var from = to - cols 
		while from >= 0:
			grid[to] = grid[from]
			gui.grid.get_child(to).modulate = gui.grid.get_child(from).modulate
			if from == 0: # Clear the top row
				grid[from] = false
				gui.grid.get_child(from).modulate = Color(0)
			from -= 1
			to -= 1
		rows_moved += 1
	add_shape_to_grid()

func save_game():
	var high_score_save = gui.high_score
	var file = File.new()
	file.open(FILE_NAME, File.WRITE)
	file.store_string(to_json(high_score_save))
	file.close()


func load_game():
	var file = File.new()
	if file.file_exists(FILE_NAME):
		file.open(FILE_NAME, File.READ)
		var high_score_save = parse_json(file.get_as_text())
		print(high_score_save)
		gui.settings(high_score_save)
