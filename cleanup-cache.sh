#!/bin/sh

PREFIX=`cd \`dirname $0\`; pwd`

export GEM_PATH=$PREFIX/vendor
export PATH=$PREFIX/bin:$PREFIX/vendor/bin:$PATH
export SPITBALL_CACHE=$PREFIX/cache

ruby -rubygems -Ilib bin/spitball-cleanup-cache
