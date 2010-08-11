#!/bin/bash
RUBIES=$(echo `rvm list strings` | tr " " "\n")
GEMSET=`grep -m 1 -o -e "\@[^ ]*" .rvmrc`
for RUBY in $RUBIES; do
  if [ $RUBY != "default" ]; then
    rvm "$RUBY$GEMSET" ruby -S "bundle install"
    rvm "$RUBY$GEMSET" rake spec
  fi
done
