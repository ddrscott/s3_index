require 's3_index/version'

require_relative '../lib/environment'

# Namespaces
module S3Index
  extend ActiveSupport::Autoload

  def self.env
    @env ||= ActiveSupport::StringInquirer.new(ENV['S3_INDEX_ENV'])
  end

  # Use like `Rails.root`
  # @return [Pathname]
  def self.root
    @root ||= Pathname(File.expand_path('../..', __FILE__))
  end

  def self.logger
    ActiveRecord::Base.logger
  end
end

S3Index.eager_load!
