#include <netinet/in.h>
#include "dnssd.h"

static VALUE mDNSSD;
static VALUE cDNSSDFlags;
static VALUE cDNSSDRecord;
static VALUE cDNSSDReplyAddrInfo;
static VALUE cDNSSDReplyBrowse;
static VALUE cDNSSDReplyDomain;
static VALUE cDNSSDReplyQueryRecord;
static VALUE cDNSSDReplyRegister;
static VALUE cDNSSDReplyResolve;
static VALUE cDNSSDService;
static VALUE cDNSSDServiceRegister;
static VALUE cDNSSDTextRecord;
static VALUE rb_cSocket;

static ID dnssd_id_join;
static ID dnssd_id_push;

static ID dnssd_iv_continue;
static ID dnssd_iv_records;
static ID dnssd_iv_replies;
static ID dnssd_iv_service;
static ID dnssd_iv_thread;
static ID dnssd_iv_type;

static void
dnssd_service_free_client(DNSServiceRef *client) {
  if (*client) {
    DNSServiceRefDeallocate(*client);
    *client = NULL;
  }
}

static void
dnssd_service_free(void *ptr) {
  DNSServiceRef *client = (DNSServiceRef*)ptr;

  if (client)
    dnssd_service_free_client(client);

  free(client);
}

static const rb_data_type_t dnssd_service_type = {
    "DNSSD/service",
    {0, dnssd_service_free, 0,},
    0, 0,
#ifdef RUBY_TYPED_FREE_IMMEDIATELY
    RUBY_TYPED_FREE_IMMEDIATELY,
#endif
};

#define get(klass, obj, type, var) \
  do {\
    Check_Type(obj, T_DATA);\
    if (rb_obj_is_kind_of(obj, klass) != Qtrue)\
    rb_raise(rb_eTypeError,\
        "wrong argument type %s",\
        rb_class2name(CLASS_OF(obj)));\
    Data_Get_Struct(obj, type, var);\
  } while (0)

static VALUE
create_fullname(const char *name, const char *regtype,
    const char *domain) {
  VALUE fullname;
  char buffer[kDNSServiceMaxDomainName];

  if (DNSServiceConstructFullName(buffer, name, regtype, domain)) {
    static const char msg[] = "could not construct full service name";
    rb_raise(rb_eArgError, msg);
  }

  buffer[kDNSServiceMaxDomainName - 1] = '\000'; /* just in case */

  fullname = rb_str_new2(buffer);
  rb_enc_associate(fullname, rb_utf8_encoding());

  return fullname;
}

/*
 * call-seq:
 *   DNSSD::Service.fullname(name, type, domain)
 *
 * Concatenate a three-part domain name like DNSSD::Reply#fullname into a
 * properly-escaped full domain name.
 *
 * Any dots or slashes in the +name+ must NOT be escaped.
 *
 * +name+ may be +nil+ (to construct a PTR record name, e.g.
 * "_ftp._tcp.apple.com").
 *
 * The +type+ is the service type followed by the protocol, separated by a dot
 * (e.g. "_ftp._tcp").
 *
 * The +domain+ is the domain name, e.g. "apple.com".  Any literal dots or
 * backslashes must be escaped.
 *
 * Raises ArgumentError if the full service name cannot be
 * constructed from the arguments.
 */

static VALUE
dnssd_service_s_fullname(VALUE klass, VALUE _name, VALUE _type, VALUE _domain) {
  char * name, * type, * domain;

  dnssd_utf8_cstr(_name, name);
  dnssd_utf8_cstr(_type, type);
  dnssd_utf8_cstr(_domain, domain);

  return create_fullname(name, type, domain);
}

#ifdef HAVE_DNSSERVICEGETPROPERTY
/*
 * call-seq:
 *   service.get_property(property)
 *
 * Binding for DNSServiceGetProperty.  The only property currently supported in
 * DNSSD is DaemonVersion
 */
static VALUE
dnssd_service_s_get_property(VALUE klass, VALUE _property) {
  char * property;
  uint32_t result = 0;
  uint32_t size = sizeof(result);
  DNSServiceErrorType e;

  dnssd_utf8_cstr(_property, property);

  e = DNSServiceGetProperty(property, (void *)&result, &size);

  dnssd_check_error_code(e);

  /* as of this writing only a uint32_t will be returned */
  return ULONG2NUM(result);
}
#endif

