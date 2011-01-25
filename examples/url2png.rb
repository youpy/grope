#!/usr/bin/env ruby

require 'rubygems'
require 'grope'

url, filename = ARGV

env = Grope::Env.new
puts "Fetching %s ..." % url
env.load(url)
env.wait
env.capture(nil, filename)
puts " ... done"
