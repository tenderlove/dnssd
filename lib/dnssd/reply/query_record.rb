require 'ipaddr'

##
# Created by DNSSD::Service#query_record

class DNSSD::Reply::QueryRecord < DNSSD::Reply

  ##
  # A domain for registration or browsing

  attr_reader :domain

  ##
  # The service name

  attr_reader :name

  ##
  # DNS Record data

  attr_reader :record

  ##
  # DNS Record class (only IN is supported)

  attr_reader :record_class

  ##
  # DNS Record type

  attr_reader :record_type

  ##
  # Time-to-live for this record.  See #expired?

  attr_reader :ttl

  ##
  # The service type

  attr_reader :type

  ##
  # Creates a new QueryRecord, called internally by
  # DNSSD::Service#query_record

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
  # Converts a RFC 1035 character-string into a ruby String

  def character_string_to_string(character_string)
    length = character_string.slice 0
    length = length.ord unless Numeric === length
    string = character_string.slice 1, length

    if string.length != length then
      raise TypeError,
        "invalid character string, expected #{length} got #{string.length} in #{@record.inspect}"
    end

    string
  end

  ##
  # Converts a RFC 1035 domain-name into a ruby String

  def domain_name_to_string(domain_name)
    return '.' if domain_name == "\0"

    domain_name = domain_name.dup
    string = []

    until domain_name.empty? do
      string << character_string_to_string(domain_name)
      domain_name.slice! 0, string.last.length + 1
    end

    string << nil unless string.last.empty?

    string.join('.')
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
    return "unknown #{@record_class}" unless @record_class == DNSSD::Record::IN
    'IN' # Only IN is supported
  end

  ##
  # Decodes output for #record, returning the raw record if it can't be
  # decoded.  Handles:
  #
  # A AAAA CNAME MX NS PTR SOA SRV TXT

  def record_data
    return @record unless @record_class == DNSSD::Record::IN

    case @record_type
    when DNSSD::Record::A,
         DNSSD::Record::AAAA then
      IPAddr.new_ntoh @record
    when DNSSD::Record::CNAME,
         DNSSD::Record::NS,
         DNSSD::Record::PTR then
      domain_name_to_string @record
    when DNSSD::Record::MX then
      mx = @record.unpack 'nZ*'
      mx[-1] = domain_name_to_string mx.last
      mx
    when DNSSD::Record::SOA then
      soa = @record.unpack 'Z*Z*NNNNN'
      soa[0] = domain_name_to_string soa[0]
      soa[1] = domain_name_to_string soa[1]
      soa
    when DNSSD::Record::SRV then
      srv = @record.unpack 'nnnZ*'
      srv[-1] = domain_name_to_string srv.last
      srv
    when DNSSD::Record::TXT then
      record = @record.dup
      txt = []

      until record.empty? do
        txt << character_string_to_string(record)
        record.slice! 0, txt.last.length + 1
      end

      txt
    else
      @record
    end
  end

  ##
  # Name of this record's record_type

  def record_type_name
    return "unknown #{@record_type} for record class (#{@record_class})" unless
      @record_class == DNSSD::Record::IN
    DNSSD::Record::VALUE_TO_NAME[@record_type]
  end

  ##
  # Outputs this record in a BIND-like DNS format

  def to_s
    "%s %d %s %s %p" % [
      fullname, ttl, record_class_name, record_type_name, record_data
    ]
  end

end

