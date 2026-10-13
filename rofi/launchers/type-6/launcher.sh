#!/usr/bin/env bash
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export XCOMPOSELOCALE="en_US.UTF-8"

## Author : Aditya Shakya (adi1090x)
## Github : @adi1090x
#
## Rofi   : Launcher (Modi Drun, Run, File Browser, Window)
#
## Available Styles
#
## style-1     style-2     style-3     style-4     style-5
## style-6     style-7     style-8     style-9     style-10

dir="$HOME/.config/rofi/launchers/type-6"
theme='style-1'

## Run
rofi \
    -show combi \
    -combi-modi "window,drun,run,files:~/.config/rofi/scripts/rofi-files.sh" \
    -modi "combi,window,drun,run,files:~/.config/rofi/scripts/rofi-files.sh" \
    -no-lazy-grab \
    -theme ${dir}/${theme}.rasi
