#!/opt/sensu/embedded/bin/ruby
# GNA production specific: script checks if all expected containers
# are running on a node

require "sensu-plugin/check/cli"

class CheckDockerContainers < Sensu::Plugin::Check::CLI
  EXPECTED_CONTAINERS="/opt/gna/shared/containers"

  def run
    running = `/usr/local/bin/docker_names`.strip.split.sort
    expected = File.read(EXPECTED_CONTAINERS).strip.split("\n")
    missing = (expected - running).join(", ")
    msg = "Container #{missing} is not running!"
    msg = "Containers #{missing} are not running!" if missing.index(",")
    critical msg unless missing.empty?
    ok "All expected containers are running"
  rescue Errno::ENOENT
    unknown "Cannot open file #{EXPECTED_CONTAINERS}"
  rescue => e
    unknown e
  end
end

