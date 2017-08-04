# config valid only for current version of Capistrano
lock "3.8.1"

set :application, "wp-deploy-easy"
set :repo_url, "<your external repo url here>"

# The WordPress admin user
set :wp_user, 'yourname'

# The WordPress admin email address
set :wp_email, 'yourname@example.com'

# The WordPress 'Site Title' for the website
set :wp_sitename, 'WP Deploy'

# The local environment URL.
set :wp_localurl, 'http://wpdeploy.dev'

################################################################################
## Setup Capistrano
################################################################################

set :log_level, :debug
set :keep_releases, 2
set :use_sudo, false
set :ssh_options, forward_agent: true


################################################################################
## Linked files and directories (symlinks)
################################################################################

set :linked_files, %w(wp-config.php)
set :linked_dirs, %w(content/uploads)

namespace :deploy do
  desc 'create WordPress files for symlinking'
  task :create_wp_files do
    on roles(:app) do
      execute :touch, "#{shared_path}/wp-config.php"
    end
  end

  after 'check:make_linked_dirs', :create_wp_files
  after :finishing, 'deploy:cleanup'
end
