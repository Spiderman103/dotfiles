# Auto-start Sway on login to tty1
if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
  command -v mango &>/dev/null && exec mango
fi
