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

static VALUE
dnssd_if_nametoindex(VALUE self, VALUE name) {
  return UINT2NUM(if_nametoindex(StringValueCStr(name)));
}

static VALUE
dnssd_if_indextoname(VALUE self, VALUE index) {
  char buffer[IF_NAMESIZE];

  if (if_indextoname(NUM2UINT(index), buffer))
    return rb_str_new2(buffer);

  rb_raise(rb_eArgError, "invalid interface %d", NUM2UINT(index));

  return Qnil;
}

void
Init_dnssd(void) {
  VALUE mDNSSD = rb_define_module("DNSSD");

  /* Specifies all interfaces. */
  rb_define_const(mDNSSD, "InterfaceAny", ULONG2NUM(kDNSServiceInterfaceIndexAny));

  /* Specifies local interfaces only. */
  rb_define_const(mDNSSD, "InterfaceLocalOnly", ULONG2NUM(kDNSServiceInterfaceIndexLocalOnly));

  rb_define_singleton_method(mDNSSD, "getservbyport", dnssd_getservbyport, -1);

  rb_define_singleton_method(mDNSSD, "interface_index", dnssd_if_nametoindex, 1);
  rb_define_singleton_method(mDNSSD, "interface_name", dnssd_if_indextoname, 1);

  Init_DNSSD_Errors();
  Init_DNSSD_Flags();
  Init_DNSSD_Service();
}

