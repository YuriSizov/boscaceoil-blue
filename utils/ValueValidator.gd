###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name ValueValidator extends Object

static func positive(value: int, message: String = "") -> int:
	var clean := maxi(value, 1)
	if clean != value:
		if message.is_empty():
			printerr("Invalid value: Expected a positive value, got %d instead." % [ value ])
		else:
			printerr(message)

	return clean

static func posizero(value: int, message: String = "") -> int:
	var clean := maxi(value, 0)
	if clean != value:
		if message.is_empty():
			printerr("Invalid value: Expected a positive value or zero, got %d instead." % [ value ])
		else:
			printerr(message)

	return clean

static func range(value: int, min_value: int, max_value: int, message: String = "") -> int:
	var clean := clampi(value, min_value, max_value)
	if clean != value:
		if message.is_empty():
			printerr("Invalid value: Expected value in range from %d to %d, got %d instead." % [ min_value, max_value, value ])
		else:
			printerr(message)

	return clean

static func index(value: int, size: int, message: String = "") -> int:
	var clean := clampi(value, 0, size - 1)
	if clean != value:
		if message.is_empty():
			printerr("Invalid value: Expected an index value between 0 and %d, got %d instead." % [ size - 1, value ])
		else:
			printerr(message)

	return clean
