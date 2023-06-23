#!/usr/bin/env bash

awk -F= -v section="[$2]" -v key='compartment_ocid' '
  $1 == section { in_section = 1 }
  in_section && $1 == key { print $2; exit }' $1