static VALUE
dnssd_service_s_allocate(VALUE klass) {
  DNSServiceRef *client = ALLOC(DNSServiceRef);

  *client = NULL;

  return Data_Wrap_Struct(klass, 0, dnssd_service_free, client);
}

/* Stops the service, closing the underlying socket and killing the underlying
 * thread.
 *
 * It is good practice to all stop running services before exit.
 *
 *   service = DNSSD.browse('_http._tcp') do |r|
 *     puts "Found #{r.name}"
 *   end
 *   sleep(2)
 *   service.stop
 */

static VALUE
dnssd_service_stop(VALUE self) {
  DNSServiceRef *client;

  TypedData_Get_Struct(self, DNSServiceRef, &dnssd_service_type, client);

  dnssd_service_free_client(client);

  return self;
}

static VALUE
dnssd_ref_sock_fd(VALUE self) {
  DNSServiceRef *client;
  TypedData_Get_Struct(self, DNSServiceRef, &dnssd_service_type, client);

  return INT2NUM(DNSServiceRefSockFD(*client));
}

static VALUE
dnssd_process_result(VALUE self) {
  DNSServiceRef *client;
  DNSServiceErrorType e;
  TypedData_Get_Struct(self, DNSServiceRef, &dnssd_service_type, client);

  e = DNSServiceProcessResult(*client);
  dnssd_check_error_code(e);

  return Qtrue;
}

/* call-seq:
 *   service._add_record(flags, type, data, ttl)
 *
 * Binding to DNSServiceAddRecord
 */

static VALUE
dnssd_service_add_record(VALUE self, VALUE _flags, VALUE _rrtype, VALUE _rdata,
    VALUE _ttl) {
  VALUE _record = Qnil;
  DNSServiceRef *client;
  DNSRecordRef *record;
  DNSServiceFlags flags;
  DNSServiceErrorType e;
  uint16_t rrtype;
  uint16_t rdlen;
  const void *rdata;
  uint32_t ttl;

  _rdata = rb_str_to_str(_rdata);
  flags = (DNSServiceFlags)NUM2ULONG(_flags);
  rrtype = NUM2UINT(_rrtype);
  rdlen = RSTRING_LEN(_rdata);
  rdata = (void *)StringValuePtr(_rdata);
  ttl = (uint32_t)NUM2ULONG(_ttl);

  TypedData_Get_Struct(self, DNSServiceRef, &dnssd_service_type, client);

  _record = rb_class_new_instance(0, NULL, cDNSSDRecord);

  get(cDNSSDRecord, _record, DNSRecordRef, record);

  e = DNSServiceAddRecord(*client, record, flags, rrtype, rdlen, rdata, ttl);

  dnssd_check_error_code(e);

  /* record will become invalid when this service is destroyed */
  rb_ivar_set(_record, dnssd_iv_service, self);

  return _record;
}

static void DNSSD_API
dnssd_service_browse_reply(DNSServiceRef client, DNSServiceFlags flags,
    uint32_t interface, DNSServiceErrorType e, const char *name,
    const char *type, const char *domain, void *context) {
  VALUE service, reply, argv[6];

  dnssd_check_error_code(e);

  service = (VALUE)context;

  argv[0] = service;
  argv[1] = ULONG2NUM(flags);
  argv[2] = ULONG2NUM(interface);
  argv[3] = rb_str_new2(name);
  rb_enc_associate(argv[3], rb_utf8_encoding());
  argv[4] = rb_str_new2(type);
  rb_enc_associate(argv[4], rb_utf8_encoding());
  argv[5] = rb_str_new2(domain);
  rb_enc_associate(argv[5], rb_utf8_encoding());

  reply = rb_class_new_instance(6, argv, cDNSSDReplyBrowse);

  rb_funcall(service, dnssd_id_push, 1, reply);
}

/* call-seq:
 *   service._browse(flags, interface, type, domain)
 *
 * Binding to DNSServiceBrowse
 */

