require 's3_index'

# Load tasks from ActiveRecord
spec = Gem::Specification.find_by_name 'activerecord'
load "#{spec.gem_dir}/lib/active_record/railties/databases.rake"

class SeedLoader
  def load_seed
    load 'db/seeds.rb'
  end
end

# @see //gems/activerecord-4.2.5/lib/active_record/tasks/database_tasks.rb
include ActiveRecord::Tasks
db_config = YAML.load(ERB.new(File.read('config/database.yml')).result)

DatabaseTasks.database_configuration = db_config
DatabaseTasks.env = S3Index.env
DatabaseTasks.db_dir = 'db'
DatabaseTasks.migrations_paths = ['db/migrate']
DatabaseTasks.root = Dir.pwd
DatabaseTasks.seed_loader = SeedLoader.new

task :environment do
  ActiveRecord::Base.establish_connection(db_config[S3Index.env])
  ActiveRecord::Base.logger = Logger.new(S3Index.root.join('log', "#{S3Index.env}.log"))
end
