#!/bin/bash

pkill -f qs
while pgrep -f qs >/dev/null; do
    sleep 0.1
done

qs &
