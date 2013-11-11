## spitball [![Build Status](https://secure.travis-ci.org/twitter/spitball.png?branch=master)](http://travis-ci.org/twitter/spitball) [![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/twitter/spitball)

A very simple gem package generation tool built on `bundler`. Pass it a
gem file, it spits out a tarball of the generated gem
environment. Perfect for "bundle once, upload everywhere"-style
deployment.

Also comes with `spitball-server`, a small sinatra app that you can run
on a dedicated build server. The `spitball` command line client can then
pull packages down from said server.

### Usage

    Usage: spitball [options] GEMFILE ARCHIVE

    options:
        -h, --host HOST                  Get the tarball from a remote spitball server
        -p, --port PORT                  Specify the remote server port. Default 8080
            --without a,b,c              Excluded groups in the tarball. Does not apply to remote spitballs
            --version

    environment variables:
            SPITBALL_CACHE		           Specifies the cache dir. Defaults to /tmp/spitball-username

### TODO

Lots of things are changing in bundler 1.0. We're stuck on 0.9.5 for
now, but once we get to 1.0, this tool will probably work with lock
files instead of gem files, for more predictable builds.
