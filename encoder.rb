#!/usr/bin/env ruby

require 'video'

Video.fetch_non_encoded_videos.each do |video|
  video.proceed
end
