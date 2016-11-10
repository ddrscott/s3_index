require 's3_index/version'
require_relative '../lib/environment'

# Namespaces
module S3Index
  extend ActiveSupport::Autoload

  autoload :Index

  module_function

  def env
    @env ||= ActiveSupport::StringInquirer.new(ENV['S3_INDEX_ENV'])
  end

  # Use like `Rails.root`
  # @return [Pathname]
  def root
    @root ||= Pathname(File.expand_path('../..', __FILE__))
  end

  def logger
    @logger ||= ActiveRecord::Base.logger
  end

  def logger=(logger)
    @logger = logger
  end

  def upload!(s3: default_client, bucket:, src:, dst: src)
    obj = s3.bucket(bucket).object(dst)

    index = index_for_src(src)
    index_attrs = index_attributes_for(src)

    # nothing to do, file is registered and the same as before
    return index if index.md5 == index_attrs[:md5]

    # try to get the data to s3 first, then save in index.
    # order is important, we don't want to make the row until
    # S3 gets the file.
    obj.upload_file(
      src,
      content_type: index_attrs[:content_type],
      content_length: index_attrs[:size]
    )

    index.s3_url = obj.public_url
    index.s3_bucket = obj.bucket_name
    index.update!(index_attrs)
    index
  end

  def download!(s3: default_client, src: nil, s3_url: nil, index: nil, dst: nil)
    src || s3_url || index ||
      raise(ArgumentError, 'src:, s3_url:, or index: must be provided!')

    index ||=
      begin
        finder = src ? { origin_url: src } : { s3_url: s3_url }
        Index.find_by(finder) || raise(ActiveRecord::RecordNotFound, "S3Index::Index not found by #{finder}")
      end

    obj = s3.bucket(index.s3_bucket).object(index.origin_url)
    obj.get(response_target: dst || index.origin_url)
  end

  def index_for_src(src)
    Index.where(origin_url: src).first_or_initialize
  end

  def index_attributes_for(path)
    {
      md5: Digest::MD5.file(path).to_s,
      file_name: File.basename(path),
      content_type: MIME::Types.type_for(path).first.try(:content_type),
      size: File.size(path)
    }
  end

  def default_client
    @s3_client ||= new_client
  end

  def new_client
    credentials = Aws::SharedCredentials.new(profile_name: 'default')
    client = Aws::S3::Client.new(
      credentials: credentials,
      http_wire_trace: $DEBUG,
      logger: logger
    )
    Aws::S3::Resource.new(client: client)
  end

  def default_client=(client)
    @s3_client = client
  end
end

S3Index.eager_load!
