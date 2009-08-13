require 'dnssd/dnssd'
require 'socket'

##
# DNSSD is a wrapper for the DNS Service Discovery library.
#
# DNSSD.announce and DNSSD::Reply.connect provide an easy-to-use way to
# announce and connect to services.
#
# The methods DNSSD.enumerate_domains, DNSSD.browse, DNSSD.register, and
# DNSSD.resolve provide the basic API for making your applications DNS \Service
# Discovery aware.

module DNSSD

  ##
  # The version of DNSSD you're using.

  VERSION = '1.2'

  ##
  # Registers +socket+ with DNSSD as +name+.  If +service+ is omitted it is
  # looked up using #getservbyport and the ports address.  +text_record+,
  # +flags+ and +interface+ are used as in #register.
  #
  # Returns the Service created by registering the socket.  The Service will
  # automatically be shut down when #close or #close_read is called on the
  # socket.
  #
  # Only for bound TCP and UDP sockets.

  def self.announce(socket, name, service = nil, text_record = nil, flags = 0,
                    interface = DNSSD::InterfaceAny, &block)
    _, port, _, address = socket.addr

    raise ArgumentError, 'socket not bound' if port == 0

    service ||= DNSSD.getservbyport port

    proto = case socket
            when TCPSocket then 'tcp'
            when UDPSocket then 'udp'
            else raise ArgumentError, 'tcp or udp sockets only'
            end

    type = "_#{service}._#{proto}"

    registrar = register(name, type, nil, port, text_record, flags, interface,
                         &block)

    socket.instance_variable_set :@registrar, registrar

    def socket.close
      result = super
      @registrar.stop
      return result
    end

    def socket.close_read
      result = super
      @registrar.stop
      return result
    end

    registrar
  end

  def self.browse(type, domain = nil, flags = 0,
                  interface = DNSSD::InterfaceAny, &block)
    service = DNSSD::Service.new

    Thread.start do
      service.browse(type, domain, flags, interface, &block)
    end

    service
  end

  def self.browse!(type, domain = nil, flags = 0,
                  interface = DNSSD::InterfaceAny, &block)
    service = DNSSD::Service.new

    service.browse(type, domain, flags, interface, &block)

    service
  ensure
    service.stop unless service.stopped?
  end

  def self.enumerate_domains(flags = DNSSD::Flags::BrowseDomains,
                             interface = DNSSD::InterfaceAny, &block)
    service = DNSSD::Service.new

    Thread.start do
      service.enumerate_domains(flags, interface, &block)
    end

    service
  end

  def self.enumerate_domains!(flags = DNSSD::Flags::BrowseDomains,
                              interface = DNSSD::InterfaceAny, &block)
    service = DNSSD::Service.new

    service.enumerate_domains(flags, interface, &block)

    service
  ensure
    service.stop unless service.stopped?
  end

  def self.register(name, type, domain, port, text_record = nil, flags = 0,
                    interface = DNSSD::InterfaceAny, &block)
    service = DNSSD::Service.new

    Thread.start do
      service.register(name, type, domain, port, nil, text_record, flags,
                       interface, &block)
    end

    service
  end

  def self.register!(name, type, domain, port, text_record = nil, flags = 0,
                     interface = DNSSD::InterfaceAny, &block)
    service = DNSSD::Service.new

    block = proc { } unless block
    service.register(name, type, domain, port, nil, text_record, flags,
                     interface, &block)

    service
  ensure
    service.stop unless service.stopped?
  end

  def self.resolve(*args, &block)
    service = DNSSD::Service.new

    Thread.start do
      service.resolve(*args, &block)
    end

    service
  end

  def self.resolve!(*args, &block)
    service = DNSSD::Service.new

    service.resolve(*args, &block)

    service
  ensure
    service.stop unless service.stopped?
  end

end

require 'dnssd/flags'
require 'dnssd/reply'
require 'dnssd/service'
require 'dnssd/text_record'

