##
# Returned by DNSSD::Service#enumerate_domains

class DNSSD::Reply::Domain < DNSSD::Reply

  ##
  # A domain for registration or browsing

  attr_reader :domain

  def initialize(flags, interface, domain)
    super flags, interface

    @domain = domain
  end

end

