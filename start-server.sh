#!/bin/sh

PREFIX=`cd \`dirname $0\`; pwd`
PIDFILE=$PREFIX/server.pid

export GEM_PATH=$PREFIX/vendor
export PATH=$PREFIX/bin:$PREFIX/vendor/bin:$PATH

export SPITBALL_CACHE=$PREFIX/cache


nice -n10 sh -c 'echo $$ > '$PIDFILE'; exec ruby -rubygems -Ilib bin/spitball-server -p 8080'
