require_relative 'aws_encrypted_bucket/version'
require 'aws-sdk'
require 'yaml'

module AwsEncryptedBucket
  class Bucket

    attr_reader :name, :region, :tags

    def initialize(name:, region:, tags: {})
      @name = name
      @region = region
      @tags = tags
    end

    def exists?
      begin
        client.head_bucket({
          bucket: name,
        })
        true
      rescue Aws::S3::Errors::NotFound
        false
      rescue Aws::S3::Errors::Http301Error
        STDERR.puts "WARNING: Bucket probably exists, but belongs to someone else"
        false
      end
    end

    def provision()
      unless exists?
        client.create_bucket(bucket: name)
      end
      enable_versioning
      set_tags
    end

    def status()
      if exists?
        {
          :name => name,
          :usable => true,
          :location => get_location,
          :encryption => get_encryption,
          :acl_grants => get_acl_grants
        }
      else
        {
          :name => name,
          :usable => false
        }
      end
    end

    def destroy()
      raise 'destroy() Not implemented'
      # if exists?
      #   client.
      # else
      #   STDERR.puts "Can't destroy #{name} because it doesn't exist or belongs to someone else"
      # end
    end

    private

    def client
      unless @client
        @client = Aws::S3::Client.new(region: region)
      end
      @client
    end

    def enable_versioning
      resp = client.put_bucket_versioning({
      bucket: name, 
        versioning_configuration: {
          mfa_delete: "Disabled", 
          status: "Enabled", 
        }, 
      })
    end

    def set_tags
      client.put_bucket_tagging({
        bucket: name, 
        tagging: { tag_set: tag_map }
      })
    end

    def tag_map
      tags.map { |key, value|
        {
          key: key,
          value: value
        }
      }
    end

    def get_acl_grants
      acl = client.get_bucket_acl({bucket: name})
      {
        :owner => acl.owner.display_name,
        :grants => acl.grants.map { |grant|
          {
            :grantee => grant.grantee.display_name,
            :permission => grant.permission
          }
        }
      }
    end

    def get_location
      client.get_bucket_location({bucket: name}).location_constraint
    end

    def get_encryption
      begin
        client.get_bucket_encryption({bucket: name})
      rescue Aws::S3::Errors::ServerSideEncryptionConfigurationNotFoundError
        'NONE'
      end
    end


  end
end
