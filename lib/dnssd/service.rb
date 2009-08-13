require 'thread'

##
# A DNSSD::Service may be used for one DNS-SD call at a time.  Between calls
# the service must be stopped.  A single service can be reused multiple times.
#
# DNSSD::Service provides the raw DNS-SD functions via the _ variants.

class DNSSD::Service

  ##
  # Creates a new DNSSD::Service

  def initialize
    @replies = []
    @continue = true
    @thread = nil
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

    _browse type, domain, flags.to_i, interface

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
  #   timeout(2) do
  #     DNSSD.enumerate_domains! do |r|
  #       available_domains << r.domain
  #     end
  #   rescue TimeoutError
  #   end
  #   
  #   p available_domains

  def enumerate_domains(flags = DNSSD::Flags::BrowseDomains,
                        interface = DNSSD::InterfaceAny, &block)
    interface = DNSSD.interface_index interface unless Integer === interface

    raise DNSSD::Error, 'service in progress' if started?

    _enumerate_domains flags.to_i, interface

    process(&block)
  end
  
  def inspect # :nodoc:
    stopped = stopped? ? 'stopped' : 'running'
    "#<%s:0x%x %s>" % [self.class, object_id, stopped]
  end

  def process
    @thread = Thread.current

    while @continue do
      _process if @replies.empty?
      yield @replies.shift until @replies.empty?
    end

    @thread = nil

    self
  end

  ##
  # Register a service.  A DNSSD::Reply object is passed to the optional block
  # when the registration completes.
  #
  #   DNSSD.register! "My Files", "_http._tcp", nil, 8080 do |r|
  #     puts "successfully registered: #{r.inspect}"
  #   end

  def register(name, type, domain, port, host = nil, text_record = nil,
               flags = 0, interface = DNSSD::InterfaceAny, &block)
    check_domain domain
    interface = DNSSD.interface_index interface unless Integer === interface

    raise DNSSD::Error, 'service in progress' if started?

    _register name, type, domain, host, port, text_record, flags.to_i, interface

    block = proc { } unless block

    process(&block)
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
  # The returned service can be used to control when to stop resolving the
  # service (see DNSSD::Service#stop).
  #
  #   s = DNSSD.resolve "foo bar", "_http._tcp", "local" do |r|
  #     p r
  #   end
  #   sleep 2
  #   s.stop

  def resolve(name, type = name.type, domain = name.domain, flags = 0,
              interface = DNSSD::InterfaceAny, &block)
    name = name.name if DNSSD::Reply === name
    check_domain domain
    interface = DNSSD.interface_index interface unless Integer === interface

    raise DNSSD::Error, 'service in progress' if started?

    _resolve name, type, domain, flags.to_i, interface

    process(&block)
  end

end

