#!/bin/sh

PREFIX=`cd \`dirname $0\`; pwd`
SHARED_PREFIX=/usr/local/spitball/shared

export GEM_PATH=$PREFIX/vendor
export PATH=$PREFIX/bin:$PREFIX/vendor/bin:$PREFIX/../shared/ruby/bin:$PATH
export SPITBALL_LOG_FILE=$PREFIX/../../shared/spitball.log
export SPITBALL_CACHE=$SHARED_PREFIX/cache

if [ "$SPITBALL_PIDFILE" = "" ]; then
    SPITBALL_PIDFILE=$SHARED_PREFIX/server.pid
fi

nice -n10 sh -c 'echo $$ > '$SPITBALL_PIDFILE'; exec ruby -rubygems -Ilib bin/spitball-server -p 1134 >> '$SPITBALL_LOG_FILE' 2>&1' &
disown -h
