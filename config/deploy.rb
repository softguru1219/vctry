# config valid for current version and patch releases of Capistrano
lock "~> 3.11.2"

set :rvm_type, :user

#deployment details
set :deploy_via, :remote_cache
set :copy_compression, :bz2
set :git_shallow_clone, 1
set :scm_verbose, true
set :use_sudo, true
set :pty, true
set :format, :pretty
set :assets_roles, [:web, :app]
set :migration_role, :db
set :rails_assets_groups, :assets

#repo details
set :scm, :git
set :repository,  "git@github.com:jeedee/vctry.git"
set :scm_username, 'github_id'
set :keep_releases, 2
set :branch, "master"


set :application, "vctry"
set :repo_url, "git@github.com:jeedee/vctry.git"

set :deploy_to, "/home/deployer/vctry"

set :puma_bind, "unix:///home/deployer/vctry/shared/tmp/sockets/puma.sock"   #accept array for multi-bind

set :tmp_dir, "/home/deployer/tmp"

append :linked_files, "config/database.yml", "config/master.key"

append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"

namespace :deploy do
  desc 'create_db'
  task :create_db do
    on roles(:app) do
      within release_path do
        execute :bundle, :exec, :"rails db:create RAILS_ENV=#{fetch(:stage)}"
      end
    end
  end

  desc 'Uploads required config files'
  task :upload_configs do
    on roles(:all) do
      upload!(".env.#{fetch(:stage)}", "#{deploy_to}/shared/.env")
    end
  end
  
  before 'deploy:migrate', 'deploy:create_db'
end

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/my_app_name"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml"

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure
