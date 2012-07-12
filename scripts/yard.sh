#!/bin/bash -l

cd "`dirname "$0"`"/../

# Yard doesn't seem to work nicely with my current version of JRuby, so I need
# to load the "normal" Ruby interpreter:

rvm use ruby-1.9.2@epic

rm -rf .yardoc/
if [ "yard" = "`basename "$0" ".sh"`" ]; then
  rm -rf public/docs/yard/*
  exec yard "$@"
else
  exec yard server --reload "$@"
fi
