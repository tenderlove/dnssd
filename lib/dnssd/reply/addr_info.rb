##
# Created by DNSSD::Service#get_addr_info

class DNSSD::Reply::AddrInfo < DNSSD::Reply

  attr_reader :address
  attr_reader :hostname
  attr_reader :port
  attr_reader :ttl

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

