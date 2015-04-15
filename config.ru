require 'rubygems'
require 'bundler'

Bundler.require

require './chronos_app'
run Sinatra::Application
