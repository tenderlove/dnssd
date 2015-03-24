require 'thread'

##
# A DNSSD::Service may be used for one DNS-SD call at a time.  The service is
# automatically stopped after calling.  A single service can not be reused
# multiple times.
#
# DNSSD::Service provides the raw DNS-SD functions via the +_+ variants.

class DNSSD::Service
  include Enumerable

  # :stopdoc:
  IPv4 = 1 unless const_defined? :IPv4
  IPv6 = 2 unless const_defined? :IPv6
  # :startdoc:

  class << self; private :new; end

  ##
  # Creates a new DNSSD::Service

  def initialize
    @replies  = []
    @continue = true
    @thread   = nil
    @lock     = Mutex.new
  end

  class Register < ::DNSSD::Service
    def initialize
      super
      @records = []
    end

    ##
    # Adds an extra DNS record of +type+ containing +data+.  +ttl+ is in
    # seconds, use 0 for the default value.  +flags+ are currently ignored.
    #
    # Must be called on a service only after #register.
    #
    # Returns the added DNSSD::Record

    def add_record type, data, ttl = 0, flags = 0
      @records << _add_record(flags.to_i, type, data, ttl)
    end
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

  def self.browse type, domain = nil, flags = 0, interface = DNSSD::InterfaceAny
    check_domain domain
    interface = DNSSD.interface_index interface unless Integer === interface

    _browse flags.to_i, interface, type, domain
  end

  def each timeout = :never
    raise DNSSD::Error, 'already stopped' unless @continue

    return enum_for __method__, timeout unless block_given?

    io = IO.new ref_sock_fd
    rd = [io]

    start_at = clock_time

    while @continue
      break unless timeout == :never || clock_time - start_at < timeout

      if IO.select rd, nil, nil, 1
        begin
          process_result
        rescue DNSSD::UnknownError
        end
        @replies.each { |r| yield r }
        @replies.clear
      end
    end
  end

  def async_each timeout = :never
    @lock.synchronize do
      raise DNSSD::Error, 'already stopped' unless @continue
      @thread = Thread.new { each(timeout) { |r| yield r } }
    end
  end

  def push record
    @replies << record
  end

  ##
  # Raises an ArgumentError if +domain+ is too long including NULL terminator
  # and trailing '.'

  def self.check_domain(domain)
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
  #   service = DNSSD::Service.enumerate_domains
  #
  #   service.each do |r|
  #     p r.domain
  #     break unless r.flags.more_coming?
  #   end

  def self.enumerate_domains(flags = DNSSD::Flags::BrowseDomains,
                        interface = DNSSD::InterfaceAny, &block)
    interface = DNSSD.interface_index interface unless Integer === interface

    _enumerate_domains flags.to_i, interface
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

  def self.getaddrinfo(host, protocol = 0, flags = 0,
                  interface = DNSSD::InterfaceAny, &block)
    interface = DNSSD.interface_index interface unless Integer === interface

    if respond_to? :_getaddrinfo, true then
      _getaddrinfo flags.to_i, interface, protocol, host
    else
      family = case protocol
               when IPv4 then Socket::AF_INET
               when IPv6 then Socket::AF_INET6
               else protocol
               end

      addrinfo = Socket.getaddrinfo host, nil, family

      list = addrinfo.map do |_, _, a_host, ip, _|
        sockaddr = Socket.pack_sockaddr_in 0, ip
        DNSSD::Reply::AddrInfo.new(self, 0, 0, a_host, sockaddr, 0)
      end
      def list.stop; end
      list
    end
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

  def self.query_record(fullname, record_type, record_class = DNSSD::Record::IN,
                   flags = 0, interface = DNSSD::InterfaceAny)
    interface = DNSSD.interface_index interface unless Integer === interface

    _query_record flags.to_i, interface, fullname, record_type, record_class
  end

  ##
  # Register a service.  A DNSSD::Reply object is passed to the optional block
  # when the registration completes.
  #
  #   service.register "My Files", "_http._tcp", nil, 8080 do |r|
  #     puts "successfully registered: #{r.inspect}"
  #   end

  def self.register(name, type, domain, port, host = nil, text_record = nil,
               flags = 0, interface = DNSSD::InterfaceAny)
    check_domain domain
    interface = DNSSD.interface_index interface unless Integer === interface
    text_record = text_record.encode if text_record

    _register flags.to_i, interface, name, type, domain, host, port, text_record
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

  def self.resolve(name, type = name.type, domain = name.domain, flags = 0,
              interface = DNSSD::InterfaceAny)
    name = name.name if DNSSD::Reply === name
    check_domain domain
    interface = DNSSD.interface_index interface unless Integer === interface

    _resolve flags.to_i, interface, name, type, domain
  end

  ##
  # Returns true if the service has been started.

  def started?
    @continue
  end

  def stop
    raise DNSSD::Error, 'service is already stopped' unless started?
    @continue = false
    @thread.join if @thread
    _stop
    self
  end

  private

  if defined? Process::CLOCK_MONOTONIC
    def clock_time
      Process.clock_gettime Process::CLOCK_MONOTONIC
    end
  else
    def clock_time
      Time.now
    end
  end
end
