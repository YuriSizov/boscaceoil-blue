###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

# Helper script to abstract colorizing console output in builder.

# ANSI escape codes.

RESET     = '\033[0m'
BOLD      = '\033[1m'
FAINT     = '\033[2m'
ITALIC    = '\033[3m'
UNDERLINE = '\033[4m'

BLACK   = '\033[30m'
RED     = '\033[31m'
GREEN   = '\033[32m'
YELLOW  = '\033[33m'
BLUE    = '\033[34m'
MAGENTA = '\033[35m'
CYAN    = '\033[36m'
WHITE   = '\033[37m'

BLACK_BG   = '\033[40m'
RED_BG     = '\033[41m'
GREEN_BG   = '\033[42m'
YELLOW_BG  = '\033[43m'
BLUE_BG    = '\033[44m'
MAGENTA_BG = '\033[45m'
CYAN_BG    = '\033[46m'
WHITE_BG   = '\033[47m'

BRIGHT_BLACK   = '\033[90m'
BRIGHT_RED     = '\033[91m'
BRIGHT_GREEN   = '\033[92m'
BRIGHT_YELLOW  = '\033[93m'
BRIGHT_BLUE    = '\033[94m'
BRIGHT_MAGENTA = '\033[95m'
BRIGHT_CYAN    = '\033[96m'
BRIGHT_WHITE   = '\033[97m'

BRIGHT_BLACK_BG   = '\033[100m'
BRIGHT_RED_BG     = '\033[101m'
BRIGHT_GREEN_BG   = '\033[102m'
BRIGHT_YELLOW_BG  = '\033[103m'
BRIGHT_BLUE_BG    = '\033[104m'
BRIGHT_MAGENTA_BG = '\033[105m'
BRIGHT_CYAN_BG    = '\033[106m'
BRIGHT_WHITE_BG   = '\033[107m'


# Helper methods.

def bold(text):
    return f"{BOLD}{text}{RESET}"
def faint(text):
    return f"{FAINT}{text}{RESET}"
def italic(text):
    return f"{ITALIC}{text}{RESET}"
def underline(text):
    return f"{UNDERLINE}{text}{RESET}"

def gray(text):
    return f"{BRIGHT_BLACK}{text}{RESET}"
def red(text):
    return f"{BRIGHT_RED}{text}{RESET}"
def green(text):
    return f"{BRIGHT_GREEN}{text}{RESET}"
def yellow(text):
    return f"{BRIGHT_YELLOW}{text}{RESET}"
def blue(text):
    return f"{BRIGHT_BLUE}{text}{RESET}"
def magenta(text):
    return f"{BRIGHT_MAGENTA}{text}{RESET}"
def cyan(text):
    return f"{BRIGHT_CYAN}{text}{RESET}"
def white(text):
    return f"{BRIGHT_WHITE}{text}{RESET}"
