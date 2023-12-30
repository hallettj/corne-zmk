#!/usr/bin/env bash

set -euo pipefail

PWD=$(pwd)
TIMESTAMP="${TIMESTAMP:-$(date -u +"%Y-%m-%d_%H%M%S")}"

function build() {
  local board="$1"
  local shield="$2"
  west build \
    -s zmk/app \
    -d build/"$shield" \
    -b "$board" \
    -- \
    -DZMK_CONFIG="${PWD}/config" \
    -DSHIELD="$shield"
  grep -v -e "^#" -e "^$" "build/${shield}/zephyr/.config" | sort
}

function copy() {
  local shield="$1"
  local output="./firmware/${TIMESTAMP}-${shield}.uf2"
  cp "build/${shield}/zephyr/zmk.uf2" "$output"
  chown 1000:100 "$output"
}

build nice_nano_v2 corne_left
build nice_nano_v2 corne_right
build nice_nano_v2 settings_reset
copy corne_left
copy corne_right
copy settings_reset
