require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rbenv'

set :domain, '37.139.12.234'
set :user, 'foxweb'
set :deploy_to, '/home/foxweb/www/zxstore'
set :app_path, "#{deploy_to}/#{current_path}"
set :repository, 'git@github.com:foxweb/zxstore.git'
set :branch, `git rev-parse --abbrev-ref HEAD`.rstrip
set :shared_paths, %W(config/database.yml public/uploads public/assets log tmp)
set :keep_releases, 5

task :environment do
  invoke :'rbenv:load'
end

desc 'Sets current deploy environment to production'
task :production do
  set :branch, 'master'
end

task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/shared/public/assets"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/public/assets"]

  queue! %[mkdir -p "#{deploy_to}/shared/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/config"]
  queue! %[touch "#{deploy_to}/shared/config/database.yml"]

  queue! %[mkdir -p "#{deploy_to}/shared/sockets"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/sockets"]

  queue! %[mkdir -p "#{deploy_to}/shared/public/uploads"]
  queue! %[chmod g+rwx,u+rwx "#{deploy_to}/shared/public/uploads"]

  queue! %[mkdir -p "#{deploy_to}/shared/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/log"]

  queue! %[mkdir -p "#{deploy_to}/shared/tmp/pids"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/tmp/pids"]
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  deploy do
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'

    to :launch do
      invoke :'puma:restart'
    end
  end
end

namespace :logs do
  desc 'tail -f log/production.log'
  task :tail do
    queue "tail -f #{app_path}/log/production.log"
  end

  desc 'less log/production.log'
  task :less do
    queue "less #{app_path}/log/production.log"
  end
end

namespace :puma do
  set :bp, "cd #{app_path} && bundle exec bluepill --no-privileged"
  set :bp_config, "#{bp} load #{app_path}/config/services.pill"

  desc "Restart puma"
  task :restart => :environment do
    queue %{
      #{bp_config}
      #{bp} dev stop
      #{bp_config}
      #{bp} dev start
    }
  end

  desc "Stop puma"
  task :stop => :environment do
    queue %{
      #{bp_config}
      #{bp} dev stop
    }
  end

  desc "Start puma"
  task :start => :environment do
    queue %{
      #{bp_config}
      #{bp} dev start
    }
  end
end