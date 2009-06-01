require 'video'

namespace :db do
  desc "migrate"
  task(:migrate) do
    p DataMapper.auto_migrate!
  end
end
