#!/usr/bin/enb ruby

require 'rubygems'
require 'grope'

if ARGV.size != 1
  warn "usage: #{$0} /path/to/js/to/minify.js"
  exit 1
end

js_filename = ARGV.shift

env = Grope::Env.open('http://fmarcia.info/jsmin/test.html')
env.xpath('//textarea')[1].value = open(js_filename).read
env.document.getElementById('go').click
puts env.xpath('//textarea')[2].value
