##
# Created by DNSSD::Service#getaddrinfo

class DNSSD::Reply::AddrInfo < DNSSD::Reply

  ##
  # IP address of host

  attr_reader :address

  ##
  # Host name

  attr_reader :hostname

  ##
  # Port name

  attr_reader :port

  ##
  # Time to live see #expired?

  attr_reader :ttl

  ##
  # Creates a new AddrInfo, called internally by DNSSD::Service#getaddrinfo

  def initialize(service, flags, interface, hostname, sockaddr, ttl)
    super service, flags, interface

    @hostname = hostname
    @port, @address = Socket.unpack_sockaddr_in sockaddr

    @created = Time.now
    @ttl = ttl
  end

  ##
  # Has this AddrInfo passed its TTL?

  def expired?
    Time.now > @created + ttl
  end

end

