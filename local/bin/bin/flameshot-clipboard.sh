#!/bin/bash
flameshot gui --raw | xclip -selection clipboard -t image/png -i
