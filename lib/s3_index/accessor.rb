# module
module S3Index
  # Adds S3 backed data accessors to any ActiveRecord model
  #
  # ## Example:
  # ```
  # class Foo < ActiveRecord::Base
  #   include S3Index::Accessor
  #
  #   s3_index_accessor :s3_data,
  #     cache_dir: '/tmp'
  #     bucket: 'foo',
  #     s3_resource: Aws::S3::Resource.new
  # end
  # ```
  module Accessor
    extend ActiveSupport::Concern

    included do
      class_attribute :_s3_index_config
    end

    class_methods do
      def s3_index_accessor(name, cache_dir:, bucket: nil, s3_resource: nil)
        # IMPORTANT never move this line unless you want everything to break.
        # This ensures lowest descendent has its own hash instance.
        self._s3_index_config ||= {}

        # do the assignment
        self._s3_index_config[name] = {
          name:        name,
          cache_dir:   cache_dir,
          bucket:      bucket || name.to_s,
          s3_resource: s3_resource || Aws::S3::Resource.new
        }

        class_eval <<-RUBY, __FILE__, __LINE__
          after_save do |row|
            handle_s3_index_after_save(:#{name}, _s3_index_config[:#{name}], row)
          end
        RUBY

        class_eval(<<-RUBY.strip_heredoc, __FILE__, __LINE__)
          def #{name}=(value)
            handle_s3_index_write(:#{name}, _s3_index_config[:#{name}], value)
          end
        RUBY

        class_eval(<<-RUBY.strip_heredoc, __FILE__, __LINE__)
          def #{name}(force: false)
            handle_s3_index_read(:#{name}, _s3_index_config[:#{name}], force: force)
          end
        RUBY

        class_eval(<<-RUBY.strip_heredoc, __FILE__, __LINE__)
          def #{name}!
            #{name}(force: true)
          end
        RUBY

        class_eval(<<-RUBY.strip_heredoc, __FILE__, __LINE__)
          def #{name}_index
            handle_s3_index_record(:#{name}, _s3_index_config[:#{name}])
          end
        RUBY
      end
    end

    private

    def handle_s3_index_write(name, config, value)
      File.open(full_cache_path(config), 'wb') { |f| f << value } if self.id
      instance_variable_set("@_#{name}", value)
    end

    def handle_s3_index_read(name, config, force:)
      if force
        var_name = "@_#{name}".to_sym
        instance_variable_set(var_name, nil)
      end
      instance_var_set_if_needed(name) do
        unless File.file?(full_cache_path(config))
          index = handle_s3_index_record(name, config)
          index.download!(s3: config[:s3_resource])
        end
        File.read(full_cache_path(config))
      end
    end

    def handle_s3_index_record(name, config)
      instance_var_set_if_needed("#{name}_index") do
        Index.find_by(origin_url: full_cache_path(config), s3_bucket: config[:bucket])
      end
    end

    def handle_s3_index_after_save(name, config, row)
      value = instance_variable_get("@_#{name}")
      handle_s3_index_write(name, config, value)
      S3Index.upload!(
        s3: config[:s3_resource],
        bucket: config[:bucket],
        src: full_cache_path(config)
      )
    end

    def full_cache_path(config)
      File.join(config[:cache_dir], "#{config[:name]}-#{self.id}")
    end

    def instance_var_set_if_needed(name, &block)
      var_name = "@_#{name}".to_sym
      result = instance_variable_get(var_name)
      unless result
        result = block.call
        instance_variable_set(var_name, result)
      end
      result
    end
  end
end
