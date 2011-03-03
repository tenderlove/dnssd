##
# Created by DNSSD::Service#resolve

class DNSSD::Reply::Resolve < DNSSD::Reply

  ##
  # A domain for registration or browsing

  attr_reader :domain

  ##
  # The service name

  attr_reader :name

  ##
  # The port for this service

  attr_reader :port

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
  # Creates a new Resolve, called internally by DNSSD::Service#resolve

  def initialize(service, flags, interface, fullname, target, port,
                 text_record)
    super service, flags, interface

    set_fullname fullname

    @target = target
    @port = port
    @text_record = DNSSD::TextRecord.new text_record
  end

  ##
  # Connects to this Reply.  If #target and #port are missing, DNSSD.resolve
  # is automatically called.
  #
  # +family+ can be used to select a particular address family (IPv6 vs IPv4).
  #
  # +addrinfo_flags+ are passed to DNSSD::Service#getaddrinfo as flags.

  def connect(family = Socket::AF_UNSPEC, addrinfo_flags = 0)
    addrinfo_protocol = case family
                        when Socket::AF_INET   then DNSSD::Service::IPv4
                        when Socket::AF_INET6  then DNSSD::Service::IPv6
                        when Socket::AF_UNSPEC then 0
                        else raise ArgumentError, "invalid family #{family}"
                        end

    service = DNSSD::Service.new

    service.getaddrinfo target, addrinfo_protocol, addrinfo_flags,
                        @interface do |addrinfo|
      address = addrinfo.address

      begin
        socket = nil

        case protocol
        when 'tcp' then
          socket = TCPSocket.new address, port
        when 'udp' then
          socket = UDPSocket.new
          socket.connect address, port
        end

        return socket
      rescue
        next if addrinfo.flags.more_coming?
        raise
      end
    end
  end

  def inspect # :nodoc:
    "#<%s:0x%x %s at %s:%d text_record: %p interface: %s flags: %p>" % [
      self.class, object_id,
      fullname, @target, @port, @text_record, interface_name, @flags
    ]
  end

end

