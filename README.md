# S3Index

Keeps an index of AWS S3 objects in a database table as objects are uploaded to AWS.

```sql
sqlite> .headers on
sqlite> SELECT * FROM s3_index;
```

|id|origin_url|file_name|content_type|md5|size|s3_url|s3_bucket|created_at|updated_at|
|---|----------|---------|------------|---|----|------|---------|----------|----------|
|1|README.md|README.md|text/plain|58f96630cec6e641fcb440abde5d1f11|1334|https://example.s3.amazonaws.com/README.md|example|2016-11-10 10:11:42.871147|2016-11-10 10:11:42.871147|
|2|/data/images/avatar.png|avatar.png|image/png|9a84d4c8fdf5a74cacba47346602a38e|35|https://example.s3.amazonaws.com/data/images/avatar.png|example|2016-11-10 20:52:46.011296|2016-11-10 20:53:22.884595|

We also provide a simple ActiveRecord helper which provides an 
`s3_index_accessor :data` to quickly attach data to an existing ActiveRecord.
The feature is similar to Paperclip, CarrierWave and others, but with this gem
we maintain a separate table that reflects what's stored on S3.

The benefits of the `s3_index` table is fast querying and analytics around S3
object utilization. The table also keeps track of the data's origin for other auditing
needs.

## Usage

### Upload a source file to a bucket.

```ruby
# Uploads a local file into S3.
S3Index.upload!(bucket: 'example', src: 'avatar.png')
# => #<S3Index::Index:0x007f8eb11a4c98
# id: 26,
# origin_url: "avatar.png"
# ...
```

### Download the original source file from S3.

```ruby
# Downloads a file from S3 back to the original `src` location.
S3Index.download!(src: 'avatar.png')
# => #<struct Aws::S3::Types::GetObjectOutput
# body=#<Seahorse::Client::ManagedFile:avatar.png (closed)>,
# delete_marker=nil
# ...
```

### Download to a different location try

```ruby
S3Index.download!(src: 'avatar.png', dst: 'some/where/else.png')
```

### Download a specific S3Index entry:

```ruby
index = S3Index.first
puts index.origin_url
# => avatar.png

index.download!

File.read(index.origin_url)
# => binary data...
```

### Create an S3Index Backed Data Attribute

This should look familiar to other attachment gems.

```ruby
class Post < ActiveRecord::Base
  include S3Index::Accessor

  s3_index_accessor :featured_image,
                    cache_dir:   'tmp/cache/images',
                    bucket:      'example-post-images'
                    s3_resource: Aws::S3::Resource.new
end
```

`s3_index_accessor` will add a few methods to your model:

1. `featured_image` - read the S3 object.
2. `featured_image=` - write the S3 object.
3. `featured_image_index` - returns the `S3Index::Index` model

Use the attribute just like any other attribute:

```ruby
# get the image data from some where
image_data = parse_image_data(request)
post = Post.create!(title: 'hello', featured_image: image_data)

# change the data
post.featured_image = File.read('blank.png')
post.save!
```

## Prerequisites

### Get and Setup AWS Credentials

Please refer to the AWS documentation: https://github.com/aws/aws-sdk-ruby.

TL;DR - Create a file `~/.aws/credentials` and fill it in with:

```
[default]
aws_access_key_id = XXXXXXXXXXXXX
aws_secret_access_key = YYYYYYYYYYYYY
```

Test for something working in the console:

    $ bin/console

```ruby
# returns a list of buckets associated on the AWS account.
Aws::S3::Resource.new.buckets.entries
# => []
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 's3_index'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install s3_index

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ddrscott/s3_index.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

