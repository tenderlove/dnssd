= dnssd

* http://rubyforge.org/projects/dnssd
* http://github.com/tenderlove/dnssd

== DESCRIPTION:

DNS Service Discovery (aka Bonjour, MDNS) API for Ruby.  Implements browsing,
resolving, registration and domain enumeration.

== FEATURES/PROBLEMS:

* Too much C, too little ruby

== SYNOPSIS:

Registering a service:

  registration = DNSSD.register 'my web service', '_http._tcp', nil, 80
  
  # ...
  
  registration.stop # unregister when we're done

Browsing services:

  require 'dnssd'
  
  DNSSD.browse '_http._tcp.' do |reply|
    p reply
  end

== REQUIREMENTS:

* The mdns library on OS X
* The dns-sd library on other operating systems

== INSTALL:

* FIX (sudo gem install, anything else)

== LICENSE:

Copyright (c) 2004 Chad Fowler, Charles Mills, Rich Kilmer
Copyright (c) 2009 Phil Hagelberg, Aaron Patterson, Eric Hodel

Licensed under the ruby license

