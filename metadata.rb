name             "eol-sensu-wrapper"
maintainer       "Dmitry Mozzherin"
maintainer_email "dmozzherin@gmail.com"
license          "MIT"
description      "Installs/Configures eol-sensu-wrapper"
long_description IO.read(File.join(File.dirname(__FILE__), "README.md"))
version          "0.1.4"

depends "sensu", "2.6.0"
depends "uchiwa", "1.0.0"
depends "postfix", "3.6.2"

%w(debian ubuntu centos redhat).each do |os|
  supports os
end
