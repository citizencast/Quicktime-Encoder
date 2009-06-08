set :application, "encoding"
set :repository,  "git@github.com:citizencast/Quicktime-Encoder.git"
set :scm, :git
set :use_sudo, false
set :deploy_to, "~/revelatr/encoding"

role :app, "192.168.0.3"
role :web, "192.168.0.3"
role :db,  "192.168.0.3", :primary => true

namespace :deploy do
  desc "Install gems"
  task :install_gems, :roles => :app do
    run "cd #{release_path} && rake gems:install"
  end
  after "deploy:update_code", "deploy:install_gems"
  
  desc "Update the crontab file"
  task :update_crontab, :roles => :db do
    run "cd #{release_path} && /Users/yvon/.gem/ruby/1.8/bin/whenever --update-crontab #{application}"
  end
  after "deploy:symlink", "deploy:update_crontab"
  
end