###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A tiny bespoke popup management system to avoid using viewports for simple
## panels.
class_name PopupManager extends CanvasLayer

enum Direction {
	BOTTOM_RIGHT,
	BOTTOM_LEFT,
	TOP_RIGHT,
	TOP_LEFT,
	OMNI,
}

static var _instance: PopupManager = null

var _active_popups: Array[PopupControl] = []
var _blocking_popups: Array[PopupControl] = []
@onready var _click_catcher: Control = $ClickCatcher


func _init() -> void:
	if _instance:
		printerr("PopupManager: Only one instance of PopupManager is allowed.")
		return
	
	_instance = self


func _ready() -> void:
	_click_catcher.visible = _active_popups.size() > 0
	_click_catcher.gui_input.connect(_handle_catcher_clicked)
	_click_catcher.draw.connect(_draw_catcher)


func _draw_catcher() -> void:
	var background_color := _click_catcher.get_theme_color("click_catcher_color", "PopupManager")
	_click_catcher.draw_rect(Rect2(Vector2.ZERO, _click_catcher.size), background_color)


# Input events.

func _handle_catcher_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton && not event.is_pressed(): # Activate on mouse release.
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			PopupManager.hide_all_blocking_popups()
			return


func _handle_popup_clicked(popup: PopupControl) -> void:
	# Close all popups on top of the clicked one.
	for i in range(_active_popups.size() - 1, 0, -1):
		var active_popup := _active_popups[i]
		if active_popup == popup:
			break
		
		destroy_popup(active_popup)


# Popup management.

func _anchor_popup(popup: PopupControl) -> PopupAnchor:
	# Add a node to align the popup against.
	var anchor := PopupAnchor.new()
	add_child(anchor)
	
	# Anchor the popup to that node.
	popup.hide() # Avoid showing it until positioned.
	anchor.add_child(popup)
	_active_popups.push_back(popup)
	
	# Emit this after the node has been added to the tree, so theme is accessible.
	# Can be used to update the size of the popup.
	popup.about_to_popup.emit()
	
	return anchor


func create_positioned_popup(popup: PopupControl, position: Vector2, direction: Direction, blocking: bool) -> void:
	if has_popup(popup):
		printerr("PopupManager: Popup %s is already shown." % [ popup ])
		return
	if popup.get_parent():
		printerr("PopupManager: Popup %s must be unparented before it can be shown." % [ popup ])
		return
	
	var anchor := _anchor_popup(popup)
	anchor.update_absolute_position(position, popup.size, direction)
	popup.align_popup(direction)
	
	popup.click_handled.connect(_handle_popup_clicked.bind(popup))
	popup.show()
	
	if blocking:
		_blocking_popups.push_back(popup)
		_click_catcher.visible = true


func create_anchored_popup(popup: PopupControl, anchor_position: Vector2, direction: Direction, blocking: bool) -> void:
	if has_popup(popup):
		printerr("PopupManager: Popup %s is already shown." % [ popup ])
		return
	if popup.get_parent():
		printerr("PopupManager: Popup %s must be unparented before it can be shown." % [ popup ])
		return
	
	var anchor := _anchor_popup(popup)
	anchor.update_relative_position(anchor_position, popup.size, direction)
	popup.align_popup(direction)
	
	popup.click_handled.connect(_handle_popup_clicked.bind(popup))
	popup.show()
	
	if blocking:
		_blocking_popups.push_back(popup)
		_click_catcher.visible = true


func adjust_popup_position(popup: PopupControl, delta: Vector2) -> void:
	if not has_popup(popup):
		printerr("PopupManager: Popup %s is not shown." % [ popup ])
		return
	
	var anchor := popup.get_popup_anchor()
	var next_position := anchor.global_position + delta
	anchor.update_absolute_position(next_position, popup.size, popup._last_direction)


