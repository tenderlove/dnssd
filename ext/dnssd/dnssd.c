#include "dnssd.h"

void Init_DNSSD_Errors(void);
void Init_DNSSD_Flags(void);
void Init_DNSSD_Service(void);

static VALUE
dnssd_getservbyport(int argc, VALUE * argv, VALUE self) {
  VALUE _port, _proto;
  struct servent * result;
  int port;
  char * proto = NULL;

  rb_scan_args(argc, argv, "11", &_port, &_proto);

  port = htons(FIX2INT(_port));

  if (RTEST(_proto))
    proto = StringValueCStr(_proto);

  result = getservbyport(port, proto);

  if (result == NULL)
    return Qnil;

  return rb_str_new2(result->s_name);
}

void
Init_dnssd(void) {
  VALUE mDNSSD = rb_define_module("DNSSD");

  /* Specifies all interfaces. */
  rb_define_const(mDNSSD, "InterfaceAny", ULONG2NUM(kDNSServiceInterfaceIndexAny));

  /* Specifies local interfaces only. */
  rb_define_const(mDNSSD, "InterfaceLocalOnly", ULONG2NUM(kDNSServiceInterfaceIndexLocalOnly));

  rb_define_singleton_method(mDNSSD, "getservbyport", dnssd_getservbyport, -1);

  Init_DNSSD_Errors();
  Init_DNSSD_Flags();
  Init_DNSSD_Service();
}

