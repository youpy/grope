#!/usr/bin/ruby

require 'rubygems'
require 'grope'

env = Grope::Env.new
env.load('http://www.onicos.com/staff/iz/amuse/javascript/expert/md5.html')
window = env.window
puts window.MD5_hexhash(window.utf16to8(STDIN.read))
