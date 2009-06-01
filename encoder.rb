require 'rubygems'
require 'aws/s3'
require 'net/http'
require 'uri'
require 'open-uri'

def connect_to_s3
  AWS::S3::Base.establish_connection!(
    :access_key_id     =>  ENV['AMAZON_ACCESS_KEY_ID'],
    :secret_access_key =>  ENV['AMAZON_SECRET_ACCESS_KEY']
  ) unless AWS::S3::Base.connected?
end

def title
  return @title if @title
  @title = "#{random_digits}"
end

def random_digits
  Array.new(5) { rand(10) }.join
end

def upload_to_s3(path)
  connect_to_s3
  
  puts "upload #{path}"
  AWS::S3::S3Object.store(path, File.open(path), 'encoded-videos', :access => :public_read)
  
  puts "http://s3.amazonaws.com/encoded-videos/#{path}"
  true
end

def encode_video(file)
  cmd = "./encoder #{file.path} #{title}"
  puts cmd
  system cmd
  true
end

def download_video(url)
  puts "Downloading #{url}..."
  
  file = File.new(File.basename(url), 'w+')
  
  file.write(open(url).read)
  file.close
  return (file)
end

raise unless ARGV[0]
file = download_video(ARGV[0])
if file
  encode_video(file) &&
    upload_to_s3(title + '.flv') &&
    upload_to_s3(title + '.jpg')
end