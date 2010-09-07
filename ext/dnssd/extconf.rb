require 'mkmf'

$CFLAGS << ' -Wall' if with_config 'warnings'

dir_config 'dnssd'

abort 'unable to find dnssd header' unless have_header 'dns_sd.h'

have_library('dnssd')  ||
have_library('dns_sd') ||
have_library('mdns')   ||
have_library('System') ||
abort('unable to find dnssd library')

have_macro('htons', 'arpa/inet.h') ||
have_func('htons', 'arpa/inet.h')  ||
abort("couldn't find htons")

have_macro('ntohs', 'arpa/inet.h') ||
have_func('ntohs', 'arpa/inet.h')  ||
abort("couldn't find ntohs")

# These functions live in netioapi.h on Windows, not net/if.h. The MSDN
# documentation says to include iphlpapi.h, not netioapi.h directly.
#
# Note, however, that these functions only exist on Vista/Server 2008 or later.
# On Windows XP and earlier you will have to define a custom version of each
# function using native functions, such as ConvertInterfaceIndexToLuid() and
# ConvertInterfaceLuidToNameA().
#
if have_header 'iphlpapi.h' then
  have_func('if_indextoname', %w[iphlpapi.h netioapi.h]) &&
  have_func('if_nametoindex', %w[iphlpapi.h netioapi.h]) ||
  abort('unable to find if_indextoname or if_nametoindex')
else
  if RUBY_PLATFORM =~ /solaris/ then
    have_library('xnet') ||
      abort('unable to find xnet library for if_indextoname/if_nametoindex')

    $CFLAGS << ' -lxnet'
  end

  have_func('if_indextoname', %w[sys/types.h sys/socket.h net/if.h]) &&
  have_func('if_nametoindex', %w[sys/types.h sys/socket.h net/if.h]) ||
  abort('unable to find if_indextoname or if_nametoindex')
end

# HACK prefer Socket.getservbyport in 1.9
have_func('getservbyport', 'netdb.h') ||
abort('unable to find getservbyport')

have_type('struct sockaddr_in', 'netinet/in.h') ||
abort('unable to find struct sockaddr_in')

have_struct_member 'struct sockaddr_in', 'sin_len', 'netinet/in.h'
# otherwise, use sizeof()

puts
puts 'checking for missing avahi features'
# avahi 0.6.25 is missing these functions
have_func 'DNSServiceGetProperty', 'dns_sd.h'
have_func 'DNSServiceGetAddrInfo', 'dns_sd.h'

# avahi 0.6.25 is missing these flags
have_func 'kDNSServiceFlagsForce', 'dns_sd.h'
have_func 'kDNSServiceFlagsNonBrowsable', 'dns_sd.h'
have_func 'kDNSServiceFlagsReturnIntermediates', 'dns_sd.h'
have_func 'kDNSServiceFlagsShareConnection', 'dns_sd.h'

# avahi 0.6.25 is missing errors after BadTime
have_func 'kDNSServiceErr_BadSig', 'dns_sd.h'

puts
puts 'checking for ruby features'
have_header 'ruby/encoding.h'

puts
create_makefile 'dnssd/dnssd'

