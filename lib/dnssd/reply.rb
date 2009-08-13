##
# DNSSD::Reply is used to return information

class DNSSD::Reply

  ##
  # The service domain

  attr_reader :domain

  ##
  # Flags describing the reply, see DNSSD::Flags

  attr_reader :flags

  ##
  # The interface on which the service is available

  attr_reader :interface

  ##
  # The service name

  attr_reader :name

  ##
  # The port for this service

  attr_reader :port

  ##
  # The DNSSD::Service associated with the reply

  attr_reader :service

  ##
  # The hostname of the host provide the service

  attr_reader :target

  ##
  # The service's primary text record

  attr_reader :text_record

  ##
  # The service type

  attr_reader :type

  ##
  # Creates a DNSSD::Reply from +service+ and +flags+

  def self.from_service(service, flags)
    reply = new
    reply.instance_variable_set :@service, service
    reply.instance_variable_set :@flags, DNSSD::Flags.new(flags)
    reply
  end

  ##
  # Connects to this Reply.  If #target and #port are missing, DNSSD.resolve
  # is automatically called.
  #
  # +family+ can be used to select a particular address family (IPv6 vs IPv4).
  #
  # +addrinfo_flags+ are passed to DNSSD::Service#getaddrinfo as flags.

  def connect(family = Socket::AF_UNSPEC, addrinfo_flags = 0)
    unless target and port then
      value = nil

      DNSSD.resolve! self do |reply|
        value = reply
        break
      end

      return value.connect(family, addrinfo_flags)
    end

    addrinfo_protocol = case family
                        when Socket::AF_INET then DNSSD::Service::IPv4
                        when Socket::AF_INET6 then DNSSD::Service::IPv6
                        when Socket::AF_UNSPEC then 0
                        else raise ArgumentError, "invalid family #{family}"
                        end

    addresses = []

    service = DNSSD::Service.new

    begin
      service.getaddrinfo target, addrinfo_protocol, addrinfo_flags,
                          interface do |addrinfo|
        address = addrinfo.address.last

        begin
          socket = nil

          case protocol
          when 'tcp' then
            socket = TCPSocket.new address, port
          when 'udp' then
            socket = UDPSocket.new
            socket.connect address, port rescue next
          end

          return socket
        rescue
          next if addrinfo.flags.more_coming?
          raise
        end
      end
    ensure
      service.stop
    end
  end

  ##
  # The full service domain name, see DNSS::Service#fullname

  def fullname
    DNSSD::Service.fullname @name.gsub("\032", ' '), @type, @domain
  end

  def inspect # :nodoc:
    "#<%s:0x%x %p type: %s domain: %s interface: %s flags: %s>" % [
      self.class, object_id, @name, @type, @domain, @interface, @flags
    ]
  end

  ##
  # Protocol of this service

  def protocol
    type.split('.').last.sub '_', ''
  end

  ##
  # Service name as in Socket.getservbyname

  def service_name
    type.split('.').first.sub '_', ''
  end

  ##
  # Sets #name, #type and #domain from +fullname+

  def set_fullname(fullname)
    fullname = fullname.gsub(/\\([0-9]+)/) do $1.to_i.chr end
    fullname = fullname.scan(/(?:[^\\.]|\\\.)+/).map do |part|
      part.gsub "\\.", '.'
    end

    @name   = fullname[0]
    @type   = fullname[1,   2].join '.'
    @domain = fullname[3..-1].map { |part| part.sub '.', '\\.' }.join('.') + '.'
  end

  ##
  # Sets #name, #type and #domain

  def set_names(name, type, domain)
    set_fullname [name, type, domain].join('.')
  end

end

