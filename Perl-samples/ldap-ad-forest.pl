#!/usr/bin/perl
#

#############################################################################
#
# Find the beginning of the application by searching for 'MAIN:'
#
#############################################################################

# Always use 'strict' and 'warnings'
use strict;
use warnings;

# Version information
my $ID  = q$Id: ldap-ad-query, v1.02 2013-09-04 smithdonalde@gmail.com $;
my $REV = q$Version: 1.02 $;

# Look for libraries in a few more places
use FindBin;
BEGIN {
    push (@INC, "./lib");
    push (@INC, "$FindBin::Bin");
    push (@INC, "$FindBin::Bin/lib");
};

# Store the name of the application for later use
my $basename = $FindBin::Script;

# Add the necessary modules to make this work.
use Getopt::Long;           # for processing command line parameters
use Net::LDAP;
use Data::Dumper;

# Data structure for defaults and config file options
my $config = {
    # standard options
    'debug'             => 0,
};

##############################################################################
#
# Standard script start-up processing
#
    process_config_options();


##############################################################################
#
# MAIN:
#   Put all new code here
#{

# Parse the UPN for the domain (AD will register all DCs at the zone level)
my ($username, $ad_domain) = split('\@', $config->{'username'});
my $ldap_host = qw();
if ($config->{'server'}) {
	$ldap_host = $config->{'server'};
} else {
	$ldap_host = $ad_domain;
}

# Parse the domain for DN
my $ldap_base = "DC=" . join (",DC=", split('\.', $ad_domain));

# Display what information we'll use to connect
print "[- Connecting ------------------------------------]\n";
print "  User UPN    :  " . $config->{'username'} . "\n";
print "  AD Domain   :  " . $ad_domain . "\n";
print "  Auth Host   :  " . $ldap_host . "\n";
if ($config->{'server'}) { print "  Server      :  " . $config->{'server'} . "\n"; }
print "  Auth Base   :  " . $ldap_base . "\n";

# Connect to the target (domain) server
my $ldap = Net::LDAP->new ($ldap_host) or die "$@";
my $bind = $ldap->bind($config->{'username'}, password=>$config->{'password'});
my $result;

if ($bind->code) {
	print "\n";
	LDAPerror( "Bind: ", $bind);
}

# Everything starts with the rootDSE information
#    Extract the forest root naming context and forest DNS zone DNs
my $root_dse          = $ldap->root_dse();
my @naming_contexts   = $root_dse->get_value('namingContexts');
my ($ldap_forestNC, $ldap_forest_zones);

foreach my $item (@naming_contexts) {
    if ($item =~ m/^CN=Configuration/) { $ldap_forestNC = $item; next; }
    if ($item =~ m/^DC=ForestDnsZones/) { $ldap_forest_zones = $item; next; }
}

# Now show the rest of the discovered information
print "  Forest NC   :  " . $ldap_forestNC . "\n";
print "  Forest Zones:  " . $ldap_forest_zones . "\n";
print "[-------------------------------------------------]\n";


# Print who is authorizing this script now
print "[- User Search -----------------------------------]\n";
$result = LDAPsearch($ldap, "(&(sAMAccountName=$username))", [ 'cn' ], $ldap_base);
DisplayResults($result);

# Let's start with the Forest Root and work down
my $ldap_forest_dhcp  = "CN=NetServices,CN=Services," . $ldap_forestNC;
my $ldap_forest_sites = "CN=Sites," . $ldap_forestNC;

# Re-usable variables
my $ldap_base_domn_zn = "DC=DomainDnsZones,";
my $ldap_filter = qw();
my $ldap_attrs  = qw();
$ldap_base = $ldap_forestNC;

#
# In order...
#   All AD Domains in the Forest
#   All Sites w/ Subnets
#   All Authorized DHCP Servers
#   All Forest level DNS zones (AD integrated)
#
print "[- AD Forest Domains Search ----------------------]\n";
$ldap_attrs  = [ "cn", "distinguishedName", "dnsroot", "ncname", "name", "netbiosname" ];
$result = LDAPsearch($ldap, "(NETBIOSName=*)", $ldap_attrs, $ldap_forestNC);
my %forest_domains = DisplayResults($result);

print "[  *** Sites *** ]\n";
$result = LDAPsearch($ldap, "(objectCategory=site)", [ 'name', 'uSNChanged', 'siteObjectBL' ], $ldap_forest_sites);
my %sites = DisplayResults($result);
foreach my $site (keys %sites) {
    print "   Site Name: $sites{$site}->{'name'}\n";

    if (ref($sites{$site}->{'siteobjectbl'}) eq "ARRAY") {
	my @sitelist = @{$sites{$site}->{'siteobjectbl'}};
	foreach my $subnet (@sitelist) {
	    my ($sn, @junk) = split /,/, $subnet;
	    $sn =~ s/,*//g;
	    $sn =~ s/^CN=//;
	    print "            : $sn\n";
	}
    } else {
	my $subnet = $sites{$site}->{'siteobjectbl'};
        my ($sn, @junk) = split /,/, $subnet;
        $sn =~ s/,*//g;
        $sn =~ s/^CN=//;
        print "            : $sn\n";
    }
    print "[-------------------------------------------------]\n";
}

