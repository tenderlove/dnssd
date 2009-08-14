#include "dnssd.h"

static VALUE mDNSSD;
static VALUE cDNSSDAddrInfo;
static VALUE cDNSSDFlags;
static VALUE cDNSSDReply;
static VALUE cDNSSDService;
static VALUE cDNSSDTextRecord;
static VALUE rb_cSocket;

static ID dnssd_id_join;
static ID dnssd_id_push;

static ID dnssd_iv_continue;
static ID dnssd_iv_domain;
static ID dnssd_iv_interface;
static ID dnssd_iv_port;
static ID dnssd_iv_replies;
static ID dnssd_iv_target;
static ID dnssd_iv_text_record;
static ID dnssd_iv_thread;

/* HACK why is this a macro */
#define GetDNSSDService(obj, var) \
  do {\
    Check_Type(obj, T_DATA);\
    if (rb_obj_is_kind_of(obj, cDNSSDService) != Qtrue)\
      rb_raise(rb_eTypeError,\
          "wrong argument type %s (expected DNSSD::Service)",\
          rb_class2name(CLASS_OF(obj)));\
    Data_Get_Struct(obj, DNSServiceRef, var);\
  } while (0)

static void
dnssd_service_callback(VALUE self, VALUE reply) {
  VALUE replies = rb_ivar_get(self, dnssd_iv_replies);

  rb_funcall(replies, dnssd_id_push, 1, reply);
}

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

static VALUE
create_fullname(const char *name, const char *regtype,
    const char *domain) {
  char buffer[kDNSServiceMaxDomainName];

  if (DNSServiceConstructFullName(buffer, name, regtype, domain)) {
    static const char msg[] = "could not construct full service name";
    rb_raise(rb_eArgError, msg);
  }

  buffer[kDNSServiceMaxDomainName - 1] = '\000'; /* just in case */
  return rb_str_new2(buffer);
}

static VALUE
reply_new(VALUE service, DNSServiceFlags flags) {
  return rb_funcall(cDNSSDReply, rb_intern("from_service"), 2, service,
                    UINT2NUM(flags));
}

static void
reply_set_interface(VALUE self, uint32_t interface) {
  VALUE if_value;
  char buffer[IF_NAMESIZE];

  if (if_indextoname(interface, buffer)) {
    if_value = rb_str_new2(buffer);
  } else {
    if_value = ULONG2NUM(interface);
  }

  rb_ivar_set(self, dnssd_iv_interface, if_value);
}

/*
 * call-seq:
 *    DNSSD::Service.fullname(name, type, domain) => String
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
dnssd_service_s_fullname(VALUE klass, VALUE name, VALUE type, VALUE domain) {
  return create_fullname(StringValueCStr(name), StringValueCStr(type),
      StringValueCStr(domain));
}

/*
 * call-seq:
 *   service.get_property(property) => result
 *
 * Binding for DNSServiceGetProperty.  The only property currently supported in
 * DNSSD is DNSSD::Service::DaemonVersion
 */
static VALUE
dnssd_service_s_get_property(VALUE klass, VALUE property) {
  uint32_t result = 0;
  uint32_t size = sizeof(result);
  DNSServiceErrorType e;

  e = DNSServiceGetProperty(StringValueCStr(property), (void *)&result, &size);

  dnssd_check_error_code(e);

  /* as of this writing only a uint32_t will be returned */
  return ULONG2NUM(result);
}

static VALUE
dnssd_service_s_allocate(VALUE klass) {
  DNSServiceRef *client = ALLOC(DNSServiceRef);

  *client = NULL;

  return Data_Wrap_Struct(klass, 0, dnssd_service_free, client);
}

/*
 * call-seq:
 *    service.started? => true or false
 *
 * Returns true if the service has been started.
 */

static VALUE
dnssd_service_started_p(VALUE service) {
  DNSServiceRef *client = (DNSServiceRef*)RDATA(service)->data;
  if (client)
    return (*client) == NULL ? Qfalse : Qtrue;

  return Qtrue;
}

/*
 * call-seq:
 *    service.stopped? => true or false
 *
 * Returns true if the service has been stopped.
 */

static VALUE
dnssd_service_stopped_p(VALUE service) {
  DNSServiceRef *client = (DNSServiceRef*)RDATA(service)->data;

  if (client)
    return (*client) == NULL ? Qtrue : Qfalse;

  return Qtrue;
}

