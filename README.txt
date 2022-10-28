= dnssd

home :: https://github.com/tenderlove/dnssd
bugs :: https://github.com/tenderlove/dnssd/issues

* https://developer.apple.com/library/archive/documentation/Networking/Conceptual/dns_discovery_api/Introduction.html

== DESCRIPTION:

DNS Service Discovery (aka Bonjour, MDNS) API for Ruby.  Implements browsing,
resolving, registration and domain enumeration.  Supports avahi's DNSSD
compatibility layer for avahi 0.6.25 or newer.

== FEATURES/PROBLEMS:

* Needs more pie.
* Not all of the DNSSD API is implemented
* Sometimes tests fail

== SYNOPSIS:

See the sample directory (Hint: <tt>gem contents --prefix dnssd</tt>)

Registering a service:

  http = TCPServer.new nil, 80
  
  DNSSD.announce http, 'my awesome HTTP server'

Browsing services:

  require 'dnssd'
  
  DNSSD.browse '_http._tcp.' do |reply|
    p reply
  end

== REQUIREMENTS:

* OS X
* The dns-sd library on other operating systems
* avahi 0.6.25+ (plus libavahi-compat-libdnssd-dev on debian)

== INSTALL:

  sudo gem install dnssd

If you have dnssd installed in a non-standard location you can use the build
options --with-dnssd-dir and --with-dnssd-lib:

  sudo gem install dnssd -- \
    --with-dnssd-dir=/path/to/dnssd \
    --with-dnssd-lib=/path/to/lib/dnssd

Using the default Bonjour SDK install for Windows, the command to build
the Ruby dnssd extension will look like this:

  # Windows 2000 or Windows XP
  sudo gem install dnssd -- \
     --with-dnssd-dir=c:/progra~1/bonjou~1 \
     --with-dnssd-lib=c:/progra~1/bonjou~1/lib/win32
  
  # Windows Vista and later
  sudo gem install dnssd -- \
     --with-dnssd-dir=c:/progra~2/bonjou~1 \
     --with-dnssd-lib=c:/progra~2/bonjou~1/lib/win32

== LICENSE:

Copyright (c) 2004 Chad Fowler, Charles Mills, Rich Kilmer

Copyright (c) 2009 Phil Hagelberg, Aaron Patterson, Eric Hodel

Licensed under the ruby license

