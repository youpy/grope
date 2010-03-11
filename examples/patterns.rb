#!/usr/bin/env ruby

env = Grope::Env.new
env.load('http://www.dinkypage.com/55654')

while true
  puts env.document.body.innerText
  sleep 1
end