/*
 * call-seq:
 *    service.stop => service
 *
 * Stops the service, closing the underlying socket and killing the underlying
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
  VALUE thread;
  DNSServiceRef *client = (DNSServiceRef*)RDATA(self)->data;

  /* set to null right away for a bit more thread safety */
  RDATA(self)->data = NULL;

  if (client == NULL)
    rb_raise(eDNSSDError, "service is already stopped");

  thread = rb_ivar_get(self, dnssd_iv_thread);
  rb_ivar_set(self, dnssd_iv_continue, Qfalse);

  if (!NIL_P(thread) && thread != rb_thread_current()) {
    rb_thread_run(thread);
    rb_funcall(thread, dnssd_id_join, 0);
  }

  dnssd_service_free_client(client);

  return self;
}

/* Binding to DNSServiceProcessResult
 *
 * When run with a single thread _process will block.
 *
 * _process works intelligently with threads.  If a service is waiting on data
 * from the daemon in a thread you can force _process to abort by setting
 * @continue to false and running the thread.
 */

static VALUE
dnssd_service_process(VALUE self) {
  DNSServiceRef *client;

  GetDNSSDService(self, client);

  if (client == NULL) {
    /* looks like this thread has already been stopped */
    return Qnil;
  }

  rb_thread_wait_fd(DNSServiceRefSockFD(*client));

  if (rb_ivar_get(self, dnssd_iv_continue) == Qfalse)
    return Qnil;

  DNSServiceErrorType e = DNSServiceProcessResult(*client);
  dnssd_check_error_code(e);

  return self;
}

static void DNSSD_API
dnssd_service_browse_reply(DNSServiceRef client, DNSServiceFlags flags,
    uint32_t interface, DNSServiceErrorType e, const char *name,
    const char *type, const char *domain, void *context) {
  VALUE service, reply;

  dnssd_check_error_code(e);

  service = (VALUE)context;

  reply = reply_new(service, flags);
  reply_set_interface(reply, interface);
  rb_funcall(reply, rb_intern("set_names"), 3, rb_str_new2(name),
      rb_str_new2(type), rb_str_new2(domain));

  dnssd_service_callback(service, reply);
}

/* Binding to DNSServiceBrowse
 */

static VALUE
dnssd_service_browse(VALUE self, VALUE _type, VALUE _domain, VALUE _flags,
    VALUE _interface) {
  const char *type;
  const char *domain = NULL;
  DNSServiceFlags flags = 0;
  uint32_t interface = 0;

  DNSServiceErrorType e;
  DNSServiceRef *client;

  type = StringValueCStr(_type);

  if (!NIL_P(_domain))
    domain = StringValueCStr(_domain);

  if (!NIL_P(_flags))
    flags = (DNSServiceFlags)NUM2ULONG(_flags);

  if (!NIL_P(_interface))
    interface = NUM2ULONG(_interface);

  GetDNSSDService(self, client);

  e = DNSServiceBrowse(client, flags, interface, type, domain,
      dnssd_service_browse_reply, (void *)self);

  dnssd_check_error_code(e);

  return self;
}

static void DNSSD_API
dnssd_service_enumerate_domains_reply(DNSServiceRef client,
    DNSServiceFlags flags, uint32_t interface, DNSServiceErrorType e,
    const char *domain, void *context) {
  VALUE service, reply;

  dnssd_check_error_code(e);

  service = (VALUE)context;

  reply = reply_new(service, flags);
  reply_set_interface(reply, interface);
  rb_ivar_set(reply, dnssd_iv_domain, rb_str_new2(domain));

  dnssd_service_callback(service, reply);
}

/* Binding to DNSServiceEnumerateDomains
 */

static VALUE
dnssd_service_enumerate_domains(VALUE self, VALUE _flags, VALUE _interface) {
  DNSServiceFlags flags = 0;
  uint32_t interface = 0;

  DNSServiceErrorType e;
  DNSServiceRef *client;

  if (!NIL_P(_flags))
    flags = (DNSServiceFlags)NUM2ULONG(_flags);

  if (!NIL_P(_interface))
    interface = NUM2ULONG(_interface);

  GetDNSSDService(self, client);

  e = DNSServiceEnumerateDomains(client, flags, interface,
      dnssd_service_enumerate_domains_reply, (void *)self);

  dnssd_check_error_code(e);

  return self;
}

