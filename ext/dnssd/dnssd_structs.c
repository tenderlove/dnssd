/*
 * Copyright (c) 2004 Chad Fowler, Charles Mills, Rich Kilmer
 * Licensed under the same terms as Ruby.
 * This software has absolutely no warranty.
 */
#include "dnssd.h"

/* dns sd flags, flag ID's, flag names */
#define DNSSD_MAX_FLAGS 9

static const DNSServiceFlags dnssd_flag[DNSSD_MAX_FLAGS] = {
  kDNSServiceFlagsMoreComing,

  kDNSServiceFlagsAdd,
  kDNSServiceFlagsDefault,

  kDNSServiceFlagsNoAutoRename,

  kDNSServiceFlagsShared,
  kDNSServiceFlagsUnique,

  kDNSServiceFlagsBrowseDomains,
  kDNSServiceFlagsRegistrationDomains,

  kDNSServiceFlagsLongLivedQuery
};

static const char *dnssd_flag_name[DNSSD_MAX_FLAGS] = {
  "more_coming",
  "add",
  "default",
  "no_auto_rename",
  "shared",
  "unique",
  "browse_domains",
  "registration_domains",
  "long_lived_query"
};

void
Init_DNSSD_Replies(void) {
  int i;
  VALUE flags_hash;
  VALUE cDNSSDFlags;

  /* hack so rdoc documents the project correctly */
#ifdef mDNSSD_RDOC_HACK
  mDNSSD = rb_define_module("DNSSD");
#endif

  cDNSSDFlags = rb_define_class_under(mDNSSD, "Flags", rb_cObject);

  /* flag constants */
#if DNSSD_MAX_FLAGS != 9
#error The code below needs to be updated.
#endif

  /* MoreComing indicates that at least one more result is queued and will be
   * delivered following immediately after this one.
   *
   * Applications should not update their UI to display browse results when the
   * MoreComing flag is set, because this would result in a great deal of ugly
   * flickering on the screen.  Applications should instead wait until
   * MoreComing is not set, and then update their UI.
   *
   * When MoreComing is not set, that doesn't mean there will be no more
   * answers EVER, just that there are no more answers immediately available
   * right now at this instant.  If more answers become available in the future
   * they will be delivered as usual.
   */
  rb_define_const(cDNSSDFlags, "MoreComing",
		  ULONG2NUM(kDNSServiceFlagsMoreComing));

  /* Applies only to enumeration.  An enumeration callback with the
   * DNSSD::Flags::Add flag NOT set indicates a DNSSD::Flags::Remove, i.e. the
   * domain is no longer valid.
   */
  rb_define_const(cDNSSDFlags, "Add", ULONG2NUM(kDNSServiceFlagsAdd));

  /* Applies only to enumeration and is only valid in conjunction with Add
   */
  rb_define_const(cDNSSDFlags, "Default", ULONG2NUM(kDNSServiceFlagsDefault));

  /* Flag for specifying renaming behavior on name conflict when registering
   * non-shared records.
   *
   * By default, name conflicts are automatically handled by renaming the
   * service.  DNSSD::Flags::NoAutoRename overrides this behavior - with this
   * flag set, name conflicts will result in a callback.  The NoAutoRename flag
   * is only valid if a name is explicitly specified when registering a service
   * (ie the default name is not used.)
   */
  rb_define_const(cDNSSDFlags, "NoAutoRename",
		  ULONG2NUM(kDNSServiceFlagsNoAutoRename));

  /* Flag for registering individual records on a connected DNSServiceRef.
   *
   * DNSSD::Flags::Shared indicates that there may be multiple records with
   * this name on the network (e.g. PTR records).  DNSSD::Flags::Unique
   * indicates that the record's name is to be unique on the network (e.g. SRV
   * records).  (DNSSD::Flags::Shared and DNSSD::Flags::Unique are currently
   * not used by the Ruby API.)
   */
  rb_define_const(cDNSSDFlags, "Shared", ULONG2NUM(kDNSServiceFlagsShared));
  rb_define_const(cDNSSDFlags, "Unique", ULONG2NUM(kDNSServiceFlagsUnique));

  /* DNSSD::Flags::BrowseDomains enumerates domains recommended for browsing
   */
  rb_define_const(cDNSSDFlags, "BrowseDomains",
		  ULONG2NUM(kDNSServiceFlagsBrowseDomains));

  /* DNSSD::Flags::RegistrationDomains enumerates domains recommended for
   * registration.
   */

  rb_define_const(cDNSSDFlags, "RegistrationDomains",
		  ULONG2NUM(kDNSServiceFlagsRegistrationDomains));

  /* Flag for creating a long-lived unicast query for the DNSDS.query_record()
   * (currently not part of the Ruby API). */
  rb_define_const(cDNSSDFlags, "LongLivedQuery",
		  ULONG2NUM(kDNSServiceFlagsLongLivedQuery));

  flags_hash = rb_hash_new();

  for (i = 0; i < DNSSD_MAX_FLAGS; i++) {
    rb_hash_aset(flags_hash, rb_str_new2(dnssd_flag_name[i]),
		 ULONG2NUM(dnssd_flag[i]));
  }

  rb_define_const(cDNSSDFlags, "FLAGS", flags_hash);
}

