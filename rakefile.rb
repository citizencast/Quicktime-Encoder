namespace :db do
  desc "migrate"
  task(:migrate) do
    require 'video'    
    p DataMapper.auto_migrate!
  end
end

namespace :gems do
  desc "Install gems"
  task(:install) do
    File.open(".gems").readlines.each do |line|
      line.chomp!
      gem_name, source = line.split
      cmd = "gem install #{gem_name} --source http://gems.rubyforge.org"
      cmd += " --source #{source}" if source
      puts cmd
      raise unless system(cmd)
    end
  end
end

namespace :app do
  desc "Encode videos"
  task(:encode) do
    require 'video'

    Video.fetch_non_encoded_videos.each do |video|
      video.proceed
    end
  end
end