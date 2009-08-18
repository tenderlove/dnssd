##
# Returned by DNSSD::Service#register

class DNSSD::Reply::Register < DNSSD::Reply

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
  # Creates a Register, called internally by DNSSD::Service#register

  def initialize(service, flags, name, type, domain)
    super service, flags, nil

    set_names name, type, domain
  end

  def inspect # :nodoc:
    "#<%s:0x%x %p flags: %p>" % [
      self.class, object_id, fullname, @flags
    ]
  end

end

