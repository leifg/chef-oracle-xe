maintainer       'Leif Gensert'
maintainer_email 'leif@propertybase.com'
license          'MIT'
description      'installs Oracle-XE version for Ubuntu'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.0.9'

%w{ubuntu debian}.each do |os|
  supports os
end