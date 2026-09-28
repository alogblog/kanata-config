#!/bin/bash
#sleep 0.02   # 20ms, 체감 불가능한 수준이지만 확실한 안전마진
xset q | grep -q "Caps Lock:  *on" && polybar-msg hook capslock 2 || polybar-msg hook capslock 1
