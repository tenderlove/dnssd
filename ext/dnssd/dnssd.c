#include "dnssd.h"

void Init_DNSSD_Errors(void);
void Init_DNSSD_Flags(void);
void Init_DNSSD_Service(void);
void Init_DNSSD_TextRecord(void);

void
Init_dnssd(void) {
  rb_define_module("DNSSD");

  /* Specifies all interfaces. */
  rb_define_const(mDNSSD, "InterfaceAny", ULONG2NUM(kDNSServiceInterfaceIndexAny));

  /* Specifies local interfaces only. */
  rb_define_const(mDNSSD, "InterfaceLocalOnly", ULONG2NUM(kDNSServiceInterfaceIndexLocalOnly));

  Init_DNSSD();
  Init_DNSSD_Errors();
  Init_DNSSD_Service();
  Init_DNSSD_TextRecord();
  Init_DNSSD_Flags();
}

