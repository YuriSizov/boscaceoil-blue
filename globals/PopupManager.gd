###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
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
}

static var _instance: PopupManager = null

var _active_popups: Array[PopupControl] = []
@onready var _click_catcher: Control = $ClickCatcher


func _init() -> void:
	if _instance:
		printerr("PopupManager: Only one instance of PopupManager is allowed.")
	
	_instance = self


func _ready() -> void:
	_click_catcher.visible = _active_popups.size() > 0
	_click_catcher.gui_input.connect(_handle_catcher_clicked)


# Popup management.

func _handle_catcher_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton && not event.is_pressed(): # Activate on mouse release.
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			PopupManager.hide_all_popups()
			_click_catcher.hide()
			return


func _handle_popup_clicked(popup: PopupControl) -> void:
	# Close all popups on top of the clicked one.
	for i in range(_active_popups.size() - 1, 0, -1):
		var active_popup := _active_popups[i]
		if active_popup == popup:
			break
		
		destroy_popup(active_popup)


func has_popup(popup: PopupControl) -> bool:
	return _active_popups.has(popup)


func create_blocking_popup(popup: PopupControl, position: Vector2, direction: Direction) -> void:
	if has_popup(popup):
		printerr("PopupManager: Popup %s is already shown." % [ popup ])
		return
	
	if popup.get_parent():
		printerr("PopupManager: Popup %s must be unparented before it can be shown." % [ popup ])
		return
	
	# Add a node to align the popup against and the popup itself.
	var anchor := Control.new()
	anchor.name = "PopupAnchor"
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(anchor)
	
	popup.hide() # Avoid showing it until positioned.
	popup.click_handled.connect(_handle_popup_clicked.bind(popup))
	anchor.add_child(popup)
	_active_popups.push_back(popup)
	
	# Emit this after the node has been added to the tree, so theme is accessible.
	popup.about_to_popup.emit()
	
	# Apply smart adjustments if the desired position + size would put the popup out of screen.
	# We trust the hardcoded direction, so the solution is be to nudge it back in.
	var valid_position := position
	
	var effective_popup_rect := Rect2()
	match direction:
		Direction.BOTTOM_RIGHT:
			effective_popup_rect.position.x = position.x
			effective_popup_rect.position.y = position.y
			effective_popup_rect.size.x = popup.size.x
			effective_popup_rect.size.y = popup.size.y
		Direction.BOTTOM_LEFT:
			effective_popup_rect.position.x = position.x - popup.size.x
			effective_popup_rect.position.y = position.y
			effective_popup_rect.size.x = popup.size.x
			effective_popup_rect.size.y = popup.size.y
		Direction.TOP_RIGHT:
			effective_popup_rect.position.x = position.x
			effective_popup_rect.position.y = position.y - popup.size.y
			effective_popup_rect.size.x = popup.size.x
			effective_popup_rect.size.y = popup.size.y
		Direction.TOP_LEFT:
			effective_popup_rect.position.x = position.x - popup.size.x
			effective_popup_rect.position.y = position.y
			effective_popup_rect.size.x = popup.size.x
			effective_popup_rect.size.y = popup.size.y - popup.size.y
	
	if effective_popup_rect.position.x < 0:
		valid_position.x -= effective_popup_rect.position.x
	elif effective_popup_rect.end.x > _click_catcher.size.x:
		valid_position.x -= effective_popup_rect.end.x - _click_catcher.size.x
	
	if effective_popup_rect.position.y < 0:
		valid_position.y -= effective_popup_rect.position.y
	elif effective_popup_rect.end.y > _click_catcher.size.y:
		valid_position.y -= effective_popup_rect.end.y - _click_catcher.size.y
	
	# Set the popup to an acceptable position.
	anchor.global_position = valid_position
	
	# Align the popup to the anchor point.
	match direction:
		Direction.BOTTOM_RIGHT:
			popup.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_KEEP_SIZE)
			popup.grow_horizontal = Control.GROW_DIRECTION_END
			popup.grow_vertical = Control.GROW_DIRECTION_END
		Direction.BOTTOM_LEFT:
			popup.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_KEEP_SIZE)
			popup.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			popup.grow_vertical = Control.GROW_DIRECTION_END
		Direction.TOP_RIGHT:
			popup.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_KEEP_SIZE)
			popup.grow_horizontal = Control.GROW_DIRECTION_END
			popup.grow_vertical = Control.GROW_DIRECTION_BEGIN
		Direction.TOP_LEFT:
			popup.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_KEEP_SIZE)
			popup.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			popup.grow_vertical = Control.GROW_DIRECTION_BEGIN
	
	# Finally, show everything.
	popup.show()
	_click_catcher.visible = true


func destroy_popup(popup: PopupControl) -> void:
	if not has_popup(popup):
		printerr("PopupManager: Popup %s is not shown." % [ popup ])
		return
	
	popup.click_handled.disconnect(_handle_popup_clicked)
	_active_popups.erase(popup)
	_click_catcher.visible = _active_popups.size() > 0
	
	popup.about_to_hide.emit()
	popup.hide()
	
	var anchor := popup.get_parent()
	anchor.remove_child(popup)
	anchor.get_parent().remove_child(anchor)


# Public API.

static func show_popup(popup: PopupControl, position: Vector2, direction: Direction) -> void:
	if not _instance:
		return
	
	_instance.create_blocking_popup(popup, position, direction)


static func hide_popup(popup: PopupControl) -> void:
	if not _instance:
		return
	
	_instance.destroy_popup(popup)


static func hide_all_popups() -> void:
	if not _instance:
		return
	
	for i in range(_instance._active_popups.size() - 1, -1, -1):
		var active_popup := _instance._active_popups[i]
		_instance.destroy_popup(active_popup)


class PopupControl extends Control:
	signal click_handled()
	signal about_to_popup()
	signal about_to_hide()
	
	
	func mark_click_handled() -> void:
		click_handled.emit()
