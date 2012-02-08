#!/bin/bash

cd "$(dirname "$0")"
export JRUBY_OPTS=--1.8

rdoc \
  --main epic.rb \
  --charset=UTF-8 \
  --encoding=UTF-8 \
  --title=EPIC \
  --tab-width=2 \
  --format=darkfish \
  --all \
  --exclude=public/docs/epic \
  --exclude=some_gems \
  --exclude=attic \
  --output=public/docs/epic \
  --force-output \
  epic*.rb djinn*.rb $GEM_HOME/gems/rack*/lib/

exit
rdoc \
  --main dav.rb \
  --encoding=UTF-8 \
  --title=EPIC \
  --format=darkfish \
  --output=rdoc \
  --exclude=rdoc \
  --all \
  --line-numbers \
  --exclude='some_gems' \
  . $GEM_HOME/gems/*/lib
