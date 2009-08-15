##
# Created by DNSSD::Service#query_record

class DNSSD::Reply::QueryRecord < DNSSD::Reply

  ##
  # A domain for registration or browsing

  attr_reader :domain

  ##
  # The service name

  attr_reader :name

  attr_reader :record
  attr_reader :record_class
  attr_reader :record_type
  attr_reader :ttl

  ##
  # The service type

  attr_reader :type

  def initialize(service, flags, interface, fullname, record_type,
                 record_class, record, ttl)
    super service, flags, interface

    set_fullname fullname

    @record_type = record_type
    @record_class = record_class
    @record = record

    @created = Time.now
    @ttl = ttl
  end

  ##
  # Has this QueryRecord passed its TTL?

  def expired?
    Time.now > @created + ttl
  end
end

