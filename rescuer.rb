require 'rubygems'
require 'net/http'
require 'uri'
require 'open-uri'
require 'progressbar'
require 'aws/s3'

require 'config/env.rb' if File.exist?('config/env.rb')

def connect_to_s3
  AWS::S3::Base.establish_connection!(S3_CREDENTIALS) unless AWS::S3::Base.connected?
end

class Rescuer
  attr_accessor :s3_name, :ext

  def initialize s3_name, ext
    self.s3_name = s3_name
    self.ext = ext
  end

  def original
    "#{s3_name}.#{ext}"
  end

  def self.do_rescue
    open("#{REVELATR}/last_failed_encoding") { |response|
      name = response.readline.split "."
      Rescuer.new(name[0], name[1]).rescue_video
    }
  rescue OpenURI::HTTPError => e
    puts "nothing to rescue: #{e.inspect}"
  end
  
  def rescue_video
    (download && encode && upload && tell_rails("encoding_rescued")) || tell_rails("encoding_rescue_failed")
  rescue Interrupt => ipt
    puts "interrupt, stopping"
  rescue Exception => e
    puts "rescue failed: updating server: #{e.class}"
    puts e.backtrace
    tell_rails("encoding_rescue_failed")
  end

  def encode
    cmd = "./bin/encoder #{original} #{s3_name}"
    puts cmd
    system(cmd)
    
    File.exist?("#{s3_name}.flv") && File.exist?("#{s3_name}.jpg")
  end

  def download
    url = "#{S3_ORIGINALS}/#{original}"
    uri = URI(url)
    file = File.new(original, 'w+')

    Net::HTTP.get_response(uri) do |res|
      size = res.header['Content-Length'].to_i
      puts "rescuing #{original}, #{size} bytes"
      prog = ProgressBar.new(s3_name, size)
      prog.file_transfer_mode
      down = 0
      dots = 0
      res.read_body do |chunk|
        file.write(chunk)
        down += chunk.size
        prog.set down
      end
    end

    print "\n"
    
    file.close
    puts "downloaded to #{file.path}"
    true
  end

  def upload
    connect_to_s3

    ['flv', 'jpg'].each do |encext|
      path = "#{s3_name}.#{encext}"
      puts ""
      print "Uploading to http://s3.amazonaws.com/encoded-videos/#{path} ..."
      STDOUT.flush
      begin
        AWS::S3::S3Object.store(path, File.open(path), 'encoded-videos', :access => :public_read)
      rescue Exception => e
        puts "couldn't upload #{path}, got #{e.inspect}"
        puts e.backtrace
        raise e
      end
      puts " ... done"
    end
    true
  end

  def tell_rails result
    url = "#{REVELATR}/#{result}/#{SECRET}/#{s3_name}"
    Net::HTTP.post_form(URI(url), "_method" => "PUT")
    puts "updated revelatR: #{result}"
    true
  end
end