func transform_anchored_popup(popup: PopupControl, anchor_position: Vector2, popup_size: Vector2, direction: Direction, smooth: bool = false) -> void:
	if not has_popup(popup):
		printerr("PopupManager: Popup %s is not shown." % [ popup ])
		return
	
	var original_position := popup.global_position
	var original_size := popup.size
	
	popup.size = popup_size
	var anchor := popup.get_popup_anchor()
	anchor.update_relative_position(anchor_position, popup_size, direction)
	popup.align_popup(direction)
	
	if smooth:
		popup.animate_transform(original_position, original_size)


func has_popup(popup: PopupControl) -> bool:
	return _active_popups.has(popup)


func destroy_popup(popup: PopupControl) -> void:
	if not has_popup(popup):
		printerr("PopupManager: Popup %s is not shown." % [ popup ])
		return
	
	popup.click_handled.disconnect(_handle_popup_clicked)
	_active_popups.erase(popup)
	_blocking_popups.erase(popup)
	_click_catcher.visible = _blocking_popups.size() > 0
	
	popup.about_to_hide.emit()
	popup.hide()
	
	var anchor := popup.get_popup_anchor()
	anchor.remove_child(popup)
	anchor.get_parent().remove_child(anchor)
	anchor.queue_free()


# Public API.

static func show_popup(popup: PopupControl, position: Vector2, direction: Direction, blocking: bool = true) -> void:
	if not _instance:
		return
	
	_instance.create_positioned_popup(popup, position, direction, blocking)


static func show_popup_anchored(popup: PopupControl, anchor_position: Vector2, direction: Direction, blocking: bool = true) -> void:
	if not _instance:
		return
	
	_instance.create_anchored_popup(popup, anchor_position, direction, blocking)


static func move_popup(popup: PopupControl, delta: Vector2) -> void:
	if not _instance:
		return
	
	_instance.adjust_popup_position(popup, delta)


static func transform_popup_anchored(popup: PopupControl, anchor_position: Vector2, popup_size: Vector2, direction: Direction, smooth: bool = false) -> void:
	if not _instance:
		return
	
	_instance.transform_anchored_popup(popup, anchor_position, popup_size, direction, smooth)


static func hide_popup(popup: PopupControl) -> void:
	if not _instance:
		return
	
	_instance.destroy_popup(popup)


static func hide_all_blocking_popups() -> void:
	if not _instance:
		return
	
	for i in range(_instance._blocking_popups.size() - 1, -1, -1):
		var active_popup := _instance._blocking_popups[i]
		_instance.destroy_popup(active_popup)


static func is_popup_shown(popup: PopupControl) -> bool:
	if not _instance:
		return false
	
	return _instance.has_popup(popup)


static func get_click_catcher() -> Control:
	if not _instance:
		return null
	
	return _instance._click_catcher


class PopupControl extends Control:
	signal click_handled()
	signal about_to_popup()
	signal about_to_hide()
	
	const TRANSFORM_DURATION := 0.18
	
	var _last_direction: Direction = Direction.BOTTOM_RIGHT
	var _tween: Tween = null
	
	
	# Input events.
	
	func mark_click_handled() -> void:
		click_handled.emit()
	
	
	# Popup management.
	
	func is_popped() -> bool:
		if not is_node_ready() || not is_inside_tree():
			return false
		
		return PopupManager.is_popup_shown(self)
	
	
	func get_popup_anchor() -> PopupAnchor:
		var parent_node := get_parent()
		if parent_node && parent_node is PopupAnchor:
			return parent_node
		
		return null
	
	
	func align_popup(direction: Direction) -> void:
		_last_direction = direction
		
		match _last_direction:
			Direction.BOTTOM_RIGHT:
				set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_KEEP_SIZE)
				grow_horizontal = Control.GROW_DIRECTION_END
				grow_vertical = Control.GROW_DIRECTION_END
			Direction.BOTTOM_LEFT:
				set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_KEEP_SIZE)
				grow_horizontal = Control.GROW_DIRECTION_BEGIN
				grow_vertical = Control.GROW_DIRECTION_END
			Direction.TOP_RIGHT:
				set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_KEEP_SIZE)
				grow_horizontal = Control.GROW_DIRECTION_END
				grow_vertical = Control.GROW_DIRECTION_BEGIN
			Direction.TOP_LEFT:
				set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_KEEP_SIZE)
				grow_horizontal = Control.GROW_DIRECTION_BEGIN
				grow_vertical = Control.GROW_DIRECTION_BEGIN
			Direction.OMNI:
				set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
				grow_horizontal = Control.GROW_DIRECTION_BOTH
				grow_vertical = Control.GROW_DIRECTION_BOTH
	
	
	func animate_transform(original_position: Vector2, original_size: Vector2) -> void:
		# We immediately reset position and size to their old values. This all
		# happens in the same frame, so it should be seamless. New position and
		# size are our tweening targets.
		
		var target_position := global_position
		var target_size := size
		
		global_position = original_position
		size = original_size
		
		if _tween:
			_tween.kill()
		
		_tween = get_tree().create_tween().set_parallel()
		_tween.tween_property(self, "global_position", target_position, TRANSFORM_DURATION)
		_tween.tween_property(self, "size", target_size, TRANSFORM_DURATION)


