#!/opt/sensu/embedded/bin/ruby
#
# MySQL Replication Status (modded from disk)
# ===
#
# Copyright 2011 Sonian, Inc <chefs@sonian.net>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require "sensu-plugin/check/cli"
require "mysql2"
require "inifile"

class CheckMysqlReplicationStatus < Sensu::Plugin::Check::CLI

  option :host,
    short: "-h",
    long: "--host=VALUE",
    description: "Database host"

  option :warn,
    short: "-w",
    long: "--warning=VALUE",
    description: "Warning threshold for replication lag",
    default: 900,
    proc: lambda { |s| s.to_i }

  option :crit,
    short: "-c",
    long: "--critical=VALUE",
    description: "Critical threshold for replication lag",
    default: 1800,
    proc: lambda { |s| s.to_i }

  option :ini,
    description: "My.cnf ini file",
    short: "-i",
    long: "--ini VALUE"

  option :help,
    short: "-h",
    long: "--help",
    description: "Check MySQL replication status",
    on: :tail,
    boolean: true,
    show_options: true,
    exit: 0

  def run
    db_host = config[:host] || "0.0.0.0"

    if config[:ini].nil?
      unknown "Must specify ini file"
    end

    begin
      ini = IniFile.load(config[:ini])
      section = ini["client"]
      db_user = section["user"]
      db_pass = section["password"]

      db = Mysql2::Client.new(host: db_host, username: db_user, password: db_pass)
      results = db.query("show slave status", as: :hash)

      unless results.nil?
        results.each do |row|
          warn "couldn't detect replication status" unless
            ["Slave_IO_State",
              "Slave_IO_Running",
              "Slave_SQL_Running",
              "Last_IO_Error",
              "Last_SQL_Error",
              "Seconds_Behind_Master"].all? do |key|
                row.has_key? key
              end

          slave_running = %w[Slave_IO_Running Slave_SQL_Running].all? do |key|
            row[key] =~ /Yes/
          end

          output = "Slave not running!"
          output += " STATES:"
          output += " Slave_IO_Running=#{row["Slave_IO_Running"]}"
          output += ", Slave_SQL_Running=#{row["Slave_SQL_Running"]}"
          output += ", LAST ERROR: #{row["Last_SQL_Error"]}"

          critical output unless slave_running

          replication_delay = row["Seconds_Behind_Master"].to_i

          message = "replication delayed by #{replication_delay}"

          if replication_delay > config[:warn] &&
              replication_delay <= config[:crit]
            warning message
          elsif replication_delay >= config[:crit]
            critical message
          else
            ok "slave running: #{slave_running}, #{message}"
          end

        end
        ok "show slave status was nil. This server is not a slave."
      end
    rescue Mysql2::Error => e
      errstr = "Error code: #{e.errno} Error message: #{e.error}"
      critical "#{errstr} SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
    rescue => e
      critical e
    ensure
      db.close if db
    end
  end

end
