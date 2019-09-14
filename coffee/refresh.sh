#!/bin/bash
for SRC in *.coffee; do ../node_modules/coffee-script/bin/coffee -c $SRC; done
