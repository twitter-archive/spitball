#!/bin/sh

PREFIX=`readlink -f $0/..`

export GEM_PATH=$PREFIX/vendor
export PATH=$PREFIX/bin:$PREFIX/vendor/bin:$PATH

export SPITBALL_CACHE=$PREFIX/cache


nice -n10 spitball-server -p 8080
