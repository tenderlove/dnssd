#include "dnssd.h"

/* dnssd flags, flag IDs, flag names */
#define DNSSD_MAX_FLAGS 15

static const DNSServiceFlags dnssd_flag[DNSSD_MAX_FLAGS] = {
  kDNSServiceFlagsMoreComing,
  kDNSServiceFlagsAdd,
  kDNSServiceFlagsDefault,
  kDNSServiceFlagsNoAutoRename,
  kDNSServiceFlagsShared,
  kDNSServiceFlagsUnique,
  kDNSServiceFlagsBrowseDomains,
  kDNSServiceFlagsRegistrationDomains,
  kDNSServiceFlagsLongLivedQuery,
  kDNSServiceFlagsAllowRemoteQuery,
  kDNSServiceFlagsForceMulticast
#ifdef HAVE_KDNSSERVICEFLAGSFORCE
, kDNSServiceFlagsForce
#else
, (DNSServiceFlags)NULL
#endif

#ifdef HAVE_KDNSSERVICEFLAGSRETURNINTERMEDIATES
, kDNSServiceFlagsReturnIntermediates
#else
, (DNSServiceFlags)NULL
#endif

#ifdef HAVE_KDNSSERVICEFLAGSNONBROWSABLE
, kDNSServiceFlagsNonBrowsable
#else
, (DNSServiceFlags)NULL
#endif

#ifdef HAVE_KDNSSERVICEFLAGSSHARECONNECTION
, kDNSServiceFlagsShareConnection
#else
, (DNSServiceFlags)NULL
#endif
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
  "long_lived_query",
  "allow_remote_query",
  "force_multicast",
  "force",
  "return_intermediates",
  "non_browsable",
  "share_connection"
};

