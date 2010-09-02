#!/bin/sh

PREFIX=`cd \`dirname $0\`; pwd`

export GEM_PATH=$PREFIX/vendor
export PATH=$PREFIX/bin:$PREFIX/vendor/bin:$PATH
export SPITBALL_CACHE=$PREFIX/cache

if [ "$SPITBALL_PIDFILE" = "" ]; then
    SPITBALL_PIDFILE=$PREFIX/server.pid
fi

nice -n10 sh -c 'echo $$ > '$SPITBALL_PIDFILE'; exec ruby -rubygems -Ilib bin/spitball-server -p 1134'
