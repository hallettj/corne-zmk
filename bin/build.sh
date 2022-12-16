#!/usr/bin/env bash

set -euo pipefail

PWD=$(pwd)
TIMESTAMP="${TIMESTAMP:-$(date -u +"%Y%m%d%H%M%S")}"

function build() {
  local side="$1"
  west build \
    -s zmk/app \
    -d build/"${side}" \
    -b nice_nano_v2 \
    -- \
    -DZMK_CONFIG="${PWD}/config" \
    -DSHIELD="corne_${side}"
  grep -v -e "^#" -e "^$" "build/${side}/zephyr/.config" | sort
}

function copy() {
  local side="$1"
  cp "build/${side}/zephyr/zmk.uf2" "./firmware/${TIMESTAMP}-${side}.uf2"
}

build left
build right
copy left
copy right