static void DNSSD_API
dnssd_service_getaddrinfo_reply(DNSServiceRef client, DNSServiceFlags flags,
    uint32_t interface, DNSServiceErrorType e, const char *host,
    const struct sockaddr *address, uint32_t ttl, void *context) {
  VALUE service, reply, argv[5];

  dnssd_check_error_code(e);

  service = (VALUE)context;

  argv[0] = rb_str_new2(host);
  argv[1] = rb_funcall(rb_cSocket, rb_intern("unpack_sockaddr_in"), 1,
      rb_str_new((char *)address, SIN_LEN((struct sockaddr_in*)address)));
  argv[2] = ULONG2NUM(ttl);
  if (interface > 0) {
    argv[3] = rb_funcall(mDNSSD, rb_intern("interface_name"), 1,
        UINT2NUM(interface));
  } else {
    argv[3] = UINT2NUM(interface);
  }
  argv[4] = rb_funcall(cDNSSDFlags, rb_intern("new"), 1, UINT2NUM(flags));

  reply = rb_class_new_instance(5, argv, cDNSSDAddrInfo);

  dnssd_service_callback(service, reply);
}

static VALUE
dnssd_service_getaddrinfo(VALUE self, VALUE _host, VALUE _protocol,
    VALUE _flags, VALUE _interface) {
  DNSServiceFlags flags = 0;
  uint32_t interface = 0;
  DNSServiceProtocol protocol = 0;
  const char *host;

  DNSServiceErrorType e;
  DNSServiceRef *client;

  host = StringValueCStr(_host);

  protocol = (DNSServiceProtocol)NUM2ULONG(_protocol);

  if (!NIL_P(_flags))
    flags = (DNSServiceFlags)NUM2ULONG(_flags);

  if (!NIL_P(_interface))
    interface = NUM2ULONG(_interface);

  GetDNSSDService(self, client);

  e = DNSServiceGetAddrInfo(client, flags, interface, protocol, host,
      dnssd_service_getaddrinfo_reply, (void *)self);

  dnssd_check_error_code(e);

  return self;
}

static void DNSSD_API
dnssd_service_register_reply(DNSServiceRef client, DNSServiceFlags flags,
    DNSServiceErrorType e, const char *name, const char *type,
    const char *domain, void *context) {
  VALUE service, reply;

  dnssd_check_error_code(e);

  service = (VALUE)context;

  reply = reply_new(service, flags);
  rb_funcall(reply, rb_intern("set_names"), 3, rb_str_new2(name),
      rb_str_new2(type), rb_str_new2(domain));

  dnssd_service_callback(service, reply);
}

/* Binding to DNSServiceRegister
 */

static VALUE
dnssd_service_register(VALUE self, VALUE _name, VALUE _type, VALUE _domain,
    VALUE _host, VALUE _port, VALUE _text_record, VALUE _flags,
    VALUE _interface) {
  const char *name, *type, *host = NULL, *domain = NULL;
  uint16_t port;
  uint16_t txt_len = 0;
  char *txt_rec = NULL;
  DNSServiceFlags flags = 0;
  uint32_t interface = 0;

  DNSServiceErrorType e;
  DNSServiceRef *client;

  name = StringValueCStr(_name);
  type = StringValueCStr(_type);

  if (!NIL_P(_host))
    host = StringValueCStr(_host);

  if (!NIL_P(_domain))
    domain = StringValueCStr(_domain);

  port = htons((uint16_t)NUM2UINT(_port));

  if (!NIL_P(_text_record)) {
    txt_rec = RSTRING_PTR(_text_record);
    txt_len = RSTRING_LEN(_text_record);
  }

  if (!NIL_P(_flags))
    flags = (DNSServiceFlags)NUM2ULONG(_flags);

  if (!NIL_P(_interface))
    interface = NUM2ULONG(_interface);

  GetDNSSDService(self, client);

  e = DNSServiceRegister(client, flags, interface, name, type,
      domain, host, port, txt_len, txt_rec, dnssd_service_register_reply,
      (void*)self);

  dnssd_check_error_code(e);

  return self;
}

static void DNSSD_API
dnssd_service_resolve_reply(DNSServiceRef client, DNSServiceFlags flags,
    uint32_t interface, DNSServiceErrorType e, const char *name,
    const char *target, uint16_t port, uint16_t txt_len,
    const unsigned char *txt_rec, void *context) {
  VALUE service, reply, text_record, text_record_str;

  dnssd_check_error_code(e);

  service = (VALUE)context;

  reply = reply_new(service, flags);

  reply_set_interface(reply, interface);
  rb_funcall(reply, rb_intern("set_fullname"), 1, rb_str_new2(name));
  rb_ivar_set(reply, dnssd_iv_target, rb_str_new2(target));
  rb_ivar_set(reply, dnssd_iv_port, UINT2NUM(ntohs(port)));

  text_record_str = rb_str_new((char *)txt_rec, txt_len);
  text_record = rb_class_new_instance(1, &text_record_str, cDNSSDTextRecord);
  rb_ivar_set(reply, dnssd_iv_text_record, text_record);

  dnssd_service_callback(service, reply);
}

