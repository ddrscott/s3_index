require 'logger'
require 'pry'

db_config = YAML.load(File.open(S3Index.root.join('config', 'database.yml')))
ActiveRecord::Base.establish_connection(db_config[S3Index.env])
ActiveRecord::Base.logger = Logger.new(S3Index.root.join('log', "#{S3Index.env}.log"))
