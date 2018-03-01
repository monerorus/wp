#!/usr/bin/env puma
threads 2, 4
workers 2
preload_app!
bind 'unix:///tmp/puma.sock'
pidfile '/tmp/puma.pid'
#environment $RACK_ENV