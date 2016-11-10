require 'spec_helper'

begin
  ActiveRecord::Base.connection
rescue ActiveRecord::ConnectionNotEstablished
  ActiveRecord::Base.establish_connection(
    adapter: 'sqlite3',
    database: 'test.db'
  )
end

ActiveRecord::Schema.define do
  create_table :foo, force: true do |t|
    t.string :name
  end
end

module S3Index
  describe Accessor do
    class Foo < ActiveRecord::Base
      self.table_name = 'foo'

      include S3Index::Accessor

      s3_index_accessor :s3_data,
        cache_dir: 'spec/tmp/',
        bucket: 'foo',
        s3_resource: Aws::S3::Resource.new
    end

    before(:all) { FileUtils.mkdir_p 'spec/tmp/' }
    after(:all)  { FileUtils.rm_rf 'spec/tmp/'   }

    before do
      allow_any_instance_of(Aws::S3::Object).to receive(:upload_file)
      allow_any_instance_of(Aws::S3::Object).to receive(:get)
    end

    describe 'basic use' do
      let(:foo) { Foo.create!(name: 'bar', s3_data: 'Mary had a little limb') }

      it 'saves an index' do
        expect(foo.s3_data).to eq('Mary had a little limb')
        expect(foo.s3_data_index).to be_instance_of(Index)
      end

      it 'writes a cache file' do
        expect(File.file?(foo.s3_data_index.origin_url)).to be(true)
      end

      let(:reloaded) { Foo.find(foo.id) }

      it 'reloads data' do
        expect_any_instance_of(Aws::S3::Object).to receive(:get)
          .with(response_target: foo.s3_data_index.origin_url)
          .once do |response_target:|
          File.open(response_target, 'wb') { |f| f << 'Mary had a little limb' }
        end

        FileUtils.rm_rf(foo.s3_data_index.origin_url)

        expect(File.file?(reloaded.s3_data_index.origin_url)).to be(false)
        expect(reloaded.s3_data).to eq('Mary had a little limb')
      end
    end

    describe 'caching' do
      let(:foo) { Foo.create!(name: 'bar', s3_data: 'Mary had a little limb') }

      it 'only gets data once' do
        expect(foo.s3_data).to eq('Mary had a little limb')

        expect_any_instance_of(Aws::S3::Object).to_not receive(:get)
        reloaded = Foo.find(foo.id)
        expect(reloaded.s3_data).to eq('Mary had a little limb')
      end
    end
  end
end
