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

  VERSION = '3.0.2'

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
    _, port, = socket.addr

    raise ArgumentError, 'socket not bound' if port == 0

    service ||= Socket.getservbyport port

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

  ##
  # Asynchronous version of DNSSD::Service#browse

  def self.browse type, domain = nil, flags = 0, interface = DNSSD::InterfaceAny
    service = DNSSD::Service.browse type, domain, flags, interface
    service.async_each { |r| yield r }
    service
  end

  ##
  # Synchronous version of DNSSD::Service#browse

  def self.browse! type, domain = nil, flags = 0, interface = DNSSD::InterfaceAny
    service = DNSSD::Service.browse type, domain, flags, interface
    service.each { |r| yield r }
  ensure
    service.stop
  end

  ##
  # Asynchronous version of DNSSD::Service#enumerate_domains

  def self.enumerate_domains flags = DNSSD::Flags::BrowseDomains,
                             interface = DNSSD::InterfaceAny
    service = DNSSD::Service.enumerate_domains flags, interface
    service.async_each { |r| yield r }
    service
  end

  ##
  # Synchronous version of DNSSD::Service#enumerate_domains

  def self.enumerate_domains!(flags = DNSSD::Flags::BrowseDomains,
                              interface = DNSSD::InterfaceAny, &block)
    service = DNSSD::Service.enumerate_domains flags, interface
    service.each { |r| yield r }
  ensure
    service.stop
  end

  ##
  # Asynchronous version of DNSSD::Service#register

  def self.register(name, type, domain, port, text_record = nil, flags = 0,
                    interface = DNSSD::InterfaceAny)
    service = DNSSD::Service.register name, type, domain, port, nil,
      text_record, flags, interface

    service.async_each { |r| yield r } if block_given?

    service
  end

  ##
  # Synchronous version of DNSSD::Service#register

  def self.register!(name, type, domain, port, text_record = nil, flags = 0,
                     interface = DNSSD::InterfaceAny, &block)
    service = DNSSD::Service.register name, type, domain, port, nil,
      text_record, flags, interface

    service.each { |r| yield r } if block_given?
  ensure
    service.stop
  end

  ##
  # Asynchronous version of DNSSD::Service#resolve

  def self.resolve(*args)
    service = DNSSD::Service.resolve(*args)
    service.async_each { |r| yield r }
    service
  end

  ##
  # Synchronous version of DNSSD::Service#resolve

  def self.resolve!(*args)
    service = DNSSD::Service.resolve(*args)
    service.each { |r| yield r }
  ensure
    service.stop if service
  end
end

require 'socket'

require 'dnssd/reply'
require 'dnssd/reply/addr_info'
require 'dnssd/reply/browse'
require 'dnssd/reply/domain'
require 'dnssd/reply/query_record'
require 'dnssd/reply/register'
require 'dnssd/reply/resolve'
require 'dnssd/text_record'

# Suppress avahi compatibilty warning
# http://0pointer.de/avahi-compat?s=libdns_sd&e=ruby
ENV['AVAHI_COMPAT_NOWARN'] = '1'

# The C extension uses above-defined classes
require 'dnssd.so'

module DNSSD
  # :stopdoc:
  class ServiceNotRunningError < UnknownError; end unless
    const_defined? :ServiceNotRunningError

  InterfaceUnicast = 4294967294 unless const_defined? :InterfaceUnicast # -2
  # :startdoc:
end

require 'dnssd/flags'
require 'dnssd/service'
require 'dnssd/record'

