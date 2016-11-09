# Set up default ENV values
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
ENV['S3_INDEX_ENV'] ||= ENV['RAILS_ENV'] || 'development'

# Bundler stuff
require 'rubygems'
require 'bundler'
Bundler.setup(:default, ENV['S3_INDEX_ENV'])

require 'active_record'
require 'active_support/all'

ActiveRecord::Base.raise_in_transactional_callbacks = true
