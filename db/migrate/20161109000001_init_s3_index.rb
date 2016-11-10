# Create index table
class InitS3Index < ActiveRecord::Migration
  def change
    create_table :s3_index, force: true do |t|
      t.string :origin_url,   index: true
      t.string :file_name,    index: true
      t.string :content_type, index: true
      t.string :md5,          index: true
      t.integer :size
      t.string :s3_url, index: true, unique: true
      t.string :s3_bucket
      t.timestamps null: false
    end
  end
end