void
Init_DNSSD_Flags(void) {
  int i;
  VALUE flags_hash;
  VALUE cDNSSDFlags;
  VALUE mDNSSD = rb_define_module("DNSSD");

  cDNSSDFlags = rb_define_class_under(mDNSSD, "Flags", rb_cObject);

  /* flag constants */
#if DNSSD_MAX_FLAGS != 15
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
   * (i.e. the default name is not used.)
   */
  rb_define_const(cDNSSDFlags, "NoAutoRename",
      ULONG2NUM(kDNSServiceFlagsNoAutoRename));

#ifdef kDNSServiceFlagsShareConnection
  /* For efficiency, clients that perform many concurrent operations may want
   * to use a single Unix Domain Socket connection with the background daemon,
   * instead of having a separate connection for each independent operation. To
   * use this mode, clients first call DNSServiceCreateConnection(&MainRef) to
   * initialize the main DNSServiceRef.  For each subsequent operation that is
   * to share that same connection, the client copies the MainRef, and then
   * passes the address of that copy, setting the ShareConnection flag to tell
   * the library that this DNSServiceRef is not a typical uninitialized
   * DNSServiceRef; it's a copy of an existing DNSServiceRef whose connection
   * information should be reused.
   *
   * NOTE: Not currently supported
   */
  rb_define_const(cDNSSDFlags, "ShareConnection",
      ULONG2NUM(kDNSServiceFlagsShareConnection));
#endif

  /* Flag for registering individual records on a connected DNSSD::Service.
   *
   * DNSSD::Flags::Shared indicates that there may be multiple records with
   * this name on the network (e.g. PTR records).
   *
   * (Not used currently by the Ruby API)
   */
  rb_define_const(cDNSSDFlags, "Shared", ULONG2NUM(kDNSServiceFlagsShared));

  /* DNSSD::Flags::Unique indicates that the record's name is to be unique on
   * the network (e.g. SRV records).
   *
   * (Not used currently by the Ruby API)
   */
  rb_define_const(cDNSSDFlags, "Unique", ULONG2NUM(kDNSServiceFlagsUnique));

  /* Specifies domain enumeration type.
   *
   * DNSSD::Flags::BrowseDomains enumerates domains recommended for browsing
   */
  rb_define_const(cDNSSDFlags, "BrowseDomains",
      ULONG2NUM(kDNSServiceFlagsBrowseDomains));

  /* Specifies domain enumeration type.
   *
   * DNSSD::Flags::RegistrationDomains enumerates domains recommended for
   * registration.
   */
  rb_define_const(cDNSSDFlags, "RegistrationDomains",
      ULONG2NUM(kDNSServiceFlagsRegistrationDomains));

  /* Flag for creating a long-lived unicast query for DNSSD.query_record
   *
   * (Not used by the Ruby API)
   */
  rb_define_const(cDNSSDFlags, "LongLivedQuery",
      ULONG2NUM(kDNSServiceFlagsLongLivedQuery));

  /* Flag for creating a record for which we will answer remote queries
   * (queries from hosts more than one hop away; hosts not directly connected
   * to the local link).
   */
  rb_define_const(cDNSSDFlags, "AllowRemoteQuery",
      ULONG2NUM(kDNSServiceFlagsAllowRemoteQuery));

  /* Flag for signifying that a query or registration should be performed
   * exclusively via multicast DNS, even for a name in a domain (e.g.
   * foo.apple.com.) that would normally imply unicast DNS.
   */
  rb_define_const(cDNSSDFlags, "ForceMulticast",
      ULONG2NUM(kDNSServiceFlagsForceMulticast));

#ifdef HAVE_KDNSSERVICEFLAGSFORCE
  /* Flag for signifying a "stronger" variant of an operation. Currently
   * defined only for DNSSD.reconfirm_record, where it forces a record to
   * be removed from the cache immediately, instead of querying for a few
   * seconds before concluding that the record is no longer valid and then
   * removing it. This flag should be used with caution because if a service
   * browsing PTR record is indeed still valid on the network, forcing its
   * removal will result in a user-interface flap -- the discovered service
   * instance will disappear, and then re-appear moments later.
   */
  rb_define_const(cDNSSDFlags, "Force", ULONG2NUM(kDNSServiceFlagsForce));
#endif

#ifdef HAVE_KDNSSERVICEFLAGSNONBROWSABLE
  /* A service registered with the NonBrowsable flag set can be resolved using
   * DNSServiceResolve(), but will not be discoverable using
   * DNSServiceBrowse().  This is for cases where the name is actually a GUID;
   * it is found by other means; there is no end-user benefit to browsing to
   * find a long list of opaque GUIDs.  Using the NonBrowsable flag creates
   * SRV+TXT without the cost of also advertising an associated PTR record.
   */
  rb_define_const(cDNSSDFlags, "NonBrowsable",
      ULONG2NUM(kDNSServiceFlagsNonBrowsable));
#endif

#ifdef HAVE_KDNSSERVICEFLAGSRETURNINTERMEDIATES
  /* Flag for returning intermediate results. For example, if a query results
   * in an authoritative NXDomain (name does not exist) then that result is
   * returned to the client. However the query is not implicitly cancelled --
   * it remains active and if the answer subsequently changes (e.g. because a
   * VPN tunnel is subsequently established) then that positive result will
   * still be returned to the client. Similarly, if a query results in a CNAME
   * record, then in addition to following the CNAME referral, the intermediate
   * CNAME result is also returned to the client. When this flag is not set,
   * NXDomain errors are not returned, and CNAME records are followed silently
   * without informing the client of the intermediate steps.
   */
  rb_define_const(cDNSSDFlags, "ReturnIntermediates",
      ULONG2NUM(kDNSServiceFlagsReturnIntermediates));
#endif

#ifdef HAVE_KDNSSERVICEFLAGSSHARECONNECTION
  rb_define_const(cDNSSDFlags, "ShareConnection",
      ULONG2NUM(kDNSServiceFlagsShareConnection));
#endif

  flags_hash = rb_hash_new();

  for (i = 0; i < DNSSD_MAX_FLAGS; i++) {
    if (dnssd_flag[i])
      rb_hash_aset(flags_hash, rb_str_new2(dnssd_flag_name[i]),
          ULONG2NUM(dnssd_flag[i]));
  }

  /* Hash of flags => flag_name */
  rb_define_const(cDNSSDFlags, "FLAGS", flags_hash);
}

