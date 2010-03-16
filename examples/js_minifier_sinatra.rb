#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'grope'
require 'json'

$grope = Grope::Env.new
$grope.load('http://fmarcia.info/jsmin/test.html')

get '/' do
  '<html><body><form action="/minify"><textarea name="js"></textarea><br><input type="submit"></form></body></html>'
end

get '/minify' do
  content_type 'application/json'
  
  $grope.all('//textarea')[1].value = params[:js]
  $grope.find('id("go")').click

  JSON.generate :result => $grope.all('//textarea')[2].value
end

