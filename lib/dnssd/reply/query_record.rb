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

  def inspect # :nodoc:
    "#<%s:0x%x %s %s %s %p interface: %s flags: %p>" % [
      self.class, object_id,
      fullname, record_class_name, record_type_name, record,
      interface_name, @flags
    ]
  end

  ##
  # Name of this record's record_class

  def record_class_name
    'IN' # Only IN is supported
  end

  ##
  # Name of this record's record_type

  def record_type_name
    DNSSD::Record::VALUE_TO_NAME[@record_type]
  end

  ##
  # Outputs this record in a BIND-like DNS format

  def to_s
    "%s %s %s %p" % [fullname, record_class_name, record_type_name, @record]
  end

end

