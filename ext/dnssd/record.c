#include "dnssd.h"

static VALUE cDNSSDRecord;

static void
dnssd_record_free(void *ptr) {
  DNSRecordRef *record = (DNSRecordRef *)ptr;

  /* TODO */

  free(record);
}

static VALUE
dnssd_record_s_allocate(VALUE klass) {
  DNSRecordRef *record = ALLOC(DNSRecordRef);

  *record = NULL;

  return Data_Wrap_Struct(klass, 0, dnssd_record_free, record);
}

void
Init_DNSSD_Record(void) {
  VALUE mDNSSD = rb_define_module("DNSSD");

  cDNSSDRecord = rb_define_class_under(mDNSSD, "Record", rb_cObject);

  rb_define_alloc_func(cDNSSDRecord, dnssd_record_s_allocate);

  /* Internet service class */
  rb_define_const(cDNSSDRecord, "IN", UINT2NUM(kDNSServiceClass_IN));

  /* Host address. */
  rb_define_const(cDNSSDRecord, "A", UINT2NUM(kDNSServiceType_A));

  /* Authoritative server. */
  rb_define_const(cDNSSDRecord, "NS", UINT2NUM(kDNSServiceType_NS));

  /* Mail destination. */
  rb_define_const(cDNSSDRecord, "MD", UINT2NUM(kDNSServiceType_MD));

  /* Mail forwarder. */
  rb_define_const(cDNSSDRecord, "MF", UINT2NUM(kDNSServiceType_MF));

  /* Canonical name. */
  rb_define_const(cDNSSDRecord, "CNAME", UINT2NUM(kDNSServiceType_CNAME));

  /* Start of authority zone. */
  rb_define_const(cDNSSDRecord, "SOA", UINT2NUM(kDNSServiceType_SOA));

  /* Mailbox domain name. */
  rb_define_const(cDNSSDRecord, "MB", UINT2NUM(kDNSServiceType_MB));

  /* Mail group member. */
  rb_define_const(cDNSSDRecord, "MG", UINT2NUM(kDNSServiceType_MG));

  /* Mail rename name. */
  rb_define_const(cDNSSDRecord, "MR", UINT2NUM(kDNSServiceType_MR));

  /* Null resource record. */
  rb_define_const(cDNSSDRecord, "NULL", UINT2NUM(kDNSServiceType_NULL));

  /* Well known service. */
  rb_define_const(cDNSSDRecord, "WKS", UINT2NUM(kDNSServiceType_WKS));

  /* Domain name pointer. */
  rb_define_const(cDNSSDRecord, "PTR", UINT2NUM(kDNSServiceType_PTR));

  /* Host information. */
  rb_define_const(cDNSSDRecord, "HINFO", UINT2NUM(kDNSServiceType_HINFO));

  /* Mailbox information. */
  rb_define_const(cDNSSDRecord, "MINFO", UINT2NUM(kDNSServiceType_MINFO));

  /* Mail routing information. */
  rb_define_const(cDNSSDRecord, "MX", UINT2NUM(kDNSServiceType_MX));

  /* One or more text strings (NOT "zero or more..."). */
  rb_define_const(cDNSSDRecord, "TXT", UINT2NUM(kDNSServiceType_TXT));

  /* Responsible person. */
  rb_define_const(cDNSSDRecord, "RP", UINT2NUM(kDNSServiceType_RP));

  /* AFS cell database. */
  rb_define_const(cDNSSDRecord, "AFSDB", UINT2NUM(kDNSServiceType_AFSDB));

  /* X_25 calling address. */
  rb_define_const(cDNSSDRecord, "X25", UINT2NUM(kDNSServiceType_X25));

  /* ISDN calling address. */
  rb_define_const(cDNSSDRecord, "ISDN", UINT2NUM(kDNSServiceType_ISDN));

  /* Router. */
  rb_define_const(cDNSSDRecord, "RT", UINT2NUM(kDNSServiceType_RT));

  /* NSAP address. */
  rb_define_const(cDNSSDRecord, "NSAP", UINT2NUM(kDNSServiceType_NSAP));

  /* Reverse NSAP lookup (deprecated). */
  rb_define_const(cDNSSDRecord, "NSAP_PTR", UINT2NUM(kDNSServiceType_NSAP_PTR));

  /* Security signature. */
  rb_define_const(cDNSSDRecord, "SIG", UINT2NUM(kDNSServiceType_SIG));

  /* Security key. */
  rb_define_const(cDNSSDRecord, "KEY", UINT2NUM(kDNSServiceType_KEY));

  /* X.400 mail mapping. */
  rb_define_const(cDNSSDRecord, "PX", UINT2NUM(kDNSServiceType_PX));

  /* Geographical position (withdrawn). */
  rb_define_const(cDNSSDRecord, "GPOS", UINT2NUM(kDNSServiceType_GPOS));

  /* IPv6 Address. */
  rb_define_const(cDNSSDRecord, "AAAA", UINT2NUM(kDNSServiceType_AAAA));

  /* Location Information. */
  rb_define_const(cDNSSDRecord, "LOC", UINT2NUM(kDNSServiceType_LOC));

  /* Next domain (security). */
  rb_define_const(cDNSSDRecord, "NXT", UINT2NUM(kDNSServiceType_NXT));

  /* Endpoint identifier. */
  rb_define_const(cDNSSDRecord, "EID", UINT2NUM(kDNSServiceType_EID));

  /* Nimrod Locator. */
  rb_define_const(cDNSSDRecord, "NIMLOC", UINT2NUM(kDNSServiceType_NIMLOC));

  /* Server Selection. */
  rb_define_const(cDNSSDRecord, "SRV", UINT2NUM(kDNSServiceType_SRV));

  /* ATM Address */
  rb_define_const(cDNSSDRecord, "ATMA", UINT2NUM(kDNSServiceType_ATMA));

  /* Naming Authority PoinTeR */
  rb_define_const(cDNSSDRecord, "NAPTR", UINT2NUM(kDNSServiceType_NAPTR));

  /* Key Exchange */
  rb_define_const(cDNSSDRecord, "KX", UINT2NUM(kDNSServiceType_KX));

  /* Certification record */
  rb_define_const(cDNSSDRecord, "CERT", UINT2NUM(kDNSServiceType_CERT));

  /* IPv6 Address (deprecated) */
  rb_define_const(cDNSSDRecord, "A6", UINT2NUM(kDNSServiceType_A6));

  /* Non-terminal DNAME (for IPv6) */
  rb_define_const(cDNSSDRecord, "DNAME", UINT2NUM(kDNSServiceType_DNAME));

  /* Kitchen sink (experimental) */
  rb_define_const(cDNSSDRecord, "SINK", UINT2NUM(kDNSServiceType_SINK));

  /* EDNS0 option (meta-RR) */
  rb_define_const(cDNSSDRecord, "OPT", UINT2NUM(kDNSServiceType_OPT));

  /* Address Prefix List */
  rb_define_const(cDNSSDRecord, "APL", UINT2NUM(kDNSServiceType_APL));

  /* Delegation Signer */
  rb_define_const(cDNSSDRecord, "DS", UINT2NUM(kDNSServiceType_DS));

  /* SSH Key Fingerprint */
  rb_define_const(cDNSSDRecord, "SSHFP", UINT2NUM(kDNSServiceType_SSHFP));

  /* IPSECKEY */
  rb_define_const(cDNSSDRecord, "IPSECKEY", UINT2NUM(kDNSServiceType_IPSECKEY));

  /* RRSIG */
  rb_define_const(cDNSSDRecord, "RRSIG", UINT2NUM(kDNSServiceType_RRSIG));

  /* NSEC */
  rb_define_const(cDNSSDRecord, "NSEC", UINT2NUM(kDNSServiceType_NSEC));

  /* DNSKEY */
  rb_define_const(cDNSSDRecord, "DNSKEY", UINT2NUM(kDNSServiceType_DNSKEY));

  /* DHCID */
  rb_define_const(cDNSSDRecord, "DHCID", UINT2NUM(kDNSServiceType_DHCID));

  /* Transaction key */
  rb_define_const(cDNSSDRecord, "TKEY", UINT2NUM(kDNSServiceType_TKEY));

  /* Transaction signature. */
  rb_define_const(cDNSSDRecord, "TSIG", UINT2NUM(kDNSServiceType_TSIG));

  /* Incremental zone transfer. */
  rb_define_const(cDNSSDRecord, "IXFR", UINT2NUM(kDNSServiceType_IXFR));

  /* Transfer zone of authority. */
  rb_define_const(cDNSSDRecord, "AXFR", UINT2NUM(kDNSServiceType_AXFR));

  /* Transfer mailbox records. */
  rb_define_const(cDNSSDRecord, "MAILB", UINT2NUM(kDNSServiceType_MAILB));

  /* Transfer mail agent records. */
  rb_define_const(cDNSSDRecord, "MAILA", UINT2NUM(kDNSServiceType_MAILA));

  /* Wildcard match. */
  rb_define_const(cDNSSDRecord, "ANY", UINT2NUM(kDNSServiceType_ANY));
}

