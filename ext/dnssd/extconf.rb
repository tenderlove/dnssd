#!/usr/bin/env ruby
# :stopdoc:
#
# Extension configuration script for DNS_SD C Extension.

def check_for_funcs(*funcs)
  funcs.flatten!
  funcs.each do |f|
    abort("need function #{f}") unless have_func(f)
  end
end

require "mkmf"

$CFLAGS << " -Wall"
$CFLAGS << " -DDEBUG" if $DEBUG

libraries = {
  'mdns'   => 'DNSServiceRefSockFD',
  'dns_sd' => 'DNSServiceRefSockFD',
  'System' => 'DNSServiceRefSockFD'
}.sort

dnssd_found = libraries.any? do |library, function|
  have_library library, function
end

unless dnssd_found then
  abort "Couldn't find DNSSD in libraries #{libraries.keys.join ', '}"
end

have_header "dns_sd.h" or abort "can't find the rendezvous client headers"

have_header "unistd.h"
have_header "sys/types.h"
have_header "sys/socket.h"
have_header "sys/param.h"
have_header "sys/if.h"
have_header "net/if.h"
have_header "arpa/inet.h"
have_header "netdb.h"

abort "need function #{f}" unless have_macro("htons") || have_func("htons")
abort "need function #{f}" unless have_macro("ntohs") || have_func("ntohs")

check_for_funcs "if_indextoname", "if_nametoindex"
have_func "gethostname"

s1 = check_sizeof "void*"
s2 = check_sizeof("DNSServiceFlags", "dns_sd.h") or
  abort("can't determine sizeof(DNSServiceFlags)")

# need to make sure storing unsigned integer in void * is OK.
s1 >= s2 or abort("sizeof(void*) < sizeof(DNSServiceFlags) please contact the authors!")

create_makefile "dnssd"

# :startdoc:

