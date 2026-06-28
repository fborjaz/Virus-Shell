#!/bin/bash
pamixer --default-source -t
sleep 0.1
vol=$(pamixer --default-source --get-volume)
mute=$(pamixer --default-source --get-mute)
if [ "$mute" = "true" ]; then
    /usr/bin/eww update micico="󰍭" micmute="true" get_mic_vol="0"
else
    /usr/bin/eww update micico="󰍬" micmute="false" get_mic_vol="$vol"
fi
