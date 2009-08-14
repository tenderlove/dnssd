##
# An AddrInfo struct with hostname, address, ttl, interface and flags.
#
# See DNSSD::Service#getaddrinfo

class DNSSD::AddrInfo < Struct.new :hostname, :address, :ttl, :interface, :flags

  def initialize(*args) # :nodoc:
    @created = Time.now
    super
  end

  ##
  # Has this AddrInfo passed its TTL?

  def expired?
    Time.now > @created + ttl
  end

end
