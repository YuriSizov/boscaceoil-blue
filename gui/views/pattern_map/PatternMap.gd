###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name PatternMap extends Control

## Control size-dependent vertical size of a pattern.
var _pattern_height: float = 0
## Offset, in number of timeline bars/pattern columns.
var _scroll_offset: int = 0
## Window-size dependent limit.
var _max_scroll_offset: int = -1

var _pattern_rows: Array[PatternRow] = []
var _pattern_cols: Array[PatternCol] = []

@onready var _track: Control = $PatternMapTrack
@onready var _overlay: Control = $PatternMapOverlay
@onready var _dock: Control = $PatternMapDock


func _ready() -> void:
	set_physics_process(false)
	
	_update_pattern_height()
	_update_scroll_offset()
	resized.connect(_update_pattern_height)
	resized.connect(_update_scroll_offset)


func _physics_process(_delta: float) -> void:
	# TODO: Update the playback cursor.
	pass


func _draw() -> void:
	_update_grid()

	var available_rect := get_available_rect()
	
	var row_odd_color := get_theme_color("row_odd_color", "PatternMap")
	var row_even_color := get_theme_color("row_even_color", "PatternMap")
	var border_width := get_theme_constant("border_width", "PatternMap")
	var border_color := get_theme_color("border_color", "PatternMap")

	# Draw the background.
	draw_rect(Rect2(Vector2.ZERO, size), row_odd_color)

	# Draw the rows.
	for row in _pattern_rows:
		var row_position := row.grid_position
		var row_size := Vector2(available_rect.size.x, _pattern_height)
		var row_color := row_even_color if row.row_index % 2 else row_odd_color
		draw_rect(Rect2(row_position, row_size), row_color)

	# Draw vertical lines.
	for pattern in _pattern_cols:
		var col_position := pattern.grid_position
		var border_size := Vector2(border_width, available_rect.size.y)
		draw_rect(Rect2(col_position, border_size), border_color)


# Drawables and visuals.

func get_available_rect() -> Rect2:
	var available_rect := Rect2(Vector2.ZERO, size)
	if not is_inside_tree():
		return available_rect

	if _dock:
		available_rect.size.x -= _dock.size.x
	if _track:
		available_rect.size.y -= _track.size.y

	return available_rect


func _update_pattern_height() -> void:
	var available_rect := get_available_rect()
	_pattern_height = available_rect.size.y / Arrangement.CHANNEL_NUMBER
	
	queue_redraw()


func _update_scroll_offset() -> void:
	var available_rect := get_available_rect()
	var pattern_width := get_theme_constant("pattern_width", "PatternMap")
	var patterns_on_screen := floori(available_rect.size.x / pattern_width)
	_max_scroll_offset = Arrangement.BAR_NUMBER - patterns_on_screen + 1

	_scroll_offset = clamp(_scroll_offset, 0, _max_scroll_offset)
	queue_redraw()


func _update_grid() -> void:
	# Reset collections.
	_pattern_rows.clear()
	_pattern_cols.clear()

	# Get reference data.
	var available_rect := get_available_rect()
	var pattern_width := get_theme_constant("pattern_width", "PatternMap")

	# Iterate through all the patterns and complete collections.
	var filled_width := 0
	var index := 0
	while filled_width < (available_rect.size.x + 2 * pattern_width): # Give it some buffer.
		var pattern_index: int = index + _scroll_offset
		if pattern_index > Arrangement.BAR_NUMBER:
			break

		# Create pattern column data.
		var pattern := PatternCol.new()
		pattern.pattern_index = pattern_index
		pattern.position = Vector2(index * pattern_width, 0)
		pattern.grid_position = pattern.position + available_rect.position

		_pattern_cols.push_back(pattern)
		
		# Update counters.
		filled_width += pattern_width
		index += 1
	
	for i in Arrangement.CHANNEL_NUMBER:
		var row := PatternRow.new()
		row.row_index = i
		row.position = Vector2(0, available_rect.position.y + i * _pattern_height)
		row.grid_position = row.position + available_rect.position
		row.label_position = row.position + Vector2(0, -6)
		
		_pattern_rows.push_back(row)
	
	# Update children with the new data.
	_track.pattern_cols = _pattern_cols


class PatternRow:
	var row_index: int = -1
	var position: Vector2 = Vector2.ZERO
	var grid_position: Vector2 = Vector2.ZERO
	var label_position: Vector2 = Vector2.ZERO


class PatternCol:
	var pattern_index: int = -1
	var position: Vector2 = Vector2.ZERO
	var grid_position: Vector2 = Vector2.ZERO
