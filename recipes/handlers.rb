cnf = data_bag_item("sensu", "handlers")

%w(sysopia ponymailer zoomailer).each do |h|

  log "Handler: #{h}"

  cookbook_file "/etc/sensu/handlers/#{h}.rb" do
    source "handlers/#{h}.rb"
    mode 0755
  end

  sensu_snippet h do
    content cnf[h]
  end

  sensu_handler h do
    type "pipe"
    command "#{h}.rb"
  end
end
