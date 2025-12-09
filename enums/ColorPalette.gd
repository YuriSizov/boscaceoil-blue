###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name BoscaColorPalette extends Object

const PALETTE_BLUE   := 0
const PALETTE_PURPLE := 1
const PALETTE_RED    := 2
const PALETTE_ORANGE := 3
const PALETTE_GREEN  := 4
const PALETTE_CYAN   := 5
const MAX            := 6

## Fallback value, but can also be set directly.
const PALETTE_GRAY   := 20


static func validate(value: int) -> int:
	if value == PALETTE_GRAY:
		return value

	return ValueValidator.index(value, BoscaColorPalette.MAX, "Invalid value: Expected an index value between 0 and %d, or %d, got %d instead." % [ BoscaColorPalette.MAX - 1, BoscaColorPalette.PALETTE_GRAY, value ])
