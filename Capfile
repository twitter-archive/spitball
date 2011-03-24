require 'rubygems'
require 'railsless-deploy'

raise("You must set SPITBALL_HOST") unless ENV['SPITBALL_HOST']

default_environment.update(
  'PATH' => '/usr/local/spitball/vendor/bin:/opt/local/bin:$PATH',
  'GEM_PATH' => '/usr/local/spitball/vendor',
  'LD_LIBRARY_PATH' => '/opt/local/lib'
)

role :app, ENV['SPITBALL_HOST']

set :application, 'spitball'
set :user, 'spitball'
set :use_sudo, false

set :ssh_options, {
  :forward_agent => true,
  :paranoid => false
}

set :deploy_to, "/usr/local/#{application}"
set :repository, "."
set :scm, :none
set :deploy_via, :copy
set :working_copy, '.'
set :copy_exclude, '.git'
set :branch, variables[:branch] || 'self_hosting'

# Restarts
#after 'deploy', 'restart'

# Cleanup
set :keep_releases, 3
after 'deploy:update', 'deploy:cleanup'
