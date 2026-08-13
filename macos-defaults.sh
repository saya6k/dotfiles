#!/usr/bin/env bash

# macOS System Preferences
# Run by hand (not from install.sh) — this changes system state and needs sudo.
#
# Skeleton only: add `defaults write ...` lines under the sections below as you
# decide what you want. Good sources for candidates:
#   https://macos-defaults.com
#   https://github.com/balloob/dotfiles/blob/main/macos-defaults.sh

set -e

# Close System Settings so it can't overwrite what this script writes.
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

echo "Setting macOS defaults..."

###############################################################################
# General UI/UX                                                               #
###############################################################################

###############################################################################
# Keyboard & Input                                                            #
###############################################################################

###############################################################################
# Trackpad & Mouse                                                            #
###############################################################################

###############################################################################
# Finder                                                                      #
###############################################################################

###############################################################################
# Dock                                                                        #
###############################################################################

###############################################################################
# Screenshots                                                                 #
###############################################################################

###############################################################################
# Developer tools (Terminal, Xcode, ...)                                      #
###############################################################################

echo "Done. Some settings need a logout or restart to take effect."

# Uncomment once this script actually writes settings:
# killall Finder Dock SystemUIServer 2>/dev/null || true
