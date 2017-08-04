namespace :wp do

  ##############################################################################
  ## Set the necessary file permissions
  ##############################################################################

  desc 'Set the necessary file permissions'
  task :set_permissions do
    on roles(:app) do
      execute :chmod, "-R 777 #{shared_path}/content/uploads"
    end
  end

  namespace :setup do

    ############################################################################
    ## Generate template files
    ############################################################################

    desc 'Generate template files'
    task :generate_remote_files do
      on roles(:web) do
        # Get details for WordPress config file
        secret_keys = capture('curl -s -k https://api.wordpress.org/secret-key/1.1/salt')
        wp_siteurl = fetch(:stage_url)
        stage = fetch(:stage).to_s
        database = YAML.load_file('config/database.yml')[stage]

        # Create template file paths based on the environment
        wpconfigFilePath = "config/wp-config.php.erb"

        # Create config file in remote environment
        db_config = ERB.new(File.read(wpconfigFilePath)).result(binding)
        io = StringIO.new(db_config)
        upload! io, File.join(shared_path, 'wp-config.php')

        # Create local wp-config.php for wp cli
        if (stage=="development")
          run_locally do
            File.open('wp-config.php', 'w') { |f| f.write(db_config) }
          end
        end

      end
      # Set some permissions
      invoke 'wp:set_permissions'
    end


    ############################################################################
    ## Setup WordPress on the remote environment
    ############################################################################

    desc 'Setup WordPress on the remote environment'
    task :remote do
      invoke 'db:confirm'
      invoke 'deploy'
      invoke 'wp:setup:generate_remote_files'
      on roles(:web) do
        within release_path do
          if !fetch(:setup_all)
            # Generate a random password
            o = [('a'..'z'), ('A'..'Z')].map(&:to_a).flatten
            password = (0...18).map { o[rand(o.length)] }.join
          else
            password = fetch(:wp_pass)
          end

          # Get WP details from config in /config
          wp_siteurl = fetch(:stage_url)
          title = fetch(:wp_sitename)
          email = fetch(:wp_email)
          user = fetch(:wp_user)

          # Install WordPress
          execute :wp, "core install --url='#{wp_siteurl}' --title='#{title}' --admin_user='#{user}' --admin_password='#{password}' --admin_email='#{email}' --debug"

          unless fetch(:setup_all)
            puts <<-MSG
            \e[32m
            =========================================================================
              WordPress has successfully been installed. Here are your login details:

              Username:       #{user}
              Password:       #{password}
              Email address:  #{email}
              Log in at:      #{wp_siteurl}/wordpress/wp-admin
            =========================================================================
            \e[0m
            MSG
          end
        end
      end
    end


    ############################################################################
    ## Setup WordPress on the local environment
    ############################################################################

    # desc 'Setup WordPress on the local environment'
    # task :local do
    #   invoke 'db:confirm'
    #   invoke 'deploy'
    #   run_locally do
    #     if !fetch(:setup_all)
    #       # Generate a random password
    #       o = [('a'..'z'), ('A'..'Z')].map(&:to_a).flatten
    #       password = (0...18).map { o[rand(o.length)] }.join
    #     else
    #       password = fetch(:wp_pass)
    #     end

    #     # Get WP details from config in /config
    #     title = fetch(:wp_sitename)
    #     email = fetch(:wp_email)
    #     user = fetch(:wp_user)
    #     wp_siteurl = fetch(:wp_localurl)
    #     stage = fetch(:stage).to_s

    #     puts "============= Running on: #{stage} ================="

    #     # Create wp-config.php
    #     database = YAML.load_file('config/database.yml')[stage]
    #     secret_keys = capture('curl -s -k https://api.wordpress.org/secret-key/1.1/salt')
    #     db_config = ERB.new(File.read('config/wp-config.php.erb')).result(binding)
    #     File.open('wp-config.php', 'w') { |f| f.write(db_config) }

    #     # Install WordPress
    #     execute :wp, "core install --url='#{wp_siteurl}' --title='#{title}' --admin_user='#{user}' --admin_password='#{password}' --admin_email='#{email}' --debug"

    #     puts <<-MSG
    #     \e[32m
    #     =========================================================================
    #       WordPress has successfully been installed. Here are your login details:

    #       Username:       #{user}
    #       Password:       #{password}
    #       Email address:  #{email}
    #     =========================================================================
    #     \e[0m
    #     MSG
    #   end
    # end


    # ############################################################################
    # ## Setup WordPress on both the local and remote environments
    # ############################################################################

    # desc 'Setup WordPress on both the local and remote environments'
    # task :both do
    #   set :setup_all, true

    #   # Generate a random password
    #   o = [('a'..'z'), ('A'..'Z')].map(&:to_a).flatten
    #   password = (0...18).map { o[rand(o.length)] }.join
    #   set :wp_pass, password

    #   # Setup remote and local envs
    #   invoke 'wp:setup:remote'
    #   invoke 'wp:setup:local'
    # end
  end

  namespace :core do

    ############################################################################
    ## Update WordPress submodule to latest version
    ############################################################################

    desc 'Update WordPress submodule to latest version'
    task :update do
      system('
      cd wordpress
      git fetch --tags
      latestTag=$(git tag -l --sort -version:refname | head -n 1)
      git checkout $latestTag
      ')
      invoke 'cache:repo:purge'
      puts 'WordPress submodule is now at the latest version. You should now commit your changes.'
    end
  end
end
