###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name ContributorLine extends HBoxContainer

const CONTRIBUTIONS_LINK := "https://github.com/YuriSizov/boscaceoil-blue/commits?author="

@export var username: String = "":
	set = set_username
@export var contributions: int = 0:
	set = set_contributions

@onready var _username_label: Label = $UsernameLabel
@onready var _link_label: LinkLabel = $LinkLabel


func _ready() -> void:
	_update_labels()


func set_username(value: String) -> void:
	if username == value:
		return
	
	username = value
	_update_labels()


func set_contributions(value: int) -> void:
	if contributions == value:
		return
	
	contributions = value
	_update_labels()


func _update_labels() -> void:
	if not is_node_ready():
		return
	
	_username_label.text = username
	_link_label.url = CONTRIBUTIONS_LINK + username
	_link_label.text = "1 contribution" if contributions == 1 else ("%s contributions" % contributions)
