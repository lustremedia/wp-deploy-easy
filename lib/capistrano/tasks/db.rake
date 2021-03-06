require 'highline/import'

namespace :db do

  ##############################################################################
  ## Create a sensible backup name for SQL files
  ##############################################################################

  desc 'Create a sensible backup name for SQL files'
  task :backup_name do
    on roles(:db) do

      # Make a new directory in your shared folder
      execute :mkdir, "-p #{shared_path}/db_backups"

      # Get the current timestamp
      backup_time = Time.now.strftime '%Y%m%d%H%M%S'

      # Set the filename as the current timestamp
      set :backup_filename, backup_time

      # Get the file's absolute path
      set :backup_file, "#{shared_path}/db_backups/#{backup_time}.sql"
    end
  end


  ##############################################################################
  ## Confirm a database action before proceeding
  ##############################################################################

  desc 'Confirms the database action before proceeeding'
  task :confirm do
    on roles(:db) do
      stage = fetch(:stage).to_s

      # Load the database details
      database = YAML.load_file('config/database.yml')[stage]

      # Set the confirmation message
      set :confirmed, proc {
        puts <<-WARN
              \033[31m
              ========================================================================

                WARNING: You're about to overwrite the database!
                To continue, please enter the name of the database for this site.

                Datebase name:\033[0m \033[1m \033[34m #{database['database']} \033[0m \033[22m \033[31m

              ========================================================================
              \033[0m
              WARN

        # Prompt the user to write out the database name
        ask :answer, database['database']

        # If user correctly inputs the database name then continue with the action
        if fetch(:answer) == database['database']
          true

        # If not, give them another chance, assuming they haven't already had 3
        else
          loopCount = 1
          loop do
            loopCount += 1
            puts "\033[31mYou typed the database name incorrectly. Please enter \033[0m\033[1m\033[34m#{database['database']}\033[0m\033[22m\033[0m\033[0m"
            ask :answer, database['database']
            break if loopCount == 3
            break if fetch(:answer) == database['database']
          end
        end

        true if fetch(:answer) == database['database']
      }.call

      # Error message to show to user
      unless fetch(:confirmed)
        puts <<-WARN
              \033[31m
              ========================================================================
                Sorry, you have entered the database name incorrectly too many times
              ========================================================================
              \033[0m
              WARN
        exit
      end
    end
  end

  desc 'Simple Yes confirmation'
  task :confirm_yes do
    on roles(:db) do

    stage = fetch(:stage).to_s

    exit unless HighLine.agree(
      <<-WARN
      \033[31m
      ================================================================================

        WARNING: You're about to overwrite the database!
        Are you sure you want to overwrite the local database with that of #{stage}?

        If so please type: 'yes' or 'y' otherwise type 'no' or 'n'

      ================================================================================
      \033[0m
      WARN
    )
    end
  end


  ##############################################################################
  ## Take a database dump from remote server
  ##############################################################################

  desc 'Take a database dump from remote server'
  task :backup do
    invoke 'db:backup_name'
    on roles(:db) do
      within release_path do
        execute :wp, "db export #{fetch(:backup_file)} --add-drop-table"
      end

      system('mkdir -p db_backups')
      download! "#{fetch(:backup_file)}", "db_backups/#{fetch(:backup_filename)}.sql"

      within release_path do
        execute :rm, "#{fetch(:backup_file)}"
      end
    end
  end


  ##############################################################################
  ## Imports the remote database to your local environment
  ##############################################################################

  desc 'Import the remote database to your local environment'
  task :pull do
    invoke 'db:confirm_yes'
    invoke 'db:backup'

    on roles(:db) do
      run_locally do
        execute :wp, "db import db_backups/#{fetch(:backup_filename)}.sql"
        execute :wp, "search-replace #{fetch(:stage_url)} #{fetch(:wp_localurl)}"
        execute :rm, "db_backups/#{fetch(:backup_filename)}.sql"
        execute :rmdir, 'db_backups' if Dir['db_backups/*'].empty?
      end
    end
  end


  ##############################################################################
  ## Import the local database to your remote environment
  ##############################################################################

  desc 'Import the local database to your remote environment'
  task :push do
    invoke 'db:backup_name'
    invoke 'db:confirm'
    on roles(:db) do
      run_locally do
        execute :mkdir, '-p db_backups'
        execute :wp, "db export db_backups/#{fetch(:backup_filename)}.sql --add-drop-table"
      end

      upload! "db_backups/#{fetch(:backup_filename)}.sql", "#{fetch(:backup_file)}"

      within release_path do
        execute :wp, "db import #{fetch(:backup_file)}"
        execute :wp, "search-replace #{fetch(:wp_localurl)} #{fetch(:stage_url)}"
        execute :rm, "#{fetch(:backup_file)}"
      end

      run_locally do
        execute :rm, "db_backups/#{fetch(:backup_filename)}.sql"
        execute :rmdir, 'db_backups' if Dir['db_backups/*'].empty?
      end
    end
  end

end
