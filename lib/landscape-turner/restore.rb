#
# Copyright 2016, DAQRI LLC.
#
# This code is covered by the MIT License (see LICENSE.txt)

require_relative 'helpers'
require_relative 'backup'
require 'fileutils'

# TODO: Document that overridden files get restored to their
# original location

class Restore
  extend LandscapeTurner::Helpers
  POSTGRES_CONFIG = "/etc/postgresql/9.5/main"
  EXCLUDE_FILES = [POSTGRES_CONFIG]
  def self.restore_with_cli_args(args = ARGV)
    opts = Trollop.options(args) do
      opt :restore_prefix, "Prefix to prepend default landscape dirs (/var, /etc) with", :default => ""
      opt :no_db,          "Disable database restore"
      opt :sudo,           "Program to use as 'sudo'",                                   :default => "sudo"

      banner <<-USAGE
In addition to optional arguments, give exactly one .tar.gz file to restore.
      USAGE
    end

    raise "You must supply exactly one argument, the backup path!" unless args.size == 1
    @@sudo = opts[:sudo]
    restore_landscape args[0], opts
  end

  def self.with_service_stopped(service)
    begin
      safe_system("#{@@sudo} service #{service} stop")
      yield
    ensure
      safe_system("#{@@sudo} service #{service} start")
    end
  end

  def self.restore_landscape(backup_loc, options = {})

    with_service_stopped("landscape-server") do
      expanded_path = File.expand_path(backup_loc)
      FileUtils.rm_rf "/tmp/landscape_backup"
      FileUtils.mkdir "/tmp/landscape_backup"
      safe_system "cd /tmp/landscape_backup && tar xpf \"#{expanded_path}\""

      Dir["/tmp/landscape_backup/*"].each do |top_level|
        sub_path = top_level.sub /^\/tmp\/landscape_backup/, ""
        next if EXCLUDE_FILES.any? { |exc| sub_path[exc] }
        new_location = File.join options[:restore_prefix], sub_path
        replace new_location, top_level
      end

      puts "Restoring Postgres"
      unless options[:no_db]
        restore_landscape_databases("/tmp/landscape_backup/postgresql_backup")
        with_service_stopped("postgresql") do
          replace(POSTGRES_CONFIG,"/tmp/landscape_backup/#{POSTGRES_CONFIG}")
        end
      end

      puts "Restoration of Landscape configuration completed."

      FileUtils.rm_rf "/tmp/landscape_backup" rescue nil
    end

  end

  def self.replace(filename_replace,filename)
    puts "Copying #{filename} to #{File.dirname(filename_replace)}..."
    FileUtils.cp_r(filename, File.dirname(filename_replace), :preserve => true, :remove_destination => true)
  end


  def self.restore_landscape_databases(restore_location)
    #clear the databases first
    Dir["#{restore_location}/*"].each { |database_name|
      database_name = File.basename(database_name)
      database_name.slice!(".bak")
      safe_system("cd /tmp && sudo -u postgres dropdb #{database_name}") rescue nil
      safe_system("cd /tmp && sudo -u postgres createdb #{database_name}")
      # psql dbname < infile
      safe_system("cd /tmp && sudo -u postgres psql #{database_name} < #{restore_location}/#{database_name}.bak")
    }

  end


end
