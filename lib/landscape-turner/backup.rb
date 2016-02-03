require_relative 'helpers'
require 'fileutils'
require 'pathname'
require 'open3'
require 'trollop'

class Backup
  extend LandscapeTurner::Helpers

  def self.backup_with_cli_args(args = ARGV)
    paths = {
      :x509_certificate  => "/etc/ssl/certs/landscape_server.pem",
      :ca_certificate    => "/etc/ssl/certs/landscape_server_ca.crt",
      :ssl_private_key   => "/etc/ssl/private/landscape_server.key",
      :postgresql_config => "/etc/postgresql/9.3/main",
      :apache_config     => "/etc/apache2/sites-available/landscape-server.conf",
      :hash_id_database  => "/var/lib/landscape/hash-id-databases",
      :landscape_dir     => "/etc/landscape",
      :landscape_default => "/etc/default/landscape-server",
    }

    new_args = Trollop.options(args) do
      opt :snapshot_path,         "Path to snapshot (required)",                             :type => String
      opt :override,              "Override paths with -o name1=path1",                      :type => :strings
      opt :disable,               "Disable paths with -d name",                              :type => :strings
      opt :no_db,                 "Disable database backup"
      opt :landscape_prefix,      "Path to prefix default landscape dirs (/var, /etc) with", :default => ""
      opt :no_op,                 "No-op (dry run)"
      opt :sudo,                  "Program to use as sudo",                                  :default => "sudo"

      banner <<-USAGE
To override specific paths, use -o name1=path1 -o name2=path2 -o name3=path3
To disable specific paths for backup, use -d name1 -d name2
Overrides have higher priority than --landscape-prefix.

Names with default values:
#{paths.keys.map { |k| "  #{k}: #{paths[k]}"} }
      USAGE
    end

    @@sudo = new_args[:sudo]

    prefix = new_args[:landscape_prefix]
    paths.each { |k, v| paths[k] = "#{prefix}#{v}" }

    (new_args[:override] || []).each do |o|
      key, val = o.split("=")
      key = key.to_sym
      raise "Unrecognized name argument: #{key.inspect}!" unless paths[key]
      paths[key] = val
    end

    (new_args[:disable] || []).each do |d|
      raise "Unrecognized name argument: #{d.inspect}!" unless paths[key]
      paths.delete d.to_sym
    end

    backup_landscape(new_args, paths, prefix)
  end

  def self.backup_landscape(params = {}, paths, prefix)
    #check required arguments needed
    unless params[:snapshot_path]
      raise ArgumentError,  "Error: Must supply snapshot path with --snapshot-path"
    end
    destination = params[:snapshot_path] + "/"
    operate = !params[:no_op]

    #create the top-level destination path
    operate ? (FileUtils.mkdir(destination) rescue nil) : nil

    paths.each do |name, path|
      # Get path relative to landscape_prefix
      rel_path = Pathname.new(path).relative_path_from(Pathname.new(File.expand_path(prefix))).to_s

      # Make sure destination subdir exists
      dest_subdir = File.dirname "#{destination}/#{rel_path}"
      puts "Copying #{path} to #{dest_subdir}..."
      FileUtils.mkdir_p dest_subdir if operate
      FileUtils.cp_r(path, dest_subdir, :preserve => true) if operate
    end

    puts "Backing up Postgres databases.."
    (operate && !params[:no_db]) ? dump_landscape_databases(destination) : nil
    destination = params[:snapshot_path]
    puts "Compressing to file #{destination}.tar.gz"
    tgz_file = "#{File.basename(destination)}.tar.gz"
    operate ? safe_system("cd #{destination} && rm -f #{tgz_file} && tar -cpzf #{tgz_file} * && mv #{tgz_file} ..") : nil
    if operate && !check_consistent_tar(destination)
      raise "Tarball inconsistent with backup"
    end
    # remove the folder where we stored everything
    operate ? FileUtils.remove_dir(destination) : nil
    puts "Finished backing up to #{destination}"     
  end

  def self.dump_landscape_databases(backup_destination)
    FileUtils.mkdir("#{backup_destination}/postgresql_backup") rescue nil
    get_landscape_databases().each { |database_name| 
    # pg_dump dbname > outfile
    safe_system("cd /tmp && sudo -u postgres pg_dump #{database_name} > #{database_name}.bak")
    FileUtils.mv("/tmp/#{database_name}.bak","#{backup_destination}/postgresql_backup/")
    }  
  end

  def self.check_consistent_tar(destination)
    FileUtils.rm_rf("/tmp/tar_check")
    puts "cd #{File.dirname(destination)} && mkdir /tmp/tar_check && tar -xf #{File.basename(destination)}.tar.gz -C /tmp/tar_check"
    safe_system("cd #{File.dirname(destination)} && mkdir /tmp/tar_check && tar -xf #{File.basename(destination)}.tar.gz -C /tmp/tar_check")
    hash_folder1 = Open3.capture3("find #{destination} -type f 2>/dev/null -exec md5sum {} \;")
    hash_folder2 = Open3.capture3("find /tmp/tar_check -type f 2>/dev/null -exec md5sum {} \;")
    FileUtils.rm_rf("/tmp/tar_check")
    return hash_folder1 == hash_folder2     
  end

end
