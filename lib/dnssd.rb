require 'dnssd/dnssd'
require 'socket'

##
# DNSSD is a wrapper for Apple's DNS Service Discovery library.  The methods
# DNSSD.enumerate_domains, DNSSD.browse(), DNSSD.register(), and
# DNSSD.resolve() provide the basic API for making your applications DNS
# Service Discovery aware.

module DNSSD

  VERSION = '1.1.0'

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

    interface = DNSSD.interface_index interface unless Numeric === interface

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

end

require 'dnssd/flags'
require 'dnssd/reply'
require 'dnssd/service'
require 'dnssd/text_record'

=begin

module DNSSD
  class MalformedDomain < Error; end
  class MalformedPort < Error; end

  def self.new_text_record(hash={})
    TextRecord.new(hash)
  end

  class ServiceDescription

    class Location
      attr_accessor :name, :port, :iface
      def initialize(port, name=nil, iface=0)
        @name = name
        @port = port
        @iface = iface
      end
    end

    def initialize(type, name, domain, location)
      @type = type
      @name = name
      @domain = validate_domain(domain)
      @location = validate_location(location)
    end

    def self.for_browse_notification(name, domain,

    def stop
      @registrar.stop
    end

    def validate_location(location)
      unless(location.port.respond_to?(:to_int))
        raise MalformedPort.new("#{location.port} is not a valid port number")
      end
      location
    end

    def validate_domain(domain)
      unless(domain.empty? || domain =~ /^[a-z_]+$/)
	      raise MalformedDomain.new("#{domain} is not a valid domain name")
      end
      domain
    end

    def advertise_and_confirm
      thread = Thread.current
       @registrar = register(@name, @type, @domain, @location.port, TextRecord.new) do |service, name, type, domain|
        @name = name
        @type = type
        @domain = domain
        thread.wakeup
      end
      Thread.stop
    end

    def self.advertise_http(name, port=80, domain="", iface=0, &block)
      self.advertise("_http._tcp", name, port, domain, iface, &block)
    end

    ##
    # iface: Numerical interface (0 = all interfaces, This should be used for
    # most applications)

    def self.advertise(type, name, port, domain="", iface=0, &block)
      service_description = ServiceDescription.new(type, name, domain, Location.new(port,nil,iface))
      service_description.advertise_and_confirm
      yield service_description if block_given?
      service_description
    end
  end

  class Browser

    Context = Struct.new(:service, :name, :type, :domain, :operation, :interface)

    class Context
      def ==(other)
        self.to_s == other.to_s
      end

      def to_s
        "#{name}.#{type}.#{domain}"
      end

      def eql?(other)
        self == other
      end

      def hash
        to_s.hash
      end
    end

    def on_change(&block)
      @change_listener ||= []
      @change_listeners << block
    end

    def on_add(&block)
      @add_listeners || = []
      @add_listeners << block
    end

    def on_remove(&block)
      @remove_listeners || = []
      @remove_listeners << block
    end

    def initialize(type, domain="")
      @list = []
      @browse_service = DNSSD::Protocol.browse(type, domain) do
         |service, name, type, domain, operation, interface|
         context = Context.new(service, name, type, domain, operation, interface)
         puts "Name: #{name} Type: #{type} Domain: #{domain} Operation: #{operation} Interface: #{interface}"
      end
    end

    def service_descriptions
      @list.clone
    end

    def stop
      @browse_service.stop
    end

    def self.for_http(domain="")
      self.new("_http._tcp", domain)
    end
  end
end

=end
