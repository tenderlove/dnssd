require 'thread'

##
# A DNSSD::Service may be used for one DNS-SD call at a time.  The service is
# automatically stopped after calling.  A single service can not be reused
# multiple times.
#
# DNSSD::Service provides the raw DNS-SD functions via the +_+ variants.

class DNSSD::Service

  # :stopdoc:
  IPv4 = 1 unless const_defined? :IPv4
  IPv6 = 2 unless const_defined? :IPv6
  # :startdoc:

  ##
  # Creates a new DNSSD::Service

  def initialize
    @replies = []
    @continue = true
    @thread = nil
    @type = nil
  end

  ##
  # Adds an extra DNS record of +type+ containing +data+.  +ttl+ is in
  # seconds, use 0 for the default value.  +flags+ are currently ignored.  
  #
  # Must be called on a service only after #register.
  #
  # Returns the added DNSSD::Record

  def add_record(type, data, ttl = 0, flags = 0)
    raise TypeError, 'must be called after register' unless @type == :register
    @records ||= []

    _add_record flags.to_i, type, data, ttl
  end

  ##
  # Browse for services.
  #
  # For each service found a DNSSD::Reply object is yielded.
  #
  #   service = DNSSD::Service.new
  #   timeout 6 do
  #     service.browse '_http._tcp' do |r|
  #       puts "Found HTTP service: #{r.name}"
  #     end
  #   rescue Timeout::Error
  #   end

  def browse(type, domain = nil, flags = 0, interface = DNSSD::InterfaceAny,
             &block)
    check_domain domain
    interface = DNSSD.interface_index interface unless Integer === interface

    raise DNSSD::Error, 'service in progress' if started?

    @type = :browse

    _browse flags.to_i, interface, type, domain

    process(&block)
  end

  ##
  # Raises an ArgumentError if +domain+ is too long including NULL terminator
  # and trailing '.'

  def check_domain(domain)
    return unless domain
    raise ArgumentError, 'domain name string is too long' if
      domain.length >= MAX_DOMAIN_NAME - 1
  end

  ##
  # Enumerate domains available for browsing and registration.
  #
  # For each domain found a DNSSD::Reply object is passed to block with
  # #domain set to the enumerated domain.
  #
  #   available_domains = []
  #   
  #   service.enumerate_domains! do |r|
  #     available_domains << r.domain
  #     break unless r.flags.more_coming?
  #   end
  #   
  #   p available_domains

  def enumerate_domains(flags = DNSSD::Flags::BrowseDomains,
                        interface = DNSSD::InterfaceAny, &block)
    interface = DNSSD.interface_index interface unless Integer === interface

    raise DNSSD::Error, 'service in progress' if started?

    _enumerate_domains flags.to_i, interface

    @type = :enumerate_domains

    process(&block)
  end

  ##
  # Retrieve address information for +host+ on +protocol+
  #
  #   addresses = []
  #   service.getaddrinfo reply.target do |addrinfo|
  #     addresses << addrinfo.address
  #     break unless addrinfo.flags.more_coming?
  #   end
  #
  # When using DNSSD on top of the Avahi compatibilty shim you'll need to
  # setup your /etc/nsswitch.conf correctly.  See
  # http://avahi.org/wiki/AvahiAndUnicastDotLocal for details

  def getaddrinfo(host, protocol = 0, flags = 0,
                  interface = DNSSD::InterfaceAny, &block)
    interface = DNSSD.interface_index interface unless Integer === interface

    if respond_to? :_getaddrinfo then
      raise DNSSD::Error, 'service in progress' if started?

      _getaddrinfo flags.to_i, interface, protocol, host

      @type = :getaddrinfo

      process(&block)
    else
      family = case protocol
               when IPv4 then Socket::AF_INET
               when IPv6 then Socket::AF_INET6
               else protocol
               end

      addrinfo = Socket.getaddrinfo host, nil, family

      addrinfo.each do |_, _, a_host, ip, _|
        sockaddr = Socket.pack_sockaddr_in 0, ip
        @replies << DNSSD::Reply::AddrInfo.new(self, 0, 0, a_host, sockaddr, 0)
      end
    end
  end

  def inspect # :nodoc:
    stopped = stopped? ? 'stopped' : 'running'
    "#<%s:0x%x %s>" % [self.class, object_id, stopped]
  end

  ##
  # Yields results from the mDNS daemon, blocking until data is available.
  # Use break or return when you wish to stop receiving results.
  #
  # The service is automatically stopped after calling this method.

  def process # :yields: DNSSD::Result
    @thread = Thread.current

    while @continue do
      _process if @replies.empty?
      yield @replies.shift until @replies.empty?
    end

    @thread = nil

    self
  rescue DNSSD::ServiceNotRunningError
    # raised when we jump out of DNSServiceProcess() while it's waiting for a
    # response
    self
  ensure
    stop unless stopped?
  end

  ##
  # Retrieves an arbitrary DNS record
  #
  # +fullname+ is the full name of the resource record.  +record_type+ is the
  # type of the resource record (see DNSSD::Resource).
  #
  # +flags+ may be either DNSSD::Flags::ForceMulticast or
  # DNSSD::Flags::LongLivedQuery
  #
  #   service.query_record "hostname._afpovertcp._tcp.local",
  #                        DNSService::Record::SRV do |record|
  #     p record
  #   end

  def query_record(fullname, record_type, record_class = DNSSD::Record::IN,
                   flags = 0, interface = DNSSD::InterfaceAny, &block)
    interface = DNSSD.interface_index interface unless Integer === interface

    raise DNSSD::Error, 'service in progress' if started?

    _query_record flags.to_i, interface, fullname, record_type, record_class

    @type = :query_record

    process(&block)
  end

  ##
  # Register a service.  A DNSSD::Reply object is passed to the optional block
  # when the registration completes.
  #
  #   service.register "My Files", "_http._tcp", nil, 8080 do |r|
  #     puts "successfully registered: #{r.inspect}"
  #   end

  def register(name, type, domain, port, host = nil, text_record = nil,
               flags = 0, interface = DNSSD::InterfaceAny, &block)
    check_domain domain
    interface = DNSSD.interface_index interface unless Integer === interface
    text_record = text_record.encode if text_record

    raise DNSSD::Error, 'service in progress' if started?

    _register flags.to_i, interface, name, type, domain, host, port,
              text_record, &block

    @type = :register

    process(&block) if block
  end

  ##
  # Resolve a service discovered via #browse.
  #
  # +name+ may be either the name of the service found or a DNSSD::Reply from
  # DNSSD::Service#browse.  When +name+ is a DNSSD::Reply, +type+ and +domain+
  # are automatically filled in, otherwise the service type and domain must be
  # supplied.
  #
  # The service is resolved to a target host name, port number, and text
  # record, all contained in the DNSSD::Reply object passed to the required
  # block.
  #
  #   service.resolve "foo bar", "_http._tcp", "local" do |r|
  #     p r
  #   end

  def resolve(name, type = name.type, domain = name.domain, flags = 0,
              interface = DNSSD::InterfaceAny, &block)
    name = name.name if DNSSD::Reply === name
    check_domain domain
    interface = DNSSD.interface_index interface unless Integer === interface

    raise DNSSD::Error, 'service in progress' if started?

    _resolve flags.to_i, interface, name, type, domain

    @type = :resolve

    process(&block)
  end

  ##
  # Returns true if the service has been started.

  def started?
    not stopped?
  end

end