/* Binding to DNSServiceResolve
 */

static VALUE
dnssd_service_resolve(VALUE self, VALUE _name, VALUE _type, VALUE _domain,
    VALUE _flags, VALUE _interface) {
  const char *name, *type, *domain;
  DNSServiceFlags flags = 0;
  uint32_t interface = 0;

  DNSServiceErrorType e;
  DNSServiceRef *client;

  name = StringValueCStr(_name);
  type = StringValueCStr(_type);
  domain = StringValueCStr(_domain);

  if (!NIL_P(_flags))
    flags = NUM2ULONG(_flags);

  if (!NIL_P(_interface))
    interface = NUM2ULONG(_interface);

  GetDNSSDService(self, client);

  e = DNSServiceResolve(client, flags, interface, name, type, domain,
      dnssd_service_resolve_reply, (void *)self);

  dnssd_check_error_code(e);

  return self;
}

void
Init_DNSSD_Service(void) {
  mDNSSD = rb_define_module("DNSSD");

  dnssd_id_join = rb_intern("join");
  dnssd_id_push = rb_intern("push");

  dnssd_iv_continue    = rb_intern("@continue");
  dnssd_iv_domain      = rb_intern("@domain");
  dnssd_iv_interface   = rb_intern("@interface");
  dnssd_iv_port        = rb_intern("@port");
  dnssd_iv_replies     = rb_intern("@replies");
  dnssd_iv_target      = rb_intern("@target");
  dnssd_iv_text_record = rb_intern("@text_record");
  dnssd_iv_thread      = rb_intern("@thread");

  cDNSSDAddrInfo   = rb_path2class("DNSSD::AddrInfo");
  cDNSSDFlags      = rb_define_class_under(mDNSSD, "Flags", rb_cObject);
  cDNSSDReply      = rb_define_class_under(mDNSSD, "Reply", rb_cObject);
  cDNSSDService    = rb_define_class_under(mDNSSD, "Service", rb_cObject);
  cDNSSDTextRecord = rb_define_class_under(mDNSSD, "TextRecord", rb_cObject);
  
  rb_cSocket = rb_path2class("Socket");

  rb_define_const(cDNSSDService, "MAX_DOMAIN_NAME",
      ULONG2NUM(kDNSServiceMaxDomainName));
  rb_define_const(cDNSSDService, "MAX_SERVICE_NAME",
      ULONG2NUM(kDNSServiceMaxServiceName));
  rb_define_const(cDNSSDService, "DaemonVersion",
      rb_str_new2(kDNSServiceProperty_DaemonVersion));

  rb_define_const(cDNSSDService, "IPv4", ULONG2NUM(kDNSServiceProtocol_IPv4));
  rb_define_const(cDNSSDService, "IPv6", ULONG2NUM(kDNSServiceProtocol_IPv6));

  rb_define_const(cDNSSDService, "UDP", ULONG2NUM(kDNSServiceProtocol_UDP));
  rb_define_const(cDNSSDService, "TCP", ULONG2NUM(kDNSServiceProtocol_TCP));

  rb_define_alloc_func(cDNSSDService, dnssd_service_s_allocate);
  rb_define_singleton_method(cDNSSDService, "fullname", dnssd_service_s_fullname, 3);

  rb_define_singleton_method(cDNSSDService, "get_property", dnssd_service_s_get_property, 1);

  rb_define_method(cDNSSDService, "started?", dnssd_service_started_p, 0);

  rb_define_method(cDNSSDService, "stop", dnssd_service_stop, 0);
  rb_define_method(cDNSSDService, "stopped?", dnssd_service_stopped_p, 0);

  rb_define_method(cDNSSDService, "_browse", dnssd_service_browse, 4);
  rb_define_method(cDNSSDService, "_enumerate_domains", dnssd_service_enumerate_domains, 2);
  rb_define_method(cDNSSDService, "_getaddrinfo", dnssd_service_getaddrinfo, 4);
  rb_define_method(cDNSSDService, "_register", dnssd_service_register, 8);
  rb_define_method(cDNSSDService, "_resolve", dnssd_service_resolve, 5);

  rb_define_method(cDNSSDService, "_process", dnssd_service_process, 0);
}

