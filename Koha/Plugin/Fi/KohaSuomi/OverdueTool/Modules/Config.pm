package Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Config;

# Copyright 2022 Koha-Suomi Oy
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use Modern::Perl;
use Carp;
use Scalar::Util qw( blessed );
use Try::Tiny;
use JSON;
use Koha::Libraries;
use Koha::Plugin::Fi::KohaSuomi::OverdueTool;
use C4::Context;

=head new

    my $config = Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Config->new($params);

=cut

sub new {
    my ($class, $params) = @_;
    my $self = {};
    $self->{_params} = $params;
    bless($self, $class);
    return $self;

}

sub _validateNew {
    my ($class, $params) = @_;

    unless ($params->{invoicelibrary}) {
        die "Missing invoicelibrary value";
    }

    unless ($params->{delaymonths}) {
        die "Missing delaymonths value";
    }

    unless ($params->{maxyears}) {
        die "Missing maxyears value";
    }

    unless ($params->{invoicenotforloan}) {
        die "Missing invoicenotforloan value";
    }

    unless ($params->{groupsettings}) {
        die "Missing groupsettings value";
    }
}

sub getInvoiceLibrary {
    return shift->{_params}->{invoicelibrary};
}

sub getDelayMonths {
    return shift->{_params}->{delaymonths};
}

sub getMaxYears {
    return shift->{_params}->{maxyears};
}

sub getInvoiceNotForLoan {
    return shift->{_params}->{invoicenotforloan};
}

sub getGroupSettings {
    return shift->{_params}->{groupsettings};
}

sub getPlugin() {
    return Koha::Plugin::Fi::KohaSuomi::OverdueTool->new();
}

sub setConfig() {
    my ($self) = @_;   
    $self->_validateNew($self->{_params});
    $self->getPlugin()->store_data(
        {
            delaymonths           => $self->getDelayMonths(),
            maxyears              => $self->getMaxYears(),
            invoicelibrary        => $self->getInvoiceLibrary(),
            invoicenotforloan     => $self->getInvoiceNotForLoan(),
            groupsettings         => $self->getGroupSettings(),

        }
    );
}

sub getConfig() {
    my ($self) = @_;

    my $branch = C4::Context->userenv->{'branch'};
    my $delaymonths = $self->getPlugin()->retrieve_data('delaymonths') || 1;
    
    my $config = {
        userlibrary => $branch,
        libraries => Koha::Libraries->search( {}, { columns => ["branchcode", "branchname"], order_by => ['branchname'] } )->unblessed,
        delaymonths => $self->getPlugin()->retrieve_data('delaymonths') || 1,
        maxyears => $self->getPlugin()->retrieve_data('maxyears') || 1,
        invoicelibrary => $self->getPlugin()->retrieve_data('invoicelibrary') || 'issuebranch',
        invoicenotforloan => $self->getPlugin()->retrieve_data('invoicenotforloan') || 6,
        overduerules => $self->checkOverdueRules($branch, $delaymonths) || [],
        groupsettings => $self->getPlugin()->retrieve_data('groupsettings') || '[]',
        pluginversion => $self->getPlugin()->{metadata}->{version},
    };
    
    $config->{groupsettings} = JSON::from_json($config->{groupsettings}) if $config->{groupsettings};

    return $config;
}

sub checkOverdueRules {
    my ( $self, $branch, $delaymonths ) = @_;

    my %delay;
    my $delayperiod;
    my $delaytime;
    my @categorycodes;

    my $dbh = C4::Context->dbh;
    my $sth;
    $sth = $dbh->prepare("SELECT * FROM overduerules WHERE branchcode = ?");
    $sth->execute($branch);
    if ( $sth->rows > 0 ) {
        for ( my $i = 0 ; $i < $sth->rows ; $i++ ) {
            my $row = $sth->fetchrow_hashref;
            if ($row->{delay3}) {
                push @categorycodes, $row->{categorycode};
                $delaytime = $row->{delay3};
                $delayperiod = '3';
            } elsif ($row->{delay2} && !$delayperiod) {
                push @categorycodes, $row->{categorycode};
                $delaytime = $row->{delay2};
                $delayperiod = '2';
            } elsif ($row->{delay1} && !$delayperiod) {
                push @categorycodes, $row->{categorycode};
                $delaytime = $row->{delay1};
                $delayperiod = '1';
            }
        }
    } else {
        my $isth = $dbh->prepare("SELECT * FROM overduerules WHERE branchcode = ''");
        $isth->execute();
        for ( my $i = 0 ; $i < $isth->rows ; $i++ ) {
            my $row = $isth->fetchrow_hashref;
            if ($row->{delay3}) {
                push @categorycodes, $row->{categorycode};
                $delaytime = $row->{delay3};
                $delayperiod = '3';
            } elsif ($row->{delay2} && !$delayperiod) {
                push @categorycodes, $row->{categorycode};
                $delaytime = $row->{delay2};
                $delayperiod = '2';
            } elsif ($row->{delay1} && !$delayperiod) {
                push @categorycodes, $row->{categorycode};
                $delaytime = $row->{delay1};
                $delayperiod = '1';
            }
        }
        $isth->finish;
    }
    $delay{delaytime} = $delaytime;
    $delay{delayperiod} = $delayperiod;
    $delay{delaymonths} = 0+$delaymonths;
    $delay{categorycodes} = \@categorycodes;

    return \%delay;

}

1;
