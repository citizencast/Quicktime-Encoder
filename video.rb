require 'rubygems'
require 'net/http'
require 'uri'
require 'open-uri'
require 'hpricot'
require 'sqlite3'
require 'datamapper'
require 'progressbar'
require 'aws/s3'

# A Sqlite3 connection to a database file:
DataMapper.setup(:default, "sqlite3:///#{Dir.pwd}/db/db.sqlite3")

require 'config/env.rb' if File.exists?('config/env.rb')

def connect_to_s3
  AWS::S3::Base.establish_connection!(
    :access_key_id     =>  ENV['AMAZON_ACCESS_KEY_ID'],
    :secret_access_key =>  ENV['AMAZON_SECRET_ACCESS_KEY']
  ) unless AWS::S3::Base.connected?
end

class Video
  include DataMapper::Resource
  
  property :id,                   Integer,  :serial => true
  property :url,                  String,   :size => 200
  property :size,                 Integer
  property :success,              Boolean
  property :thumbnail,            String,   :size => 200
  property :video,                String,   :size => 200
  
  def proceed
    puts "Processing video #{id} (#{url})..."
    
    if Video.get(self.id)
      puts "Video #{id} allready exists"
      return false
    end
    
    success = download_video && encode_video && upload_to_s3 && update_merb_application
    puts "-- SUCCESS: #{success} --"
    raise self.errors unless self.save
    
    return true
  end
  
  def Video.fetch_non_encoded_videos
    doc = Hpricot(open("http://ec2-174-129-124-26.compute-1.amazonaws.com/videos/failed.xml"))
  
    tab = Array.new
  
    doc.search("//video").each do |vid|
      vid_id =  vid.at("id").inner_html.to_i
      vid_url = vid.at("original").inner_html
    
      tab << Video.new(:id => vid_id, :url => vid_url)
    end
  
    return tab
  end
  
  private
  
  def title
    return @title if @title
    @title = "#{id}_#{random_digits}_42"
  end

  def random_digits
    Array.new(5) { rand(10) }.join
  end
  
  def update_merb_application
    # TODO: Dynamic id
    url = ::URI.parse("http://ec2-174-129-124-26.compute-1.amazonaws.com/videos/#{self.id}.xml")
    req = Net::HTTP::Put.new(url.path)

    req.set_form_data(
      'video[thumbnail]' => thumbnail,
      'video[encoded]' => video
    )

    resp = Net::HTTP.new( url.host, url.port ).start{ |http| http.request( req )}
    raise unless resp.code == '200'
    
    url = ::URI.parse("http://ec2-174-129-124-26.compute-1.amazonaws.com/videos/#{self.id}/ping_remote_app")
    req = Net::HTTP::Put.new(url.path)
    resp = Net::HTTP.new( url.host, url.port ).start{ |http| http.request( req )}
    raise unless resp.code == '200'
    
    true
  end
  
  def upload_to_s3
    connect_to_s3

    ['.flv', '.jpg'].each do |ext|
      path = title + ext
      puts "Uploading #{path}..."
      AWS::S3::S3Object.store(path, File.open(path), 'encoded-videos', :access => :public_read)

      puts "http://s3.amazonaws.com/encoded-videos/#{path}"
    end
    
    self.video     = "http://s3.amazonaws.com/encoded-videos/#{title}.flv"
    self.thumbnail = "http://s3.amazonaws.com/encoded-videos/#{title}.jpg"

    true
  end

  def encode_video
    raise unless @file

    cmd = "./bin/encoder #{@file.path} #{title}"
    system(cmd)
  end

  def download_video
    @file = File.new(File.basename(url), 'w+')

    @file.write(open(url,
      :content_length_proc => lambda { |size|
        @pbar = ProgressBar.new(url, size)
        self.size = size
      },
      :progress_proc => lambda { |read|
        @pbar.set(read)
      }
    ).read)
    
    print "\n"
    
    @file.close
    return (@file)
  end
end