#!/opt/sensu/embedded/bin/ruby

require "sensu-handler"
require "hipchat"
require "openssl"

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class HipChatNotif < Sensu::Handler

  def event_name
    @event["client"]["name"] + "/" + @event["check"]["name"]
  end

  def handle
    hipchatmsg = HipChat::Client.new(settings["hipchat"]["apikey"])
    message = @event["check"]["notification"] || @event["check"]["output"]

    if @event["action"].eql?("resolve")
      hipchatmsg[settings["hipchat"]["room"]].send("Sensu", "RESOLVED - [#{event_name}] - #{message}.", :color => "green")
    else
      hipchatmsg[settings["hipchat"]["room"]].send("Sensu", "ALERT - [#{event_name}] - #{message}.", :color => "red", :notify => true)
    end
  end

end
