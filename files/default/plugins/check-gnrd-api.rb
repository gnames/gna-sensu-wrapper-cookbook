#!/opt/sensu/embedded/bin/ruby

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'
require 'net/http'
require 'net/https'
require 'json'

class CheckHTTP < Sensu::Plugin::Check::CLI

  option :url,
    :short => '-u URL',
    :long => '--url URL',
    :description => 'A URL to connect to'

  option :timeout,
    :short => '-t SECS',
    :long => '--timeout SECS',
    :proc => proc { |a| a.to_i },
    :description => 'Set the timeout',
    :default => 15

  def run
    uri = nil
    if config[:url]
      uri = URI(config[:url])
    else
      unless config[:host] and config[:path]
        unknown 'No URL specified'
      end
    end

    begin
      timeout(config[:timeout]) do
        get_resource(uri)
      end
    rescue Timeout::Error
      critical "Request timed out"
    rescue => e
      critical "Request error: #{e.message}"
    end
  end

  def request(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(uri)
    http.request(req)
  end

  def get_resource(uri)
    res = request(uri)
    case res
    when Net::HTTPRedirection
      check_names(10, URI(res['location'])) 
    else 
      critical res.code
    end
  end

  def check_names(count, uri)
    sleep 1
    data = JSON.parse(request(uri).body, symbolize_names: true)
    exit if data[:names] && !data[:names].empty?
    warning "Slow response. Queue is too full?" if count == 0
    check_names(count - 1, uri)
  end
end
