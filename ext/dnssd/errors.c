#include "dnssd.h"
#include <assert.h>

VALUE eDNSSDError;
static VALUE eDNSSDUnknownError;

#define DNSSD_ERROR_START (-65556)
#define DNSSD_ERROR_END   (-65536)

static VALUE dnssd_errors[DNSSD_ERROR_END - DNSSD_ERROR_START];

static void
dnssd_errors_store(VALUE error, int num) {
  assert(DNSSD_ERROR_START <= num && num < DNSSD_ERROR_END);
  dnssd_errors[num - DNSSD_ERROR_START] = error;
}

void
dnssd_check_error_code(DNSServiceErrorType e) {
  int num = (int)e;
  if (num) {
    if(DNSSD_ERROR_START <= num && num < DNSSD_ERROR_END) {
      rb_raise(dnssd_errors[num - DNSSD_ERROR_START],
          "DNSSD operation failed with error code: %d", num);
    } else {
      rb_raise(eDNSSDUnknownError,
          "DNSSD operation failed with unrecognized error code: %d", num);
    }
  }
}

void
dnssd_instantiation_error(const char *what) {
  rb_raise(rb_eRuntimeError,
      "cannot instantiate %s, use DNSSD "
      "enumerate_domains(), browse(), resolve() or register() instead",
      what);
}

/* Document-class: DNSSD::Error
 *
 * Base class of all DNS Service Discovery related errors.
 *
 */

void
Init_DNSSD_Errors(void) {
  VALUE error_class;
  VALUE mDNSSD = rb_define_module("DNSSD");

  eDNSSDError = rb_define_class_under(mDNSSD, "Error", rb_eStandardError);

  eDNSSDUnknownError = rb_define_class_under(mDNSSD, "UnknownError", eDNSSDError);
  dnssd_errors_store(eDNSSDUnknownError, kDNSServiceErr_Unknown);

  error_class = rb_define_class_under(mDNSSD, "NoSuchNameError", eDNSSDError);
  dnssd_errors_store(error_class, kDNSServiceErr_NoSuchName);

  error_class = rb_define_class_under(mDNSSD, "NoMemoryError", eDNSSDError);
  dnssd_errors_store(error_class, kDNSServiceErr_NoMemory);

  error_class = rb_define_class_under(mDNSSD, "BadParamError", eDNSSDError);
  dnssd_errors_store(error_class, kDNSServiceErr_BadParam);

  error_class = rb_define_class_under(mDNSSD, "BadReferenceError", eDNSSDError);
  dnssd_errors_store(error_class, kDNSServiceErr_BadReference);

  error_class = rb_define_class_under(mDNSSD, "BadStateError", eDNSSDError);
  dnssd_errors_store(error_class, kDNSServiceErr_BadState);

  error_class = rb_define_class_under(mDNSSD, "BadFlagsError", eDNSSDError);
  dnssd_errors_store(error_class, kDNSServiceErr_BadFlags);

  error_class = rb_define_class_under(mDNSSD, "UnsupportedError", eDNSSDError);
  dnssd_errors_store(error_class, kDNSServiceErr_Unsupported);

  error_class = rb_define_class_under(mDNSSD, "NotInitializedError", eDNSSDError);
  dnssd_errors_store(error_class, kDNSServiceErr_NotInitialized);

  error_class = rb_define_class_under(mDNSSD, "AlreadyRegisteredError", eDNSSDError);
  dnssd_errors_store(error_class, kDNSServiceErr_AlreadyRegistered);

  error_class = rb_define_class_under(mDNSSD, "NameConflictError", eDNSSDError);
  dnssd_errors_store(error_class, kDNSServiceErr_NameConflict);

  error_class = rb_define_class_under(mDNSSD, "InvalidError", eDNSSDError);
  dnssd_errors_store(error_class, kDNSServiceErr_Invalid);

  error_class = rb_define_class_under(mDNSSD, "FirewallError", eDNSSDError);
  dnssd_errors_store(error_class, kDNSServiceErr_Firewall);

  error_class = rb_define_class_under(mDNSSD, "ClientIncompatibleError", eDNSSDError);
  dnssd_errors_store(error_class, kDNSServiceErr_Incompatible);

  error_class = rb_define_class_under(mDNSSD, "BadInterfaceIndexError", eDNSSDError);
  dnssd_errors_store(error_class, kDNSServiceErr_BadInterfaceIndex);

  error_class = rb_define_class_under(mDNSSD, "RefusedError", eDNSSDError);
  dnssd_errors_store(error_class, kDNSServiceErr_Refused);

  error_class = rb_define_class_under(mDNSSD, "NoSuchRecordError", eDNSSDError);
  dnssd_errors_store(error_class, kDNSServiceErr_NoSuchRecord);

  error_class = rb_define_class_under(mDNSSD, "NoAuthenticationError", eDNSSDError);
  dnssd_errors_store(error_class, kDNSServiceErr_NoAuth);

  error_class = rb_define_class_under(mDNSSD, "NoSuchKeyError", eDNSSDError);
  dnssd_errors_store(error_class, kDNSServiceErr_NoSuchKey);

  error_class = rb_define_class_under(mDNSSD, "NATTraversalError", eDNSSDError);
  dnssd_errors_store(error_class, kDNSServiceErr_NATTraversal);

  error_class = rb_define_class_under(mDNSSD, "DoubleNATError", eDNSSDError);
  dnssd_errors_store(error_class, kDNSServiceErr_DoubleNAT);

  error_class = rb_define_class_under(mDNSSD, "BadTimeError", eDNSSDError);
  dnssd_errors_store(error_class, kDNSServiceErr_BadTime);

  error_class = rb_define_class_under(mDNSSD, "BadSigError", eDNSSDError);
  dnssd_errors_store(error_class, kDNSServiceErr_BadSig);

  error_class = rb_define_class_under(mDNSSD, "BadKeyError", eDNSSDError);
  dnssd_errors_store(error_class, kDNSServiceErr_BadKey);

  error_class = rb_define_class_under(mDNSSD, "TransientError", eDNSSDError);
  dnssd_errors_store(error_class, kDNSServiceErr_Transient);

  error_class = rb_define_class_under(mDNSSD, "ServiceNotRunningError", eDNSSDError);
  dnssd_errors_store(error_class, kDNSServiceErr_ServiceNotRunning);

  error_class = rb_define_class_under(mDNSSD, "NATPortMappingUnsupported", eDNSSDError);
  dnssd_errors_store(error_class, kDNSServiceErr_NATPortMappingUnsupported);

  error_class = rb_define_class_under(mDNSSD, "NATPortMappingDisabled", eDNSSDError);
  dnssd_errors_store(error_class, kDNSServiceErr_NATPortMappingDisabled);
}
