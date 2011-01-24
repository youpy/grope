#!/usr/bin/env ruby

require 'rubygems'
require 'grope'

js_filename = ARGV.shift
js = (js_filename ? open(js_filename) : STDIN).read

env = Grope::Env.new
env.load('http://fmarcia.info/jsmin/test.html')
env.all('//textarea')[1].value = js
env.document.getElementById('go').click
puts env.all('//textarea')[2].value
