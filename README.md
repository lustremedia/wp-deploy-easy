# wp-deploy-easy

This is basically a hard fork of [wp-deploy by Mixd](https://github.com/Mixd/wp-deploy) to introduce a couple of changes to make wordpress deployments easier with the latest Capistrano version.

**wp-deploy-easy** makes following changes:

- Templating support has been dropped (no .htaccess and robots.txt). Mostly because I am using NGINX and feel that robots.txt should not be part of the deployment process.
- A local deployment with a ```development``` stage and ```capistrano-locally``` plugin has been introduced to mimic remote deployments locally.
- ```wp-config.php.erb``` template files have been merged into one file and ```define('WP_DEBUG', true);``` will be introduced according to stage.
- ```database.example.yml``` has been renamed to ```database.yml``` saving me a rename file step.
- ```config/prepare.sh``` has been replaced by ```initialize.sh``` under the project root doing the hard lifting, combining all installation steps of wp-deploy in one file.


## Prerequisites

- **Git > v1.7.3**: Git is used to pull down the website from your Git hosting and therefore is a mandatory requirement.
- **SSH access**: For wp-deploy (or Capistrano in general) to work you need SSH access both between your local machine and your remote server, and between your local machine and your Git hosting (Github, Bitbucket, CodebaseHQ, etc) account.
- **Bundler**: As WP-Deploy comes with various different Ruby Dependencies, Bundler is used to make quick work of the installation process. Here's the [link](http://bundler.io/)
- **WP-CLI (greater than 0.22.0)**: WP-Deploy also requires the automation of WordPress functions directly in the Command Line. As these functions are required on all environments (local, staging and production servers), we make use of the WordPress Command Line Interface. You can check out the [documentation](http://wp-cli.org/#install) on how to get this setup.

In addition, as this is powered by WordPress, you'll also need to follow [WordPress' requirements](https://codex.wordpress.org/Hosting_WordPress).

## Getting Started

First you want to copy the repository of wp-deploy-easy to your development environment.
```
git clone https://github.com/lustremedia/wp-deploy-easy.git my-local-copy
```

### Remote Git Repository Binding

Create a remote git repository and bind it to the wp-deploy-easy project:

Under config/deploy.rb you need to enter an external repo_url
```
...
set :application, "wp-deploy-easy"
set :repo_url, "<your external repo url here>"
...
```

Under initialize.sh you also need to ender the external repo_url

```
...
git commit -m "Inital commit"

git remote add origin <your external repo url>
git push -u origin master
...
```

### Fill In WP Credentials

Under config/deploy.rb you need to enter your initial wordpress data

```
...
# The WordPress admin user
set :wp_user, 'yourname'

# The WordPress admin email address
set :wp_email, 'yourname@example.com'

# The WordPress 'Site Title' for the website
set :wp_sitename, 'WP Deploy'

# The local environment URL.
set :wp_localurl, 'http://wpdeploy.dev'
...
```

### Database binding

You need to enter your database credentials under ```config/database.yml``` for each deployment environment

```
development:
  host: localhost
  database: db_name
  username: db_user
  password: 'db_pass'
staging:
  host: localhost
  database: db_name
  username: db_user
  password: 'db_pass'
production:
  host: localhost
  database: db_name
  username: db_user
  password: 'db_pass'
```

### Initializing The New Wordpress Project
Now, to get a working development environment we need to initialize the project.
For this, simply run initialize.sh from the root of the project tree:

```
$ sh initialize.sh
```

## Acknowledgments
A shout out to Mixd for their splendid work on [wp-deploy by Mixd](https://github.com/Mixd/wp-deploy), cheers.
