# The Git branch this environment should be attached to.
set :branch, 'development'

# The environment's name. To be used in commands and other references.
set :stage, :development

# The URL of the website in this environment.
set :stage_url, 'http://www.example.com'

# The environment's server credentials
server 'localhost', roles: %w(web app db)

# The deploy path to the website on this environment's server.
set :deploy_to, '/deploy/to/path'
