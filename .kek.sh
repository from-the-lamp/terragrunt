#!/usr/bin/env bash

awk -F= -v section="[$3]" -v key="$1" '
  $1 == section { in_section = 1; next }
  $1 == "[" section "]" { in_section = 0 }
  in_section && $1 == key { print $2; exit }' $2