class PopupAnchor extends Control:
	func _init() -> void:
		name = "PopupAnchor"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	
	func update_absolute_position(next_position: Vector2, popup_size: Vector2, direction: Direction) -> void:
		global_position = _fit_to_screen(next_position, popup_size, direction)
	
	
	func update_relative_position(next_position: Vector2, popup_size: Vector2, direction: Direction) -> void:
		# Reset values which may affect the position.
		global_position = Vector2.ZERO
		offset_left = 0
		offset_right = 0
		offset_top = 0
		offset_bottom = 0
		
		# Set relative position using anchoring.
		anchor_left = next_position.x
		anchor_right = next_position.x
		anchor_top = next_position.y
		anchor_bottom = next_position.y
		
		# Make sure that the actual position is valid.
		global_position = _fit_to_screen(global_position, popup_size, direction)
	
	
	func _fit_to_screen(next_position: Vector2, popup_size: Vector2, direction: Direction) -> Vector2:
		# Apply smart adjustments if the desired position + size would put the popup out of screen.
		# We trust the hardcoded direction, so the solution is to nudge it back in.
		var valid_position := next_position
		
		var effective_popup_rect := Rect2()
		effective_popup_rect.size.x = popup_size.x
		effective_popup_rect.size.y = popup_size.y
		
		match direction:
			Direction.BOTTOM_RIGHT:
				effective_popup_rect.position.x = next_position.x
				effective_popup_rect.position.y = next_position.y
			Direction.BOTTOM_LEFT:
				effective_popup_rect.position.x = next_position.x - popup_size.x
				effective_popup_rect.position.y = next_position.y
			Direction.TOP_RIGHT:
				effective_popup_rect.position.x = next_position.x
				effective_popup_rect.position.y = next_position.y - popup_size.y
			Direction.TOP_LEFT:
				effective_popup_rect.position.x = next_position.x - popup_size.x
				effective_popup_rect.position.y = next_position.y - popup_size.y
			Direction.OMNI:
				effective_popup_rect.position.x = next_position.x - popup_size.x / 2.0
				effective_popup_rect.position.y = next_position.y - popup_size.y / 2.0
		
		var click_catcher := PopupManager.get_click_catcher()
		
		if effective_popup_rect.position.x < 0:
			valid_position.x -= effective_popup_rect.position.x
		elif click_catcher && effective_popup_rect.end.x > click_catcher.size.x:
			valid_position.x -= effective_popup_rect.end.x - click_catcher.size.x
		
		if effective_popup_rect.position.y < 0:
			valid_position.y -= effective_popup_rect.position.y
		elif click_catcher && effective_popup_rect.end.y > click_catcher.size.y:
			valid_position.y -= effective_popup_rect.end.y - click_catcher.size.y
		
		return valid_position
