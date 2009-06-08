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
  
  desc "Compile encoder"
  task :compile, :roles => :app do
    run "cd #{release_path} && make"
  end
  
  desc "Update the crontab file"
  task :update_crontab, :roles => :db do
    run "cd #{release_path} && /Users/yvon/.gem/ruby/1.8/bin/whenever --update-crontab #{application}"
  end
  after "deploy:symlink", "deploy:update_crontab"
  
  task :migrate, :roles => :db, :only => { :primary => true } do
    rake = fetch(:rake, "rake")
    migrate_target = fetch(:migrate_target, :latest)

    directory = case migrate_target.to_sym
      when :current then current_path
      when :latest  then current_release
      else raise ArgumentError, "unknown migration target #{migrate_target.inspect}"
      end

    run "cd #{directory}; #{rake} db:migrate"
  end
  
  desc "Set up symb links"
  task :symlinks, :roles => :app do
    run <<-CMD
      ln -s #{shared_path}/db.sqlite3 #{latest_release}/db
    CMD
  end
  after "deploy:finalize_update", "deploy:symlinks"
  
  [:start, :stop, :restart].each do |t|
    desc "#{t.to_s.capitalize} task is a no-op."
    task t, :roles => :app do ; end
  end
end