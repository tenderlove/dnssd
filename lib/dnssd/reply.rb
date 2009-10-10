##
# DNSSD::Reply is used to return information

class DNSSD::Reply

  ##
  # Flags for this reply, see DNSSD::Flags

  attr_reader :flags

  ##
  # The interface name for this reply

  attr_reader :interface

  ##
  # The DNSSD::Service that created this reply

  attr_reader :service

  ##
  # Creates a new reply attached to +service+ with +flags+ on interface index
  # +interface+

  def initialize(service, flags, interface)
    @service = service
    @flags = DNSSD::Flags.new flags
    @interface = if interface then
                   interface > 0 ? DNSSD.interface_name(interface) : interface
                 end
  end

  ##
  # The full service domain name, see DNSS::Service#fullname

  def fullname
    fullname = DNSSD::Service.fullname @name.gsub("\032", ' '), @type, @domain
    fullname << '.' unless fullname =~ /\.$/
    fullname
  end

  def inspect # :nodoc:
    "#<%s:0x%x interface: %s flags: %p>" % [
      self.class, object_id, interface_name, @flags
    ]
  end

  ##
  # Expands the name of the interface including constants

  def interface_name
    case @interface
    when nil                       then 'nil'
    when DNSSD::InterfaceAny       then 'any'
    when DNSSD::InterfaceLocalOnly then 'local'
    when DNSSD::InterfaceUnicast   then 'unicast'
    else @interface
    end
  end

  ##
  # Protocol of this service

  def protocol
    raise TypeError, 'no type on this reply' unless
      instance_variable_defined? :@type

    @type.split('.').last.sub '_', ''
  end

  ##
  # Service name as in Socket.getservbyname

  def service_name
    raise TypeError, 'no type on this reply' unless
      instance_variable_defined? :@type

    @type.split('.').first.sub '_', ''
  end

  ##
  # Sets #name, #type and #domain from +fullname+

  def set_fullname(fullname)
    fullname = fullname.gsub(/\\([0-9]{1,3})/) do $1.to_i.chr end
    fullname = fullname.scan(/(?:[^\\.]|\\\.)+/).map do |part|
      part.gsub "\\.", '.'
    end

    @name   = fullname[0]
    @type   = fullname[1, 2].join '.'
    @domain = fullname[3..-1].map { |part| part.sub '.', '\\.' }.join('.') + '.'
  end

  ##
  # Sets #name, #type and #domain

  def set_names(name, type, domain)
    set_fullname [name, type, domain].join('.')
  end

end

