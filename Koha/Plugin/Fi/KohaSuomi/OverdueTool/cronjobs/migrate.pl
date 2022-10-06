#!/usr/bin/perl

# Copyright 2022 Koha-Suomi Oy
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

BEGIN {
    # find Koha's Perl modules
    # test carefully before changing this
    use FindBin;
    eval { require "$FindBin::Bin/../kohalib.pl" };
}
use
  CGI; # NOT a CGI script, this is just to keep C4::Templates::gettemplate happy
use C4::Context;
use Modern::Perl;
use Getopt::Long;
use Koha::Library::Groups;
use Koha::Plugins;
use Koha::Plugin::Fi::KohaSuomi::OverdueTool;

my $plugin = Koha::Plugin::Fi::KohaSuomi::OverdueTool->new();
$plugin->retrieve_data('groupsettings');
my $groupsettings = JSON::from_json($plugin->retrieve_data('groupsettings'));
my $dbh = C4::Context->dbh;
my $groups = $dbh->selectall_arrayref("SELECT * FROM library_groups", { Slice => {} });
foreach my $setting (@$groupsettings) {
    foreach my $group (@$groups) {
        if ($group->{description} =~ /$setting->{groupname}/ ) {
            my $sub = Koha::Library::Groups->find($group->{id});
            delete $setting->{grouplibraries} if $setting->{grouplibraries};
            foreach my $library (@{$sub->libraries->unblessed}) {
                push @{$setting->{grouplibraries}}, {branchname => $library->{branchname}, branchcode => $library->{branchcode}};
            }
        }
    }

    foreach my $group (@$groups) {
        my $sub = Koha::Library::Groups->find($group->{id});
        if ($group->{description} =~ /EINVOICE/) {
            foreach my $library (@{$sub->libraries->unblessed}) {
                foreach my $branch (@{$setting->{grouplibraries}}) {
                    if ($branch->{branchcode} eq $library->{branchcode}) {
                        $setting->{invoicetype} = 'EINVOICE';
                    }
                }
                
            }
        }
        if ($group->{description} =~ /FINVOICE/) {
            foreach my $library (@{$sub->libraries->unblessed}) {
                foreach my $branch (@{$setting->{grouplibraries}}) {
                    if ($branch->{branchcode} eq $library->{branchcode}){
                        $setting->{invoicetype} = 'FINVOICE';
                    }
                }
                
            }
        }
        if ($group->{description} =~ /ODUECLAIM/) {
            foreach my $library (@{$sub>libraries->unblessed}) {
                foreach my $branch (@{$setting->{grouplibraries}}) {
                    if ($branch->{branchcode} eq $library->{branchcode}) {
                        $setting->{invoicetype} = 'ODUECLAIM';
                    }
                }
                
            }
        }
    }
}

$plugin->store_data({
    groupsettings => JSON::to_json($groupsettings)
});

$dbh->do("INSERT INTO message_transport_types (message_transport_type) VALUES ('finvoice');");
$dbh->do("INSERT INTO message_transport_types (message_transport_type) VALUES ('pdf');");
$dbh->do("INSERT INTO plugin_data (plugin_class,plugin_key,plugin_value) VALUES ('Koha::Plugin::Fi::KohaSuomi::OverdueTool','invoicenumber','1');");
$dbh->do("INSERT INTO plugin_data (plugin_class,plugin_key,plugin_value) VALUES ('Koha::Plugin::Fi::KohaSuomi::OverdueTool','__ENABLED__','1');");
$dbh->do("UPDATE letter set code = 'ODUECLAIM', message_transport_type = 'finvoice' where code = 'FINVOICE' and message_transport_type = 'invoice';");
$dbh->do("UPDATE letter set message_transport_type = 'pdf' where code = 'ODUECLAIM' and message_transport_type = 'invoice';");

