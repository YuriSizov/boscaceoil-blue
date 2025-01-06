###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name AccentedContentEffect extends RichTextEffect

var bbcode: String = "accent"


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	char_fx.color = ThemeDB.get_project_theme().get_color("accent_color", "InfoPopup")
	return true