print "[  *** Authorized DHCP Servers *** ]\n";
$result = LDAPsearch($ldap, "(dhcpServers=*)", [ 'name' ], $ldap_forest_dhcp);
DisplayResults($result);

print "[  *** Forest DNS Zones *** ]\n";
$result = LDAPsearch($ldap, "(&(cn=Zone)(!(name=..TrustAnchors)))", [ 'name', 'instancetype' ], $ldap_forest_zones);
DisplayResults($result);

#
# Now, on a per AD domain basis through the entire forest
# In order...
#   All AD Domain Controllers per Domain
#   All Domain level DNS zones (AD integrated)
#
print "[- AD Domain Controller Search -------------------]\n";
$ldap_filter = "(&(objectCategory=Computer)(userAccountControl:1.2.840.113556.1.4.803:=8192))";
$ldap_attrs  = [ "cn", "name", "dnshostname", "operatingsystem", "operatingsystemversion", "location", "description", "operatingsystemservicepack" ];
foreach my $forest (keys %forest_domains) {
	my $current_domain = $forest_domains{$forest}{'dnsroot'};
	print "[  *** $current_domain : AD Domain ***  ]\n";

	my $ldap = Net::LDAP->new ($current_domain);
	#check for error; if we get one, print issue and goto next; otherwise continue

	my $bind = $ldap->bind($config->{'username'}, password=>$config->{'password'});

	my $ldap_base = "DC=" . join (",DC=", split('\.', $current_domain));

	$result = LDAPsearch($ldap, $ldap_filter, $ldap_attrs, $ldap_base);
	DisplayResults($result);

	print "[  *** $current_domain : Domain DNS Zones *** ]\n";
	my $ldap_domain_zones = $ldap_base_domn_zn . $ldap_base;
	$result = LDAPsearch($ldap, "(&(cn=Zone)(!(name=RootDNSServers)))", [ 'name', 'instancetype' ], $ldap_domain_zones);
	DisplayResults($result);
}

$ldap->unbind;
print "! Finished\n";
exit 0;


##############################################################################
#
# End of main
#
##############################################################################



##############################################################################
# Usage         :   process_config_options()
# Purpose       :   Processes command line options and reads in config file
# Returns       :   nothing, modifies global $config variable
# Parameters    :   none
sub process_config_options {
    # Create a variable to hold out options in
    my $options;

    # Get the passed parameters
    my $options_okay = GetOptions (
        'server=s' 		=> \$config->{'server'},
        'username=s'    => \$config->{'username'},
        'password=s'    => \$config->{'password'},
    );

    # If we got some option we didn't expect, print a message and abort
    if ( !$options_okay ) {
        print "ERROR", "An invalid option was passed on the command line.\n";
        print "NOTICE", "Try '$basename --help' for help.\n";
        exit 1;
    }

    # update the config data with the options passed on the command line
    foreach my $opt_key (keys %{ $options }) {
        # Make sure we didn't somehow end up with a null value
        if (defined $options->{$opt_key}) {
            $config->{$opt_key} = $options->{$opt_key};
        }
    }

    return;
}



sub LDAPerror {
	my $unknown = "not known";
	my ($from, $mesg) = @_;

	print "Return Code: $mesg->code\n";
	print "\tMessage: $mesg->error_name\n";
	print "\t       : $mesg->error_text\n";
	print "MessageID  : $mesg->mesg_id\n";

	my $dn = $mesg->dn;
	if (!$dn) { $dn = $unknown; }
	print "\tDN: $dn\n";
}

sub DisplayResults {
	my ($results) = @_;
	my %records;

	my $href = $results->as_struct;
	my @arrayofDNs = keys %$href;

	foreach (@arrayofDNs) {
		my %record;
		my $key = $_;

		print "\n*  ", $key, "\n";
		my $valref = $$href{$_};
		my @arrayofAttrs = sort keys %$valref;
		my $attrName;

		foreach $attrName (@arrayofAttrs) {
			next if ($attrName =~ /;binary$/ );
			my $attrVal = @$valref{$attrName};
			print "   $attrName: @$attrVal \n";

			if (scalar @$attrVal > 1) {
			    @{$record{$attrName}} = @$attrVal;
			} else {
			    $record{$attrName} = "@$attrVal";
			}
		}

		$records{$key} = \%record;
	}
	print "\n[-------------------------------------------------]\n";
	return %records;
}

sub LDAPsearch {
	my ($ldap, $searchString, $attrs, $base) = @_;
	if (!$base) { $base = "DC=ad,DC=lab,DC=local"; }
	if (!$attrs) { $attrs = [ 'cn' ]; }

	my $sr = $ldap->search(
		base	=> "$base",
 		scope	=> "sub",
		filter	=> "$searchString",
		attrs	=> $attrs,
	);

	return $sr;
}


##############################################################################
#
# End of program
#
##############################################################################
