require 'open3'

module LandscapeTurner
  module Helpers
    def safe_system(cmd)
      e = system(cmd)
      raise "Failure in command: #{cmd.inspect}!" unless e
    end
    def get_landscape_databases()
      landscape_databases = Array.new()
      list = Open3.capture3("cd /tmp && sudo -u postgres psql -qlA")[0].split("\n")
      #This is to remove irrelevant information generated from this command at the first and last line.
      list.shift()
      list.pop()
      landscape_list = Array.new()
      list.each { |item|
      db_name = item.split("|")[0]
      if db_name.start_with?("landscape")
        landscape_list.push(db_name)
      end
      }
      return landscape_list
     end
  end
end