static VALUE
dnssd_service_browse(VALUE klass, VALUE _flags, VALUE _interface, VALUE _type,
    VALUE _domain) {
  const char *type;
  const char *domain = NULL;
  DNSServiceFlags flags = 0;
  uint32_t interface = 0;

  DNSServiceErrorType e;
  DNSServiceRef *client;
  VALUE self;

  dnssd_utf8_cstr(_type, type);

  if (!NIL_P(_domain))
    dnssd_utf8_cstr(_domain, domain);

  if (!NIL_P(_flags))
    flags = (DNSServiceFlags)NUM2ULONG(_flags);

  if (!NIL_P(_interface))
    interface = (uint32_t)NUM2ULONG(_interface);

  client = xcalloc(1, sizeof(DNSServiceRef));
  self = TypedData_Wrap_Struct(klass, &dnssd_service_type, client);
  rb_obj_call_init(self, 0, 0);

  e = DNSServiceBrowse(client, flags, interface, type, domain,
      dnssd_service_browse_reply, (void *)self);

  dnssd_check_error_code(e);

  return self;
}

static void DNSSD_API
dnssd_service_enumerate_domains_reply(DNSServiceRef client,
    DNSServiceFlags flags, uint32_t interface, DNSServiceErrorType e,
    const char *domain, void *context) {
  VALUE service, reply, argv[4];

  dnssd_check_error_code(e);

  service = (VALUE)context;

  argv[0] = service;
  argv[1] = ULONG2NUM(flags);
  argv[2] = ULONG2NUM(interface);
  argv[3] = rb_str_new2(domain);
  rb_enc_associate(argv[3], rb_utf8_encoding());

  reply = rb_class_new_instance(4, argv, cDNSSDReplyDomain);

  rb_funcall(service, dnssd_id_push, 1, reply);
}

/* call-seq:
 *   service._enumerate_domains(flags, interface)
 *
 * Binding to DNSServiceEnumerateDomains
 */

static VALUE
dnssd_service_enumerate_domains(VALUE klass, VALUE _flags, VALUE _interface) {
  DNSServiceFlags flags = 0;
  uint32_t interface = 0;
  VALUE self;

  DNSServiceErrorType e;
  DNSServiceRef *client;

  if (!NIL_P(_flags))
    flags = (DNSServiceFlags)NUM2ULONG(_flags);

  if (!NIL_P(_interface))
    interface = (uint32_t)NUM2ULONG(_interface);

  client = xcalloc(1, sizeof(DNSServiceRef));
  self = TypedData_Wrap_Struct(klass, &dnssd_service_type, client);
  rb_obj_call_init(self, 0, 0);

  e = DNSServiceEnumerateDomains(client, flags, interface,
      dnssd_service_enumerate_domains_reply, (void *)self);

  dnssd_check_error_code(e);

  return self;
}

#ifdef HAVE_DNSSERVICEGETADDRINFO
static void DNSSD_API
dnssd_service_getaddrinfo_reply(DNSServiceRef client, DNSServiceFlags flags,
    uint32_t interface, DNSServiceErrorType e, const char *host,
    const struct sockaddr *address, uint32_t ttl, void *context) {
  VALUE service, reply, argv[6];

  dnssd_check_error_code(e);

  service = (VALUE)context;

  argv[0] = service;
  argv[1] = ULONG2NUM(flags);
  argv[2] = ULONG2NUM(interface);
  argv[3] = rb_str_new2(host);
  rb_enc_associate(argv[3], rb_utf8_encoding());
  argv[4] = rb_str_new((char *)address, SIN_LEN((struct sockaddr_in*)address));
  rb_enc_associate(argv[4], rb_utf8_encoding());
  argv[5] = ULONG2NUM(ttl);

  reply = rb_class_new_instance(6, argv, cDNSSDReplyAddrInfo);

  rb_funcall(service, dnssd_id_push, 1, reply);
}

/* call-seq:
 *   service._getaddrinfo(flags, interface, host, protocol)
 *
 * Binding to DNSServiceGetAddrInfo
 */

static VALUE
dnssd_service_getaddrinfo(VALUE klass, VALUE _flags, VALUE _interface,
    VALUE _protocol, VALUE _host) {
  DNSServiceFlags flags = 0;
  uint32_t interface = 0;
  DNSServiceProtocol protocol = 0;
  const char *host;
  VALUE self;

  DNSServiceErrorType e;
  DNSServiceRef *client;

  dnssd_utf8_cstr(_host, host);

  protocol = (DNSServiceProtocol)NUM2ULONG(_protocol);

  if (!NIL_P(_flags))
    flags = (DNSServiceFlags)NUM2ULONG(_flags);

  if (!NIL_P(_interface))
    interface = (uint32_t)NUM2ULONG(_interface);

  client = xcalloc(1, sizeof(DNSServiceRef));
  self = TypedData_Wrap_Struct(klass, &dnssd_service_type, client);
  rb_obj_call_init(self, 0, 0);

  e = DNSServiceGetAddrInfo(client, flags, interface, protocol, host,
      dnssd_service_getaddrinfo_reply, (void *)self);

  dnssd_check_error_code(e);

  return self;
}
#endif

