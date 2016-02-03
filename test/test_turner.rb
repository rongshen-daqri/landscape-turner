#
# Copyright 2016, DAQRI LLC.
#
# This code is covered by the MIT License (see LICENSE.txt)

require 'minitest'
require 'minitest/autorun'

require 'landscape-turner/restore'
require 'landscape-turner/backup'

require 'fileutils'

class TestTurner < Minitest::Test
  # Make sure the permissions before and after the backup are the same
  def test_permissions_intact()
    check_files = [
      "/etc/ssl/certs/landscape_server.pem",
      "/etc/landscape",
      "/etc/default/landscape-server",
      "/var/lib/landscape/hash-id-databases",
      "/etc/ssl/certs/landscape_server_ca.crt",
      "/etc/postgresql/9.3/main",
      "/etc/apache2/sites-available/landscape-server.conf",
    ]
    # This is a bit of a hack - better to not change directory
    Dir.chdir File.dirname(__FILE__)
    old_perms = check_files.inject({}) { |h, file| h[file] = File.stat("fixtures/basic" + file); h }

    # TODO: actually test with database restore; this requires more dependencies installed
    Backup.backup_with_cli_args ["--no-db", "--sudo", "echo", "--snapshot-path", "/tmp/testing_backup",
                                 "--landscape-prefix", File.expand_path(File.join File.dirname(__FILE__), "fixtures/basic")]
    FileUtils.mkdir("/tmp/restore_area") unless File.exist?("/tmp/restore_area")
    Restore.restore_with_cli_args ["--no-db", "--sudo", "echo", "--restore-prefix", "/tmp/restore_area", "/tmp/testing_backup.tar.gz"]

    new_perms = check_files.inject({}) { |h, file| h[file] = File.stat("/tmp/restore_area" + file); h }

    FileUtils.rm_rf("/tmp/testing_backup.tar.gz")
    FileUtils.rm_rf("/tmp/testing_backup")

    running_as_root = (`whoami`.chomp == "root")

    unless running_as_root
      puts "NOT RUNNING AS ROOT: not checking that GIDs match after copy. Run test w/ sudo to check GIDs."
    end

    check_files.each do |filename|
      assert_equal old_perms[filename].uid, new_perms[filename].uid, "UIDs for #{filename} do not match!"
      assert_equal(old_perms[filename].gid, new_perms[filename].gid, "GIDs for #{filename} do not match!") if running_as_root
    end

  end
end
