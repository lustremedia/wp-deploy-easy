# The Git branch this environment should be attached to.
set :branch, 'master'

# The environment's name. To be used in commands and other references.
set :stage, :production

# The URL of the website in this environment.
set :stage_url, 'http://www.example.com'

# The environment's server credentials
server 'X.X.X.X', user: 'ssh_user_on_server', roles: %w(web app db)

# The deploy path to the website on this environment's server.
set :deploy_to, '/deploy/to/path'
