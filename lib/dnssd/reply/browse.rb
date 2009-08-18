##
# Returned by DNSSD::Service#browse

class DNSSD::Reply::Browse < DNSSD::Reply

  ##
  # A domain for registration or browsing

  attr_reader :domain

  ##
  # The service name

  attr_reader :name

  ##
  # The service type

  attr_reader :type

  ##
  # Creates a new Browse, called internally by DNSSD::Service#browse

  def initialize(service, flags, interface, name, type, domain)
    super service, flags, interface

    set_names name, type, domain
  end

  ##
  # Resolves this service's target using DNSSD::Reply::Resolve#connect which
  # connects, returning a TCP or UDP socket.

  def connect(family = Socket::AF_UNSPEC, addrinfo_flags = 0)
    value = nil

    DNSSD.resolve! self do |reply|
      value = reply
      break
    end

    value.connect family, addrinfo_flags
  end

  def inspect # :nodoc:
    "#<%s:0x%x %p interface: %s flags: %p>" % [
      self.class, object_id, fullname, interface_name, @flags
    ]
  end

end

