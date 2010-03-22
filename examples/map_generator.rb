#!/usr/bin/env ruby

require 'rubygems'
require 'grope'

env = Grope::Env.new
env.load('http://www.horaguchi.net/map_generator/map_generator.html')

while true
  puts "\e[2J\e[0;0f"
  env.window.generate
  puts env.document.generator.text_map.value
  sleep 0.5
end
