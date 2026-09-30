#!/bin/bash

grep -A4  'wc --bytes' logs/update-cyclemaps.log |egrep -v '^([-+]|[0-9.]*G )'