static void DNSSD_API
dnssd_service_query_record_reply(DNSServiceRef client, DNSServiceFlags flags,
    uint32_t interface, DNSServiceErrorType e, const char *fullname,
    uint16_t rrtype, uint16_t rrclass, uint16_t rdlen, const void *rdata,
    uint32_t ttl, void *context) {
  VALUE service, reply, argv[8];

  dnssd_check_error_code(e);

  service = (VALUE)context;

  argv[0] = service;
  argv[1] = ULONG2NUM(flags);
  argv[2] = ULONG2NUM(interface);
  argv[3] = rb_str_new2(fullname);
  rb_enc_associate(argv[3], rb_utf8_encoding());
  argv[4] = UINT2NUM(rrtype);
  argv[5] = UINT2NUM(rrclass);
  argv[6] = rb_str_new((char *)rdata, rdlen);
  rb_enc_associate(argv[6], rb_utf8_encoding());
  argv[7] = ULONG2NUM(ttl);

  reply = rb_class_new_instance(8, argv, cDNSSDReplyQueryRecord);

  rb_funcall(service, dnssd_id_push, 1, reply);
}

/* call-seq:
 *   service._query_record(flags, interface, fullname, record_type, record_class)
 *
 * Binding to DNSServiceQueryRecord
 */

static VALUE
dnssd_service_query_record(VALUE klass, VALUE _flags, VALUE _interface,
    VALUE _fullname, VALUE _rrtype, VALUE _rrclass) {
  DNSServiceRef *client;
  DNSServiceFlags flags;
  DNSServiceErrorType e;
  char *fullname;
  uint32_t interface;
  uint16_t rrtype;
  uint16_t rrclass;
  VALUE self;

  flags = (DNSServiceFlags)NUM2ULONG(_flags);
  interface = (uint32_t)NUM2ULONG(_interface);
  dnssd_utf8_cstr(_fullname, fullname);
  rrtype = NUM2UINT(_rrtype);
  rrclass = NUM2UINT(_rrclass);

  client = xcalloc(1, sizeof(DNSServiceRef));
  self = TypedData_Wrap_Struct(klass, &dnssd_service_type, client);
  rb_obj_call_init(self, 0, 0);

  e = DNSServiceQueryRecord(client, flags, interface, fullname, rrtype,
      rrclass, dnssd_service_query_record_reply, (void *)self);

  dnssd_check_error_code(e);

  return self;
}

static void DNSSD_API
dnssd_service_register_reply(DNSServiceRef client, DNSServiceFlags flags,
    DNSServiceErrorType e, const char *name, const char *type,
    const char *domain, void *context) {
  VALUE service, reply, argv[5];

  dnssd_check_error_code(e);

  service = (VALUE)context;

  argv[0] = service;
  argv[1] = ULONG2NUM(flags);
  argv[2] = rb_str_new2(name);
  rb_enc_associate(argv[2], rb_utf8_encoding());
  argv[3] = rb_str_new2(type);
  rb_enc_associate(argv[3], rb_utf8_encoding());
  argv[4] = rb_str_new2(domain);
  rb_enc_associate(argv[4], rb_utf8_encoding());

  reply = rb_class_new_instance(5, argv, cDNSSDReplyRegister);

  rb_funcall(service, dnssd_id_push, 1, reply);
}

/* call-seq:
 *   service._register(flags, interface, name, type, domain, host, port, text_record)
 *
 * Binding to DNSServiceRegister
 */

