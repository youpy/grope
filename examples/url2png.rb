#!/usr/bin/env ruby

require 'rubygems'
require 'grope'

url, filename, xpath = ARGV

env = Grope::Env.new
puts "Fetching %s ..." % url
env.load(url)
env.wait
env.capture(xpath ? env.find(xpath) : nil, filename)
puts " ... done"
