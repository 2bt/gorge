#!/bin/sh

mkdir lovegame
cp -r *.lua media/ lovegame/
adb push lovegame/ /sdcard/lovegame
exit


zip -9 -q -r gorge.love *.lua media/
adb push gorge.love /sdcard/Download/gorge.love
adb shell am start -S -n "org.love2d.android/.GameActivity" -d "file:///sdcard/Download/gorge.love"