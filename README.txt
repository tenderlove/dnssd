= dnssd

* http://rubyforge.org/projects/dnssd
* http://github.com/tenderlove/dnssd

== DESCRIPTION:

DNS Service Discovery (aka Bonjour, MDNS) API for Ruby.  Implements browsing,
resolving, registration and domain enumeration.

== FEATURES/PROBLEMS:

* Needs more pie.
* Not all of the DNSSD API is implemented
* Sometimes tests fail

== SYNOPSIS:

See the sample directory (Hint: gem contents --prefix dnssd)

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
* The dns-sd library on other operating systems (or dns-sd shim)

== INSTALL:

  sudo gem install dnssd

== LICENSE:

Copyright (c) 2004 Chad Fowler, Charles Mills, Rich Kilmer
Copyright (c) 2009 Phil Hagelberg, Aaron Patterson, Eric Hodel

Licensed under the ruby license

