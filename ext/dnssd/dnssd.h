#ifndef RDNSSD_INCLUDED
#define RDNSSD_INCLUDED

#include <ruby.h>
#include <dns_sd.h>

/* for if_indextoname() and other unix networking functions */
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#ifdef HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
#ifdef HAVE_SYS_SOCKET_H
#include <sys/socket.h>
#endif
#ifdef HAVE_SYS_PARAM_H
#include <sys/param.h>
#endif
#ifdef HAVE_NET_IF_H
#include <net/if.h>
#endif
#ifdef HAVE_SYS_IF_H
#include <sys/if.h>
#endif
#ifdef HAVE_NETDB_H
#include <netdb.h>
#endif

#ifdef HAVE_SIN_LEN
# define SIN_LEN(si) (si)->sin_len
#else
# define SIN_LEN(si) sizeof(struct sockaddr_in)
#endif

extern VALUE eDNSSDError;

void dnssd_check_error_code(DNSServiceErrorType e);

#endif /* RDNSSD_INCLUDED */

