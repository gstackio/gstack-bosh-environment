// define our registrar and providers
var REG_NONE = NewRegistrar('none', 'NONE');
var GANDI = NewDnsProvider("gandi", "GANDI");

D("DNS_ZONE", REG_NONE, DnsProvider(GANDI),
    DefaultTTL('5m'),

    A("DNS_SUBDOMAIN",              "EXTERNAL_IP"),
    CNAME("*.DNS_SUBDOMAIN",        "DNS_SUBDOMAIN.DNS_ZONE."),

    {'ns_ttl': '600'} // On domain apex NS RRs

)
