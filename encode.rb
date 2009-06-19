#!/usr/bin/env ruby

require 'video'

file_path = ARGV.first
raise unless file_path

v = Video.new
v.file = file_path
v.send(:encode_video) && v.send(:upload_to_s3)