static VALUE
dnssd_service_register(VALUE klass, VALUE _flags, VALUE _interface, VALUE _name,
    VALUE _type, VALUE _domain, VALUE _host, VALUE _port, VALUE _text_record) {
  const char *name = NULL, *type, *host = NULL, *domain = NULL;
  uint16_t port;
  uint16_t txt_len = 0;
  char *txt_rec = NULL;
  DNSServiceFlags flags = 0;
  uint32_t interface = 0;
  DNSServiceRegisterReply callback = NULL;

  DNSServiceErrorType e;
  DNSServiceRef *client;
  VALUE self;

  if (!NIL_P(_name)) {
    Check_Type(_name, T_STRING);
    dnssd_utf8_cstr(_name, name);
  }

  Check_Type(_type, T_STRING);
  dnssd_utf8_cstr(_type, type);

  if (!NIL_P(_host)) {
    Check_Type(_host, T_STRING);
    dnssd_utf8_cstr(_host, host);
  }

  if (!NIL_P(_domain)) {
    Check_Type(_domain, T_STRING);
    dnssd_utf8_cstr(_domain, domain);
  }

  port = htons((uint16_t)NUM2UINT(_port));

  if (!NIL_P(_text_record)) {
    txt_rec = StringValuePtr(_text_record);
    txt_len = RSTRING_LEN(_text_record);
  }

  if (!NIL_P(_flags))
    flags = (DNSServiceFlags)NUM2ULONG(_flags);

  if (!NIL_P(_interface))
    interface = (uint32_t)NUM2ULONG(_interface);

  callback = dnssd_service_register_reply;

  client = xcalloc(1, sizeof(DNSServiceRef));
  self = TypedData_Wrap_Struct(cDNSSDServiceRegister, &dnssd_service_type, client);
  rb_obj_call_init(self, 0, 0);

  e = DNSServiceRegister(client, flags, interface, name, type,
      domain, host, port, txt_len, txt_rec, callback, (void*)self);

  dnssd_check_error_code(e);

  return self;
}

static void DNSSD_API
dnssd_service_resolve_reply(DNSServiceRef client, DNSServiceFlags flags,
    uint32_t interface, DNSServiceErrorType e, const char *name,
    const char *target, uint16_t port, uint16_t txt_len,
    const unsigned char *txt_rec, void *context) {
  VALUE service, reply, argv[7];

  dnssd_check_error_code(e);

  service = (VALUE)context;

  argv[0] = service;
  argv[1] = ULONG2NUM(flags);
  argv[2] = ULONG2NUM(interface);
  argv[3] = rb_str_new2(name);
  rb_enc_associate(argv[3], rb_utf8_encoding());
  argv[4] = rb_str_new2(target);
  rb_enc_associate(argv[4], rb_utf8_encoding());
  argv[5] = UINT2NUM(ntohs(port));
  argv[6] = rb_str_new((char *)txt_rec, txt_len);
  rb_enc_associate(argv[6], rb_utf8_encoding());

  reply = rb_class_new_instance(7, argv, cDNSSDReplyResolve);

  rb_funcall(service, dnssd_id_push, 1, reply);
}

/* call-seq:
 *   service._resolve(flags, interface, name, type, domain)
 *
 * Binding to DNSServiceResolve
 */

static VALUE
dnssd_service_resolve(VALUE klass, VALUE _flags, VALUE _interface, VALUE _name,
    VALUE _type, VALUE _domain) {
  const char *name, *type, *domain;
  DNSServiceFlags flags = 0;
  uint32_t interface = 0;
  VALUE self;

  DNSServiceErrorType e;
  DNSServiceRef *client;

  dnssd_utf8_cstr(_name, name);
  dnssd_utf8_cstr(_type, type);
  dnssd_utf8_cstr(_domain, domain);

  if (!NIL_P(_flags))
    flags = (uint32_t)NUM2ULONG(_flags);

  if (!NIL_P(_interface))
    interface = (uint32_t)NUM2ULONG(_interface);

  client = xcalloc(1, sizeof(DNSServiceRef));
  self = TypedData_Wrap_Struct(klass, &dnssd_service_type, client);
  rb_obj_call_init(self, 0, 0);

  e = DNSServiceResolve(client, flags, interface, name, type, domain,
      dnssd_service_resolve_reply, (void *)self);

  dnssd_check_error_code(e);

  return self;
}

