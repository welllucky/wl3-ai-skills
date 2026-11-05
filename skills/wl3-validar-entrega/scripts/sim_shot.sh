#!/bin/bash
# uso: sim_shot.sh <udid> <arquivo.png>  (screenshot do simulador no momento do passo)
xcrun simctl io "$1" screenshot --type=png "$2" >/dev/null 2>&1 && echo "$2"
