#!/bin/sh
# /proc/bus/input/devices에 kanata1이 만든 kanata가 없거나, 심링크가 깨졌으면 재시작
if! grep -q '"kanata"' /proc/bus/input/devices; then
  systemctl --user restart kanata1.service
  exit 0
fi
[ -L /run/user/1000/kanata1 ] && [ -e /run/user/1000/kanata1 ] || systemctl --user restart kanata1.service
[ -L /run/user/1000/kanata2 ] && [ -e /run/user/1000/kanata2 ] || systemctl --user restart kanata2.service
