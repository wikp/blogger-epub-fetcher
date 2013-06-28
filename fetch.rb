#!/usr/bin/env ruby

require 'google/api_client'
require 'faraday'
require 'epubbery'
require 'rubygems'

require './lib/blogger-fetcher'
require './lib/blogger-post'
require './lib/string-ext'

CONFIG_FILE = './config.yml'

if File.exists? CONFIG_FILE
  fetcher = BloggerFetcher.new(YAML::load(File.read(CONFIG_FILE)), ARGV[0])
  fetcher.write_epub
else
  raise RuntimeError, 'Copy config.yml.dist file to config.yml and edit it'
end



