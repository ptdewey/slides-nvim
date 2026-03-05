#!/usr/bin/env bash

set -euo pipefail

mkdir -p lua/slides
for f in fnl/slides/*.fnl; do
    fennel --compile "$f" > "lua/slides/$(basename "${f%.fnl}").lua"
done
