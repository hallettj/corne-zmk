#!/usr/bin/env bash
#
# This script runs in a zmk-build-arm docker container. See Dockerfile and
# Makefile in this repo.

set -euo pipefail

PWD=$(pwd)
TIMESTAMP="${TIMESTAMP:-$(date -u +"%Y-%m-%d_%H%M%S")}"

function compile() {
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

# Files produced in the docker container are owned by root. If `OWNER_ID` and
# `GROUP_ID` environment variables are given then reassign ownership to those
# values instead.
function fix_owner() {
  local path="$1"
  if [[ -n "$OWNER_ID" && -n "$GROUP_ID" ]]; then
    chown "${OWNER_ID}:${GROUP_ID}" "$path"
  fi
}

# Copy build outputs to firmware/ on the host filesystem
function copy() {
  local shield="$1"
  local output="./firmware/${TIMESTAMP}-${shield}.uf2"
  cp "build/${shield}/zephyr/zmk.uf2" "$output"
  fix_owner "$output"
}

# usage: build <board> <shield>
function build() {
  local board="$1"
  local shield="$2"
  compile "$board" "$shield"
  copy "$shield"
}

build nice_nano_v2 corne_left
build nice_nano_v2 corne_right

# Uncomment to build reset firmware in case of trouble pairing left and right
# halves:
# build nice_nano_v2 settings_reset
