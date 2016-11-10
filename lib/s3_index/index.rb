module S3Index
  # Model containing S3 file metadata.
  # All files uploaded by `S3Index.upload!` will be registered
  # here for easy querying.
  class Index < ActiveRecord::Base
    self.table_name = 's3_index'
  end
end
