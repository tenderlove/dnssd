#ifndef RDNSSD_INCLUDED
#define RDNSSD_INCLUDED

#include <ruby.h>

#include <dns_sd.h>

#include <arpa/inet.h>  /* htons ntohs */
#include <sys/socket.h> /* struct sockaddr_in */
#include <netdb.h>      /* getservbyport */

/* if_indextoname and if_nametoindex */
#ifdef HAVE_IPHLPAPI_H
#include <iphlpapi.h> /* Vista and newer */
#else
#include <sys/types.h>
#include <net/if.h>
#endif

#ifdef HAVE_ST_SIN_LEN
#define SIN_LEN(si) (si)->sin_len
#else
#define SIN_LEN(si) sizeof(struct sockaddr_in)
#endif

#include <ruby/encoding.h>
#define dnssd_utf8_cstr(str, to) \
  do {\
    VALUE utf8;\
    utf8 = rb_str_encode(str, rb_enc_from_encoding(rb_utf8_encoding()),\
        0, Qnil);\
    to = StringValueCStr(utf8);\
  } while (0)

extern VALUE eDNSSDError;

void dnssd_check_error_code(DNSServiceErrorType e);

#endif /* RDNSSD_INCLUDED */

