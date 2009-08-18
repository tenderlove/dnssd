require 'ipaddr'

##
# Created when adding a DNS record using DNSSD::Service#add_record.  Provides
# convenience methods for creating the DNS record.
#
# See also {RFC 1035}[http://www.rfc-editor.org/rfc/rfc1035.txt]

class DNSSD::Record

  value_to_name = constants.map do |name|
    next if name.intern == :IN
    [const_get(name), name.to_s]
  end.compact.flatten

  ##
  # Maps record constant values to the constant name

  VALUE_TO_NAME = Hash[*value_to_name]

  ##
  # Turns +string+ into an RFC-1035 character-string

  def self.string_to_character_string(string)
    length = string.length
    raise ArgumentError, "#{string.inspect} is too long (255 bytes max)" if
      length > 255
    "#{length.chr}#{string}"
  end

  ##
  # Turns +string+ into an RFC-1035 domain-name

  def self.string_to_domain_name(string)
    string.split('.').map do |part|
      string_to_character_string part
    end.join('') << "\0"
  end

  ##
  # Encodes resource +args+ into +type+.  Handles:
  #
  # A AAAA CNAME MX NS PTR SOA SRV TXT

  def self.to_data(type, *args)
    raise ArgumentError, "unknown type #{type}" unless VALUE_TO_NAME.key? type

    data = case type
           when A then
             addr = args.shift
             addr = IPAddr.new addr unless IPAddr === addr
             raise ArgumentError, "#{addr} is not IPv4" unless addr.ipv4?
             addr.hton
           when AAAA then
             addr = args.shift
             addr = IPAddr.new addr unless IPAddr === addr
             raise ArgumentError, "#{addr} is not IPv6" unless addr.ipv6?
             addr.hton
           when CNAME, NS, PTR then
             string_to_domain_name args.shift
           when MX then
             [args.shift, string_to_domain_name(args.shift)].pack 'na*'
           when SOA then
             [
               string_to_domain_name(args.shift),
               string_to_domain_name(args.shift),
               args.shift, args.shift, args.shift, args.shift, args.shift
             ].pack 'a*a*NNNNN'
           when SRV then
             [
               args.shift, args.shift, args.shift,
               string_to_domain_name(args.shift)
             ].pack 'nnna*'
           when TXT then
             data = args.map do |string|
               string_to_character_string string
             end.join ''

             raise ArgumentError,
                   "TXT record too long (#{data.length} bytes)" if
               data.length > 65535

             args.clear

             data
           else
             raise ArgumentError, "unhandled record type #{VALUE_TO_NAME[type]}"
           end

    raise ArgumentError, "Too many arguments for #{VALUE_TO_NAME[type]}" unless
      args.empty?

    data
  end

end

