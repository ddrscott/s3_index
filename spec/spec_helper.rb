$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

ENV['S3_INDEX_ENV'] ||= 'test'
ENV['RAILS_ENV'] ||= 'test'

require 's3_index'
require_relative './config'
require 'rails'
require 'active_record/railtie'
require 'rspec/rails'

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.use_transactional_fixtures = true
end
