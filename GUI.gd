extends CenterContainer

var grid
var nextShape

var level = 1 setget _on_HSlider_value_changed
var score = 0 setget set_score
var high_score = 0 setget set_high_score
var lines = 0 setget set_lines

signal button_pressed(button_name)

func _on_HSlider_value_changed(value):
	find_node("Level").text = str(value)
	level = value


func set_score(value):
	find_node("Score").text = "%08d" % value
	score = value


func set_high_score(value):
	find_node("HighScore").text = "%08d" % value
	high_score = value


func set_lines(value):
	find_node("Lines").text = str(value)
	lines = value


func reset_stats(_high_score = 0, _score = 0, _lines = 0):
	self.high_score = _high_score
	self.score = _score
	self.lines = _lines
	self.level = level


func settings(high_score_save):
	self.high_score = high_score_save


func _ready():
	grid = find_node("Grid")
	nextShape = find_node("NextShape")
	add_cells(grid, 200)
	clear_all_cells()


func set_next_shape(shape: ShapeData):
	clear_cells(nextShape)
	var i = 0
	for col in shape.coors.size():
		for row in [0, 1]:
			if shape.grid[row][col]:
				nextShape.get_child(i).modulate = shape.color
			i += 1


func add_cells(node, n):
	var num_cells = node.get_child_count();
	while num_cells < n:
		node.add_child(node.get_child(0).duplicate())
		num_cells += 1


func clear_all_cells():
	clear_cells(grid)
	clear_cells(nextShape)


func clear_cells(node):
	for cell in node.get_children():
		cell.modulate = Color(0)


func _on_Play_pressed():
	emit_signal("button_pressed", "Play")

func _on_Pause_pressed():
	emit_signal("button_pressed", "Pause")


func _on_Control_pressed():
	$ControlBox.popup_centered()


func _set_button_state(button, state):
	find_node(button).set_disabled(state)


func set_button_states(playing):
	_set_button_state("Play",playing)
	_set_button_state("Pause",!playing)
	_set_button_state("Control",playing)


func set_button_text(button, text):
	find_node(button).set_text(text)


func disable_slider():
	find_node("Difficulty").set_editable(false)


func enable_slider():
	find_node("Difficulty").set_editable(true)


func _on_ControlBox_popup_hide():
	_set_button_state("Control",false)
