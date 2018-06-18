#!/usr/bin/env ruby

require_relative 'lib/aws_encrypted_bucket'

def exists?
  existing_bucket = AwsEncryptedBucket::Bucket.new(name: 'delivery-state-cloudspin-noodle', region: 'eu-west-1')
  if existing_bucket.exists?
    puts "KSM: Existing bucket exists"
  else
    puts "KSM: Existing bucket does not seem to exist"
  end

  non_existing_bucket = AwsEncryptedBucket::Bucket.new(name: 'kief-kief-kief', region: 'eu-west-1')
  if non_existing_bucket.exists?
    puts "KSM: NON-Existing bucket seems to exist"
  else
    puts "KSM: NON-Existing bucket does not exist"
  end
end

def provision(name)
  my_bucket = AwsEncryptedBucket::Bucket.new(name: name, region: 'eu-west-1')
  my_bucket.provision
  puts "Provisioned bucket '#{name}'"
end

def status(name)
  my_bucket = AwsEncryptedBucket::Bucket.new(name: name, region: 'eu-west-1')
  puts "STATUS (#{name}):\n#{my_bucket.status.to_yaml}"
end

def get_name
  the_name = ARGV.shift
  if the_name.nil?
    puts "ERROR: No bucket name given to check status for"
    exit 1
  end
  the_name
end

action = ARGV.shift
puts "ACTION: #{action}"

if action.nil?
  puts "ERROR: No action given"
  exit 1
elsif action == 'exists'
  exists?
elsif action == 'status'
  the_name = get_name
  status(the_name)
elsif action == 'provision'
  the_name = get_name
  provision(the_name)
  status(the_name)
else
  puts "ERROR: Unknown action '#{action}'"
  exit 1
end
