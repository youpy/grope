require 'osx/cocoa'
OSX.require_framework 'Webkit'
include OSX

module Grope
end

require 'grope/dom_ext'
require 'grope/wso_wrapper'
require 'grope/cookie_storage'
require 'grope/frame_load_delegate'
require 'grope/web_resource_load_delegate'
require 'grope/env'
