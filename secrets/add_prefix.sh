#!/bin/bash

# TODO: test for CLI params.
# Usage: $0 <prefix> (just the number!)

PASSWORD=$(pwgen -s 10 1)
DIGEST=$( echo -n "$1:EPIC:$PASSWORD" | md5sum )
DIGEST=${DIGEST:0:32}

cat <<EOT
Please add the following to users.rb:

    '$1' => {
      :digest       => '$DIGEST', # $PASSWORD
      :handle       => '0.NA/$1',
      :index        => 300,
      :index_create => 200,
    },

EOT