void
Init_DNSSD_Service(void) {
  VALUE sDNSSDService;

  mDNSSD = rb_define_module("DNSSD");

  dnssd_id_join = rb_intern("join");
  dnssd_id_push = rb_intern("push");

  dnssd_iv_continue    = rb_intern("@continue");
  dnssd_iv_records     = rb_intern("@records");
  dnssd_iv_replies     = rb_intern("@replies");
  dnssd_iv_service     = rb_intern("@service");
  dnssd_iv_thread      = rb_intern("@thread");
  dnssd_iv_type        = rb_intern("@type");

  cDNSSDFlags           = rb_define_class_under(mDNSSD, "Flags", rb_cObject);
  cDNSSDRecord          = rb_define_class_under(mDNSSD, "Record", rb_cObject);
  cDNSSDService         = rb_define_class_under(mDNSSD, "Service", rb_cObject);
  cDNSSDServiceRegister = rb_define_class_under(cDNSSDService, "Register", cDNSSDService);
  cDNSSDTextRecord = rb_path2class("DNSSD::TextRecord");

  cDNSSDReplyAddrInfo    = rb_path2class("DNSSD::Reply::AddrInfo");
  cDNSSDReplyBrowse      = rb_path2class("DNSSD::Reply::Browse");
  cDNSSDReplyDomain      = rb_path2class("DNSSD::Reply::Domain");
  cDNSSDReplyQueryRecord = rb_path2class("DNSSD::Reply::QueryRecord");
  cDNSSDReplyRegister    = rb_path2class("DNSSD::Reply::Register");
  cDNSSDReplyResolve     = rb_path2class("DNSSD::Reply::Resolve");
  sDNSSDService = rb_singleton_class(cDNSSDService);

  rb_cSocket = rb_path2class("Socket");


  /* Maximum length for a domain name */
  rb_define_const(cDNSSDService, "MAX_DOMAIN_NAME",
      ULONG2NUM(kDNSServiceMaxDomainName));

  /* Maximum length for a service name */
  rb_define_const(cDNSSDService, "MAX_SERVICE_NAME",
      ULONG2NUM(kDNSServiceMaxServiceName));

#ifdef kDNSServiceProperty_DaemonVersion
  /* DaemonVersion property value */
  rb_define_const(cDNSSDService, "DaemonVersion",
      rb_str_new2(kDNSServiceProperty_DaemonVersion));
#endif

#ifdef HAVE_DNSSERVICEGETPROPERTY
  /* IPv4 protocol for #getaddrinfo */
  rb_define_const(cDNSSDService, "IPv4", ULONG2NUM(kDNSServiceProtocol_IPv4));

  /* IPv6 protocol for #getaddrinfo */
  rb_define_const(cDNSSDService, "IPv6", ULONG2NUM(kDNSServiceProtocol_IPv6));

  /* HACK the below are only used by NAT, fix with proper HAVE_ */

  /* TCP protocol for creating NAT port mappings */
  rb_define_const(cDNSSDService, "TCP", ULONG2NUM(kDNSServiceProtocol_TCP));

  /* UDP protocol for creating NAT port mappings */
  rb_define_const(cDNSSDService, "UDP", ULONG2NUM(kDNSServiceProtocol_UDP));
#endif

  rb_define_alloc_func(cDNSSDService, dnssd_service_s_allocate);
  rb_define_singleton_method(cDNSSDService, "fullname", dnssd_service_s_fullname, 3);

#ifdef HAVE_DNSSERVICEGETPROPERTY
  rb_define_singleton_method(cDNSSDService, "get_property", dnssd_service_s_get_property, 1);
#endif

  rb_define_private_method(cDNSSDService, "_stop", dnssd_service_stop, 0);

  rb_define_private_method(cDNSSDServiceRegister, "_add_record", dnssd_service_add_record, 4);
  rb_define_private_method(cDNSSDService, "ref_sock_fd", dnssd_ref_sock_fd, 0);
  rb_define_private_method(cDNSSDService, "process_result", dnssd_process_result, 0);

  /* private class methods */
  rb_define_private_method(sDNSSDService, "_browse", dnssd_service_browse, 4);
  rb_define_private_method(sDNSSDService, "_enumerate_domains", dnssd_service_enumerate_domains, 2);
#ifdef HAVE_DNSSERVICEGETADDRINFO
  rb_define_private_method(sDNSSDService, "_getaddrinfo", dnssd_service_getaddrinfo, 4);
#endif
  rb_define_private_method(sDNSSDService, "_query_record", dnssd_service_query_record, 5);
  rb_define_private_method(sDNSSDService, "_register", dnssd_service_register, 8);
  rb_define_private_method(sDNSSDService, "_resolve", dnssd_service_resolve, 5);

}
