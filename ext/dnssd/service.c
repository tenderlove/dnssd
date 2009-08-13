#include "dnssd.h"
#include <assert.h>

#ifndef DNSSD_API
  /* define as nothing if not defined in Apple's "dns_sd.h" header  */
  #define DNSSD_API
#endif

static VALUE cDNSSDReply;
static VALUE cDNSSDService;
static VALUE cDNSSDTextRecord;

static ID dnssd_id_call;
static ID dnssd_id_encode;
static ID dnssd_id_to_i;
static ID dnssd_id_to_str;

static ID dnssd_iv_block;
static ID dnssd_iv_domain;
static ID dnssd_iv_interface;
static ID dnssd_iv_port;
static ID dnssd_iv_result;
static ID dnssd_iv_service;
static ID dnssd_iv_target;
static ID dnssd_iv_text_record;
static ID dnssd_iv_thread;

#define IsDNSSDService(obj) (rb_obj_is_kind_of(obj, cDNSSDService) == Qtrue)
#define GetDNSSDService(obj, var) \
  do {\
    assert(IsDNSSDService(obj));\
    Data_Get_Struct(obj, DNSServiceRef, var);\
  } while (0)

static DNSServiceFlags
dnssd_to_flags(VALUE obj) {
  return (DNSServiceFlags)NUM2ULONG(rb_funcall(obj, dnssd_id_to_i, 0));
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

static VALUE
text_record_new(VALUE text_record) {
  return rb_funcall(cDNSSDTextRecord, rb_intern("new"), 1, text_record);
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

static VALUE
reply_from_browse(VALUE service, DNSServiceFlags flags,
    uint32_t interface, const char *name, const char *regtype,
    const char *domain) {
  VALUE self = reply_new(service, flags);
  reply_set_interface(self, interface);
  rb_funcall(self, rb_intern("set_names"), 3, rb_str_new2(name),
      rb_str_new2(regtype), rb_str_new2(domain));
  return self;
}

static VALUE
reply_from_domain_enum(VALUE service, DNSServiceFlags flags,
    uint32_t interface, const char *domain) {
  VALUE self = reply_new(service, flags);
  reply_set_interface(self, interface);
  rb_ivar_set(self, dnssd_iv_domain, rb_str_new2(domain));
  return self;
}

static VALUE
reply_from_register(VALUE service, DNSServiceFlags flags,
    const char *name, const char *regtype, const char *domain) {
  VALUE self = reply_new(service, flags);
  rb_funcall(self, rb_intern("set_names"), 3, rb_str_new2(name),
      rb_str_new2(regtype), rb_str_new2(domain));
  /* HACK */
  /* See HACK in dnssd_service.c */
  rb_ivar_set(self, dnssd_iv_interface,
      rb_ivar_get(service, dnssd_iv_interface));
  rb_ivar_set(self, dnssd_iv_port, rb_ivar_get(service, dnssd_iv_port));
  rb_ivar_set(self, dnssd_iv_text_record,
      rb_ivar_get(service, dnssd_iv_text_record));
  /********/
  return self;
}

static VALUE
reply_from_resolve(VALUE service, DNSServiceFlags flags, uint32_t
    interface, const char *fullname, const char *host_target, uint16_t
    opaqueport, uint16_t txt_len, const char *txt_rec) {
  uint16_t port = ntohs(opaqueport);
  VALUE self = reply_new(service, flags);

  reply_set_interface(self, interface);
  rb_funcall(self, rb_intern("set_fullname"), 1, rb_str_new2(fullname));
  rb_ivar_set(self, dnssd_iv_target, rb_str_new2(host_target));
  rb_ivar_set(self, dnssd_iv_port, UINT2NUM(port));
  rb_ivar_set(self, dnssd_iv_text_record,
      text_record_new(rb_str_new(txt_rec, txt_len)));

  return self;
}

static void
dnssd_callback(VALUE service, VALUE reply) {
  VALUE block = rb_ivar_get(service, dnssd_iv_block);
  VALUE result = Qnil;

  if (!NIL_P(block))
    result = rb_funcall2(block, dnssd_id_call, 1, &reply);

  rb_ivar_set(service, dnssd_iv_result, result);
}

static const char *
dnssd_get_domain(VALUE service_domain) {
  const char *domain = StringValueCStr(service_domain);
  /* max len including the null terminator and trailing '.' */
  if (RSTRING_LEN(service_domain) >= kDNSServiceMaxDomainName - 1)
    rb_raise(rb_eArgError, "domain name string too large");
  return domain;
}

static uint32_t
dnssd_get_interface_index(VALUE interface) {
  /* if the interface is a string then convert it to the interface index */
  if (rb_respond_to(interface, dnssd_id_to_str)) {
    return if_nametoindex(StringValueCStr(interface));
  } else {
    return (uint32_t)NUM2ULONG(interface);
  }
}

/*
 * call-seq:
 *    DNSSD::Service.new => raises a RuntimeError
 *
 * Services can only be instantiated using ::enumerate_domains, ::browse,
 * ::register, and ::resolve.
 */

static VALUE
dnssd_service_new(int argc, VALUE *argv, VALUE klass) {
  dnssd_instantiation_error(rb_class2name(klass));
  return Qnil;
}

static void
dnssd_service_free_client(DNSServiceRef *client) {
  DNSServiceRefDeallocate(*client);
  free(client); /* free the pointer */
}

static void
dnssd_service_free(void *ptr) {
  DNSServiceRef *client = (DNSServiceRef*)ptr;
  if (client) {
    /* client will be non-null only if client has not been deallocated */
    dnssd_service_free_client(client);
  }
}

static VALUE
dnssd_service_alloc(VALUE block) {
  DNSServiceRef *client = ALLOC(DNSServiceRef);
  VALUE service = Data_Wrap_Struct(cDNSSDService, 0, dnssd_service_free, client);
  rb_ivar_set(service, dnssd_iv_block, block);
  rb_ivar_set(service, dnssd_iv_thread, Qnil);
  rb_ivar_set(service, dnssd_iv_result, Qnil);
  return service;
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
  return client == NULL ? Qtrue : Qfalse;
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
dnssd_service_stop(VALUE service) {
  VALUE thread;
  DNSServiceRef *client = (DNSServiceRef*)RDATA(service)->data;

  /* set to null right away for a bit more thread safety */
  RDATA(service)->data = NULL;

  if (client == NULL)
    rb_raise(eDNSSDError, "service is already stopped");

  dnssd_service_free_client(client);

  thread = rb_ivar_get(service, dnssd_iv_thread);
  rb_ivar_set(service, dnssd_iv_block, Qnil);
  rb_ivar_set(service, dnssd_iv_thread, Qnil);

  if (!NIL_P(thread)) {
    /* will raise error if thread is not a Ruby Thread */
    rb_thread_kill(thread);
  }

  return service;
}

/* stop the service only if it is still running */

static VALUE
dnssd_service_stop2(VALUE service) {
  if (RTEST(dnssd_service_stopped_p(service))) {
    return service;
  }
  return dnssd_service_stop(service);
}

static VALUE
dnssd_service_process(VALUE service) {
  DNSServiceRef *client;

  GetDNSSDService(service, client);

  if (client == NULL) {
    /* looks like this thread has already been stopped */
    return Qnil;
  }

  rb_thread_wait_fd(DNSServiceRefSockFD(*client));

  DNSServiceErrorType e = DNSServiceProcessResult(*client);
  dnssd_check_error_code(e);

  /* return the result from the processing */
  return rb_ivar_get(service, dnssd_iv_result);
}

static VALUE
dnssd_service_start(VALUE service) {
  return rb_ensure(dnssd_service_process, service, dnssd_service_stop2,
      service);
}

static VALUE
dnssd_service_start_in_thread(VALUE service) {
  /* race condition - service.@block could be called before the service's
   * @thread is set and if the block calls #stop will raise an error, even
   * though the service has been started and is running. */

  VALUE thread = rb_thread_create(dnssd_service_process, (void *)service);
  rb_ivar_set(service, dnssd_iv_thread, thread);

  /* !! IMPORTANT: prevents premature garbage collection of the service, this
   * way the thread holds a reference to the service and the service gets
   * marked as long as the thread is running.  Running threads are always
   * marked by Ruby. !! */

  rb_ivar_set(thread, dnssd_iv_service, service);
  return service;
}

static void DNSSD_API
dnssd_domain_enum_reply(DNSServiceRef sdRef, DNSServiceFlags flags,
    uint32_t interface_index, DNSServiceErrorType e,
    const char *domain, void *context) {
  VALUE service;
  /* other parameters are undefined if errorCode != 0 */
  dnssd_check_error_code(e);
  service = (VALUE)context;
  dnssd_callback(service,
      reply_from_domain_enum(service, flags, interface_index, domain));
}

static VALUE
sd_enumerate_domains(int argc, VALUE *argv, VALUE service) {
  VALUE tmp_flags, interface;

  DNSServiceFlags flags = 0;
  uint32_t interface_index = 0;

  DNSServiceErrorType e;
  DNSServiceRef *client;

  rb_scan_args(argc, argv, "02", &tmp_flags, &interface);

  /* optional parameters */
  if (!NIL_P(tmp_flags))
    flags = dnssd_to_flags(tmp_flags);

  if (!NIL_P(interface))
    interface_index = dnssd_get_interface_index(interface);

  GetDNSSDService(service, client);
  e = DNSServiceEnumerateDomains(client, flags, interface_index,
      dnssd_domain_enum_reply, (void *)service);
  dnssd_check_error_code(e);
  return service;
}

/*
 * call-seq:
 *    DNSSD.enumerate_domains!(flags, interface) { |reply| } => service
 *
 * Synchronously enumerate domains available for browsing and registration.
 * For each domain found a DNSSD::Reply object is passed to block with #domain
 * set to the enumerated domain.
 *
 *   available_domains = []
 *   
 *   timeout(2) do
 *     DNSSD.enumerate_domains! do |r|
 *       available_domains << r.domain
 *     end
 *   rescue TimeoutError
 *   end
 *   
 *   puts available_domains.inspect
 */

static VALUE
dnssd_enumerate_domains_bang(int argc, VALUE * argv, VALUE self) {
  return dnssd_service_start(
      sd_enumerate_domains(argc, argv, dnssd_service_alloc(rb_block_proc())));
}

/*
 * call-seq:
 *    DNSSD.enumerate_domains(flags, interface) { |reply| } => serivce
 *
 * Asynchronously enumerate domains available for browsing and registration.
 * For each domain found a DNSSD::DomainEnumReply object is passed to block.
 * The returned +service+ can be used to control when to stop enumerating
 * domains (see DNSSD::Service#stop).
 *
 *   domains = []
 *   
 *   s = DNSSD.enumerate_domains do |d|
 *     domains << d.domain
 *   end
 *   
 *   sleep(0.2)
 *   s.stop
 *   p domains
 */

static VALUE
dnssd_enumerate_domains(int argc, VALUE * argv, VALUE self) {
  return dnssd_service_start_in_thread(
      sd_enumerate_domains(argc, argv, dnssd_service_alloc(rb_block_proc())));
}

static void DNSSD_API
dnssd_browse_reply(DNSServiceRef client, DNSServiceFlags flags,
    uint32_t interface_index, DNSServiceErrorType e,
    const char *name, const char *type,
    const char *domain, void *context) {
  VALUE service;
  /* other parameters are undefined if errorCode != 0 */
  dnssd_check_error_code(e);
  service = (VALUE)context;
  dnssd_callback(service,
      reply_from_browse(service, flags, interface_index, name, type, domain));
}

static VALUE
sd_browse(int argc, VALUE *argv, VALUE service) {
  VALUE type, domain, tmp_flags, interface;

  const char *type_str;
  const char *domain_str = NULL;
  DNSServiceFlags flags = 0;
  uint32_t interface_index = 0;

  DNSServiceErrorType e;
  DNSServiceRef *client;

  rb_scan_args(argc, argv, "13", &type, &domain, &tmp_flags, &interface);
  type_str = StringValueCStr(type);

  /* optional parameters */
  if (!NIL_P(domain))
    domain_str = dnssd_get_domain(domain);

  if (!NIL_P(tmp_flags))
    flags = dnssd_to_flags(tmp_flags);

  if (!NIL_P(interface))
    interface_index = dnssd_get_interface_index(interface);

  GetDNSSDService(service, client);
  e = DNSServiceBrowse(client, flags, interface_index, type_str, domain_str,
      dnssd_browse_reply, (void *)service);
  dnssd_check_error_code(e);
  return service;
}

/*
 * call-seq:
 *    DNSSD.browse!(type, domain, flags, interface) { |reply| } => service
 *
 * Synchronously browse for services.
 *
 * +domain+ is optional
 *
 * +flags+ is 0 by default
 *
 * +interface+ is DNSSD::InterfaceAny by default
 *
 * For each service found a DNSSD::Reply object is passed to block.
 *
 *   timeout 6 do
 *     DNSSD.browse! '_http._tcp' do |r|
 *       puts "found: #{r.name}"
 *     end
 *   rescue TimeoutError
 *   end
 *
 */

static VALUE
dnssd_browse_bang(int argc, VALUE * argv, VALUE self) {
  return dnssd_service_start(
      sd_browse(argc, argv, dnssd_service_alloc(rb_block_proc())));
}

/*
 * call-seq:
 *    DNSSD.browse(type, domain, flags, interface) { |reply| } => service
 *
 * Asynchronously browse for services.
 *
 * +domain+ is optional
 *
 * +flags+ is 0 by default
 *
 * +interface+ is DNSSD::InterfaceAny by default
 *
 * For each service found a DNSSD::BrowseReply object is passed to block.
 *
 * The returned service can be used to control when to stop browsing for
 * services (see DNSSD::Service#stop).
 *
 *   s = DNSSD.browse '_http._tcp' do |b|
 *     puts "found: #{b.name}"
 *   end
 *   
 *   s.stop
 */

static VALUE
dnssd_browse(int argc, VALUE * argv, VALUE self) {
  return dnssd_service_start_in_thread(
      sd_browse(argc, argv, dnssd_service_alloc(rb_block_proc())));
}

static void DNSSD_API
dnssd_register_reply(DNSServiceRef client, DNSServiceFlags flags,
    DNSServiceErrorType e,
    const char *name, const char *regtype,
    const char *domain, void *context) {
  VALUE service;
  /* other parameters are undefined if errorCode != 0 */
  dnssd_check_error_code(e);
  service = (VALUE)context;
  dnssd_callback(service,
      reply_from_register(service, flags, name, regtype, domain));
}

static VALUE
sd_register(int argc, VALUE *argv, VALUE service) {
  VALUE name, type, domain, port, text_record, tmp_flags, interface;

  const char *name_str, *type_str, *domain_str = NULL;
  uint16_t opaqueport;
  uint16_t txt_len = 0;
  char *txt_rec = NULL;
  DNSServiceFlags flags = 0;
  uint32_t interface_index = 0;

  DNSServiceErrorType e;
  DNSServiceRef *client;

  rb_scan_args(argc, argv, "43", &name, &type, &domain, &port,
      &text_record, &tmp_flags, &interface);

  /* required parameters */
  name_str = StringValueCStr(name);
  type_str = StringValueCStr(type);

  if (!NIL_P(domain))
    domain_str = dnssd_get_domain(domain);

  /* convert from host to net byte order */
  opaqueport = htons((uint16_t)NUM2UINT(port));

  /* optional parameters */
  if (!NIL_P(text_record)) {
    text_record = rb_funcall(text_record, dnssd_id_encode, 0);
    txt_rec = RSTRING_PTR(text_record);
    txt_len = RSTRING_LEN(text_record);
  }

  if (!NIL_P(tmp_flags))
    flags = dnssd_to_flags(tmp_flags);

  if(!NIL_P(interface))
    interface_index = dnssd_get_interface_index(interface);

  GetDNSSDService(service, client);

  /* HACK */
  rb_ivar_set(service, dnssd_iv_interface, interface);
  rb_ivar_set(service, dnssd_iv_port, port);
  rb_ivar_set(service, dnssd_iv_text_record, text_record);
  /********/

  e = DNSServiceRegister(client, flags, interface_index, name_str, type_str,
      domain_str, NULL, opaqueport, txt_len, txt_rec, dnssd_register_reply,
      (void*)service);
  dnssd_check_error_code(e);
  return service;
}

/*
 * call-seq:
 *   DNSSD.register!(name, type, domain, port, text_record, flags, interface) { |reply| } => obj
 *
 * Synchronously register a service.  A DNSSD::Reply object is passed to the
 * optional block when the registration completes.
 *
 * +text_record+ defaults to nil, +flags+ defaults to 0 and +interface+
 * defaults to DNSSD::InterfaceAny.
 *
 *   DNSSD.register! "My Files", "_http._tcp", nil, 8080 do |r|
 *     puts "successfully registered: #{r.inspect}"
 *   end
 */

static VALUE
dnssd_register_bang(int argc, VALUE * argv, VALUE self) {
  VALUE block = Qnil;

  if (rb_block_given_p())
    block = rb_block_proc();

  return dnssd_service_start(
      sd_register(argc, argv, dnssd_service_alloc(block)));
}

/*
 * call-seq:
 *   DNSSD.register(name, type, domain, port, text_record, flags, interface) { |reply| } => obj
 *
 * Asynchronously register a service.  A DNSSD::Reply object is passed to the
 * optional block when the registration completes.
 *
 * +text_record+ defaults to nil, +flags+ defaults to 0 and +interface+
 * defaults to DNSSD::InterfaceAny.
 *
 * The returned service can be used to control when to stop the service.
 *
 *   # Start a webserver and register it using DNS Service Discovery
 *   require 'dnssd'
 *   require 'webrick'
 *   
 *   web_s = WEBrick::HTTPServer.new :Port => 8080, :DocumentRoot => Dir.pwd
 *   dns_s = DNSSD.register "My Files", "_http._tcp", nil, 8080 do |r|
 *     warn "successfully registered: #{r.inspect}"
 *   end
 *   
 *   trap "INT" do dns_s.stop; web_s.shutdown end
 *   web_s.start
 */

static VALUE
dnssd_register(int argc, VALUE * argv, VALUE self) {
  VALUE block = Qnil;

  if (rb_block_given_p())
    block = rb_block_proc();

  return dnssd_service_start_in_thread(
      sd_register(argc, argv, dnssd_service_alloc(block)));
}

static void DNSSD_API
dnssd_resolve_reply(DNSServiceRef client, DNSServiceFlags flags,
    uint32_t interface_index, DNSServiceErrorType e,
    const char *fullname, const char *host_target,
    uint16_t opaqueport, uint16_t txt_len,
    const char *txt_rec, void *context) {
  VALUE service;
  /* other parameters are undefined if errorCode != 0 */
  dnssd_check_error_code(e);
  service = (VALUE)context;
  dnssd_callback(service,
      reply_from_resolve(service, flags, interface_index, fullname,
        host_target, opaqueport, txt_len, txt_rec));
}

static VALUE
sd_resolve(int argc, VALUE *argv, VALUE service) {
  VALUE reply = Qnil;
  VALUE name, type, domain, tmp_flags, interface;

  const char *name_str, *type_str, *domain_str;
  DNSServiceFlags flags = 0;
  uint32_t interface_index = 0;

  DNSServiceErrorType err;
  DNSServiceRef *client;

  if (argc == 1 &&
      RTEST(rb_funcall(cDNSSDReply, rb_intern("==="), 1, argv[0]))) {
    reply = argv[0];
    name      = rb_funcall(reply, rb_intern("name"),      0);
    type      = rb_funcall(reply, rb_intern("type"),      0);
    domain    = rb_funcall(reply, rb_intern("domain"),    0);
    tmp_flags = rb_funcall(reply, rb_intern("flags"),     0);
    interface = rb_funcall(reply, rb_intern("interface"), 0);
  } else {
    rb_scan_args(argc, argv, "32", &name, &type, &domain, &tmp_flags, &interface);
  }

  /* required parameters */
  name_str = StringValueCStr(name);
  type_str = StringValueCStr(type);
  domain_str = dnssd_get_domain(domain);

  /* optional parameters */
  if (!NIL_P(tmp_flags))
    flags = dnssd_to_flags(tmp_flags);

  if (!NIL_P(interface))
    interface_index = dnssd_get_interface_index(interface);

  GetDNSSDService(service, client);
  err = DNSServiceResolve(client, flags, interface_index, name_str, type_str,
      domain_str, (DNSServiceResolveReply)dnssd_resolve_reply,
      (void *)service);
  dnssd_check_error_code(err);
  return service;
}

/*
 * call-seq:
 *   DNSSD.resolve!(browse_reply) { |reply| } => service
 *   DNSSD.resolve!(name, type, domain, flags, interface) { |reply| } => service
 *
 * Synchronously resolve a service discovered via DNSSD::browse.
 *
 * +flags+ defaults to 0, +interface+ defaults to DNSSD::InterfaceAny.
 *
 * The service is resolved to a target host name, port number, and text record,
 * all contained in the DNSSD::Reply object passed to the required block.
 *
 *   timeout 2 do
 *     DNSSD.resolve! "foo bar", "_http._tcp", "local" do |r|
 *       p r
 *     end
 *   rescue TimeoutError
 *   end
 */

static VALUE
dnssd_resolve_bang(int argc, VALUE * argv, VALUE self) {
  return dnssd_service_start(
      sd_resolve(argc, argv, dnssd_service_alloc(rb_block_proc())));
}

/*
 * call-seq:
 *   DNSSD.resolve(browse_reply) { |reply| } => service
 *   DNSSD.resolve(name, type, domain, flags, interface) { |reply| } => service
 *
 * Asynchronously resolve a service discovered via DNSSD.browse().
 *
 * +flags+ defaults to 0, +interface+ defaults to DNSSD::InterfaceAny.
 *
 * The service is resolved to a target host name, port number, and text record,
 * all contained in the DNSSD::Reply object passed to the required block.
 *
 * The returned service can be used to control when to stop resolving the
 * service (see DNSSD::Service#stop).
 *
 *   s = DNSSD.resolve "foo bar", "_http._tcp", "local" do |r|
 *     p r
 *   end
 *   sleep 2
 *   s.stop
 */

static VALUE
dnssd_resolve(int argc, VALUE * argv, VALUE self) {
  return dnssd_service_start_in_thread(
      sd_resolve(argc, argv, dnssd_service_alloc(rb_block_proc())));
}

void
Init_DNSSD_Service(void) {
  VALUE mDNSSD = rb_define_module("DNSSD");

  dnssd_id_call        = rb_intern("call");
  dnssd_id_encode      = rb_intern("encode");
  dnssd_id_to_i        = rb_intern("to_i");
  dnssd_id_to_str      = rb_intern("to_str");

  dnssd_iv_block       = rb_intern("@block");
  dnssd_iv_domain      = rb_intern("@domain");
  dnssd_iv_interface   = rb_intern("@interface");
  dnssd_iv_port        = rb_intern("@port");
  dnssd_iv_result      = rb_intern("@result");
  dnssd_iv_service     = rb_intern("@service");
  dnssd_iv_target      = rb_intern("@target");
  dnssd_iv_text_record = rb_intern("@text_record");
  dnssd_iv_thread      = rb_intern("@thread");

  cDNSSDReply      = rb_define_class_under(mDNSSD, "Reply",      rb_cObject);
  cDNSSDService    = rb_define_class_under(mDNSSD, "Service",    rb_cObject);
  cDNSSDTextRecord = rb_define_class_under(mDNSSD, "TextRecord", rb_cObject);

  rb_define_singleton_method(cDNSSDService, "new", dnssd_service_new, -1);
  rb_define_singleton_method(cDNSSDService, "fullname", dnssd_service_s_fullname, 3);

  rb_define_method(cDNSSDService, "stop", dnssd_service_stop, 0);
  rb_define_method(cDNSSDService, "stopped?", dnssd_service_stopped_p, 0);

  rb_define_module_function(mDNSSD, "browse", dnssd_browse, -1);
  rb_define_module_function(mDNSSD, "browse!", dnssd_browse_bang, -1);

  rb_define_module_function(mDNSSD, "enumerate_domains", dnssd_enumerate_domains, -1);
  rb_define_module_function(mDNSSD, "enumerate_domains!", dnssd_enumerate_domains_bang, -1);

  rb_define_module_function(mDNSSD, "register", dnssd_register, -1);
  rb_define_module_function(mDNSSD, "register!", dnssd_register_bang, -1);

  rb_define_module_function(mDNSSD, "resolve", dnssd_resolve, -1);
  rb_define_module_function(mDNSSD, "resolve!", dnssd_resolve_bang, -1);
}

