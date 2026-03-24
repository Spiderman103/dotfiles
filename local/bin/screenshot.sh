#!/bin/bash
grim -g "$(slurp)" - | wl-copy && wl-paste > ~/Pictures/Screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png
