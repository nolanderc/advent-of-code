#!/usr/bin/bash

if [[ "$#" -ne "2" ]]; then
    echo "$0 <year> <day>"
    exit 1
fi

year="$1"
day="$2"
tmp_path="/tmp/aoc_$1_day_$2.input"

if [[ ! -f "$tmp_path" ]]; then
    curl --cookie "session=$AOC_SESSION" "https://adventofcode.com/$year/day/$day/input" > "$tmp_path" || exit 1
fi

cat "$tmp_path"

