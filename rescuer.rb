require 'logger'
require 'rubygems'
require 'net/http'
require 'uri'
require 'open-uri'
require 'progressbar'
require 'aws/s3'

require 'config/env.rb'

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
    logger.info "\n\nstarting rescue at #{Time.now}"
    open("#{REVELATR}/en/last_failed_encoding") { |response|
      name = response.readline.split "."
      Rescuer.new(name[0], name[1]).rescue_video
    }
  rescue OpenURI::HTTPError => e
    logger.info "nothing to rescue: #{e.inspect}"
  end
  
  def rescue_video
    logger.info "rescuing #{original}"
    (download && encode && upload && tell_rails("encoding_rescued")) || tell_rails("encoding_rescue_failed")
  rescue Interrupt => ipt
    logger.info "interrupt, stopping"
  rescue Exception => e
    logger.info "rescue failed: updating server: #{e.class}"
    logger.info e.backtrace
    tell_rails("encoding_rescue_failed")
  end

  def encode
    cmd = "./bin/encoder #{original} #{s3_name}"
    logger.info cmd
    logger.info `#{cmd}`
    
    File.exist?("#{s3_name}.flv") && File.exist?("#{s3_name}.jpg")
  end

  def download
    url = "#{S3_ORIGINALS}/#{original}"
    uri = URI(url)
    file = File.new(original, 'w+')

    Net::HTTP.get_response(uri) do |res|
      size = res.header['Content-Length'].to_i
      logger.info "rescuing #{original}, #{size} bytes"
      res.read_body do |chunk|
        file.write(chunk)
      end
    end

    print "\n"
    
    file.close
    logger.info "downloaded to #{file.path}"
    true
  end

  def upload
    connect_to_s3

    ['flv', 'jpg'].each do |encext|
      path = "#{s3_name}.#{encext}"
      logger.info ""
      logger.info "Uploading to http://s3.amazonaws.com/encoded-videos/#{path} ..."
      STDOUT.flush
      begin
        AWS::S3::S3Object.store(path, File.open(path), 'encoded-videos', :access => :public_read)
      rescue Exception => e
        logger.info "couldn't upload #{path}, got #{e.inspect}"
        logger.info e.backtrace
        raise e
      end
      logger.info " ... done"
    end
    true
  end

  def tell_rails result, hd = false
    url = "#{REVELATR}/#{result}/#{SECRET}/#{s3_name}?hd=#{hd}"
    Net::HTTP.post_form(URI(url), "_method" => "PUT")
    logger.info "updated revelatR: #{result}"
    true
  end
  
  def self.logger
    @@rescue_log ||= returning(Logger.new("log/rescue.log", 'weekly')) { |lg| lg.level = Logger::INFO }
  end
  
  def logger
    Rescuer.logger
  end
end


