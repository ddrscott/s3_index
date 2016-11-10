require 'spec_helper'

describe S3Index do

  let(:bucket) { 's3-index-test-fake' }
  let(:src) { File.absolute_path 'spec/dummy.txt' }
  let(:uploaded) { S3Index.upload!(bucket: bucket, src: src) }

  before do
    # make some fake data
    File.open(src, 'w'){|f| f << '0123456789'}

    # make sure we don't actually make aws calls
    allow_any_instance_of(Aws::S3::Object).to receive(:upload_file)
    allow_any_instance_of(Aws::S3::Object).to receive(:get)
  end

  describe '#upload!' do
    it 'saves data' do
      expect_any_instance_of(Aws::S3::Object).to receive(:upload_file).with(
        src,
        content_type: 'text/plain',
        content_length: 10
      )
      expect(uploaded.origin_url).to eq(src)
      expect(uploaded.file_name).to eq('dummy.txt')
      expect(uploaded.content_type).to eq('text/plain')
      expect(uploaded.md5).to eq(Digest::MD5.hexdigest('0123456789'))
      expect(uploaded.size).to eq(10)
      expect(uploaded.s3_url).to eq('https://s3-index-test-fake.s3.amazonaws.com/' + src)
      expect(uploaded.s3_bucket).to eq('s3-index-test-fake')
    end

    it 'only sends it once when data is the same' do
      expect_any_instance_of(Aws::S3::Object).to receive(:upload_file).once
      2.times { S3Index.upload!(bucket: bucket, src: src) }
      expect(S3Index::Index.count).to eq(1)
    end

    it 'updates index and s3 when data changed' do
      call_count = 0

      allow_any_instance_of(Aws::S3::Object).to receive(:upload_file) do
        call_count += 1
      end

      # first upload
      S3Index.upload!(bucket: bucket, src: src)

      # change the data
      File.open(src, 'w') { |f| f << '0123456789-more' }

      expect(uploaded.origin_url).to eq(src)
      expect(call_count).to eq(2)
      expect(uploaded.md5).to eq(Digest::MD5.hexdigest('0123456789-more'))
      expect(uploaded.size).to eq(15)
      expect(S3Index::Index.count).to eq(1)
    end

    it 'raises error with invalid src' do
      expect { S3Index.upload!(bucket: bucket, src: 'path/not/found') }.to raise_error(Errno::ENOENT)
    end
  end

  describe '#download!' do
    describe 'without uploaded file' do
      it "can't download unregistered files" do
        expect { S3Index.download!(src: 'path/not/found') }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe 'with uploaded file' do
      before do
        S3Index.upload!(bucket: bucket, src: src) 
      end
      let(:last_index) { S3Index::Index.last }

      it 'download by src' do
        expect_any_instance_of(Aws::S3::Object).to receive(:get).with(response_target: src).once
        S3Index.download!(src: src)
      end

      it 'download by index' do
        expect_any_instance_of(Aws::S3::Object).to receive(:get).with(response_target: src).once
        last_index.download!
      end

      it 'download by s3_url' do
        expect_any_instance_of(Aws::S3::Object).to receive(:get).with(response_target: src).once
        S3Index.download!(s3_url: last_index.s3_url)
      end

      it 'download to different destination' do
        expect_any_instance_of(Aws::S3::Object).to receive(:get).with(response_target: 'spec/over-here').once
        last_index.download!(dst: 'spec/over-here')
      end
    end
  end
end
