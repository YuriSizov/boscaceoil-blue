###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name CreditsPopup extends WindowPopup

# TODO: Perhaps use an external text file for this.
# Use the case-independent alphabetical order!
const CONTRIBUTORS := [
	# username, contributions
	[ "genderfreak", 1, ],
	[ "SirLich", 1, ],
]

const CONTRIBUTOR_LINE_SCENE := preload("res://gui/views/help_view/ContributorLine.tscn")

@onready var _contributors_list: VBoxContainer = %ContributorsList


func _ready() -> void:
	super()
	
	_update_contributors_list()


func _notification(what: int) -> void:
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		# Since this is a part of an instantiated scene, these nodes are immediately available.
		# This allows us to use them safely before ready.
		_contributors_list = %ContributorsList


func _update_contributors_list() -> void:
	while _contributors_list.get_child_count() > 0:
		var child_node := _contributors_list.get_child(0)
		_contributors_list.remove_child(child_node)
	
	for contributor: Array in CONTRIBUTORS:
		var line := CONTRIBUTOR_LINE_SCENE.instantiate()
		line.username = contributor[0]
		line.contributions = contributor[1]
		
		_contributors_list.add_child(line)
