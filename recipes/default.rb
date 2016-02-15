cnf = data_bag_item("sensu", "config")
master_address = cnf["master_address"] || node["ipaddress"]
additional_attributes = cnf["additional"] || {}

if cnf[node.name] && cnf[node.name]["roles"]
  node.override["gna_sensu_wrapper"]["roles"] = cnf[node.name]["roles"]
end

node.override["sensu"]["rabbitmq"]["host"] = master_address
node.override["sensu"]["redis"]["host"] = master_address
node.override["sensu"]["api"]["host"] = master_address

if cnf["uchiwa_user"]
  node.override["uchiwa"]["settings"]["user"] = cnf["uchiwa_user"]
end

if cnf["uchiwa_password"]
  node.override["uchiwa"]["settings"]["pass"] =
    cnf["uchiwa_password"]
end

if cnf["uchiwa_port"]
  node.override["uchiwa"]["settings"]["port"] = cnf["uchiwa_port"]
end

umask = File.umask
File.umask(0022)

package "sysstat"

sensu_gem "sensu-plugin" do
  version node["gna_sensu_wrapper"]["sensu_plugin_version"]
end

unless (node["gna_sensu_wrapper"]["roles"] & %w(mysql sensu)).empty?
  sensu_gem "mysql2"
  sensu_gem "inifile"
end

include_recipe "sensu::default"

if node["ipaddress"] == master_address
  sensu_gem "pony"
  sensu_gem "hipchat"

  include_recipe "sensu::rabbitmq"
  include_recipe "sensu::redis"
  include_recipe "postfix"

  sensu_checks = data_bag("sensu_checks").map do |item|
    data_bag_item("sensu_checks", item)
  end

  sensu_checks.each do |check|
    sensu_check check["id"] do
      type check["type"]
      command check["command"]
      subscribers check["subscribers"]
      interval check["interval"]
      handlers check["handlers"]
      additional check["additional"]
    end
  end

  include_recipe "sensu::server_service"
  include_recipe "sensu::api_service"
  include_recipe "uchiwa"
end

sensu_client node.name do
  address node["ipaddress"]
  subscriptions node["gna_sensu_wrapper"]["roles"] + ["all"]
  additional(additional_attributes)
end

remote_directory "/etc/sensu/plugins" do
  source "plugins"
  files_mode "0750"
  files_owner "root"
  files_group "sensu"
  owner "root"
  group "sensu"
end

log "Adding Handlers"

include_recipe "gna-sensu-wrapper::handlers"

include_recipe "sensu::client_service"

File.umask(umask)
