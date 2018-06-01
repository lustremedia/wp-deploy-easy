# Load DSL and set up stages
require "capistrano/setup"

# Include default deployment tasks
require "capistrano/deploy"

# Load the SCM plugin appropriate to your project:
#
require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

# Include the git submodule strategy for capistrano
require "capistrano/scm/git-with-submodules"
install_plugin Capistrano::SCM::Git::WithSubmodules

require 'capistrano/locally'

require 'yaml'

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }
