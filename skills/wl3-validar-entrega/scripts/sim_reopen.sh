#!/bin/bash
# uso: sim_reopen.sh <udid> <bundle_id> <deep_link> [espera_s]
# encerra o app, abre de novo e navega pelo deep link (força nova consulta, sem cache do SWR)
xcrun simctl terminate "$1" "$2" >/dev/null 2>&1
xcrun simctl launch "$1" "$2" >/dev/null
sleep 6
xcrun simctl openurl "$1" "$3"
sleep "${4:-12}"
