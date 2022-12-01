package Koha::Plugin::Fi::KohaSuomi::OverdueTool::Controllers::OverdueController;

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

use Modern::Perl;

use Mojo::Base 'Mojolicious::Controller';
use Try::Tiny;

use Koha::Checkouts;
use Koha::Patron::Attributes;
use C4::Context;

=head1 API

=cut

sub get {
    my $c = shift->openapi->valid_input or return;

    my $startdate = $c->validation->param('startdate');
    $startdate = "$startdate 00:00:00";
    my $enddate = $c->validation->param('enddate');
    $enddate = "$enddate 23:59:59";
    my @libraries = split(',', $c->validation->param('libraries'));
    my @categorycodes = split(',', $c->validation->param('categorycodes'));
    my $invoicelibrary = $c->validation->param('invoicelibrary');
    my $lastdate = $c->validation->param('lastdate');
    my $invoiced = $c->validation->param('invoiced');
    my $invoicedstatus = $c->validation->param('invoicedstatus');
    my $other_params = {
            'columns' => [ qw/borrowernumber/ ],
            'group_by' => [ qw/borrowernumber/ ],
            join => { 'item' => '', 'patron'},
        };
    my %attributes;
    my $notforloan = $invoiced ? { '=' => $invoicedstatus} : { '!=' => $invoicedstatus};
    if ($invoicelibrary eq "itembranch") {
        %attributes = (
            date_due => { '-between' => [$startdate, $enddate] },
            'item.homebranch' => \@libraries,
            'patron.categorycode' => \@categorycodes,
            'item.notforloan' => $notforloan,
        );
    } else {
        %attributes = (
            date_due => { '-between' => [$startdate, $enddate] },
            'me.branchcode' => \@libraries,
            'patron.categorycode' => \@categorycodes,
            'item.notforloan' => $notforloan,
        );
    }

    my $checkouts_count = Koha::Checkouts->search(
          \%attributes,
          $other_params
        )->count;

    my @columns = Koha::Checkouts->columns;
    _populate_paging_params($other_params, $c, 'date_due', \@columns);

    my $checkouts = Koha::Checkouts->search(
        \%attributes,
        $other_params
    );

    my $results = [];
    my $totalItems = 0;
    my $totalSum = 0;

    foreach my $checkout (@{$checkouts->unblessed}){
        my $items = [];
        my $librarytable = $invoicelibrary eq "itembranch" ? 'item.homebranch' : 'me.branchcode';
        my $borcheckouts = Koha::Checkouts->search(
            {
                borrowernumber => $checkout->{borrowernumber},
                date_due => { '>=' => $startdate, '<=' => $enddate  },
                'item.notforloan' => $notforloan,
                $librarytable => \@libraries,
            }, 
            {
                join => { 'item' => 'biblio'},
                '+select' => ['item.barcode', 'item.enumchron', 'item.itemcallnumber', 'item.itype', 'item.replacementprice', 'item.biblionumber', 'item.dateaccessioned', 'biblio.title', 'biblio.author'],
                '+as' => ['barcode', 'enumchron', 'itemcallnumber', 'itype', 'replacementprice', 'biblionumber', 'dateaccessioned', 'title', 'author'],
            }
        )->unblessed;

        $totalItems += scalar @$borcheckouts;
        foreach my $borcheckout (@$borcheckouts){
            $totalSum += $borcheckout->{replacementprice} if $borcheckout->{replacementprice};
        }

        my $borrowercheckouts;
        my $patron = Koha::Patrons->find($checkout->{borrowernumber})->unblessed;
        my $patronssnkey = Koha::Patron::Attributes->search({borrowernumber => $checkout->{borrowernumber}, code => 'SSN'})->next;
        $patronssnkey = $patronssnkey->attribute if $patronssnkey;
        $patron->{guarantorid} = get_guarantor_id($checkout->{borrowernumber});
        my $guarantorssnkey = Koha::Patron::Attributes->search({borrowernumber => $patron->{guarantorid}, code => 'SSN'})->next if $patron->{guarantorid};
        $guarantorssnkey = $guarantorssnkey->attribute if $guarantorssnkey;
        $borrowercheckouts = {
            borrowernumber => $checkout->{borrowernumber},
            cardnumber => $patron->{cardnumber},
            firstname => $patron->{firstname},
            surname => $patron->{surname},
            dateofbirth => $patron->{dateofbirth},
            address => $patron->{address},
            city => $patron->{city},
            zipcode => $patron->{zipcode},
            guarantorid => $patron->{guarantorid},
            lang => $patron->{lang},
            categorycode => $patron->{categorycode},
            patronssnkey => $patronssnkey || '',
            guarantorssnkey => $guarantorssnkey || ''
        };

        $borrowercheckouts->{checkouts} = $borcheckouts;
        push @{$results}, $borrowercheckouts
    }

    $totalSum = sprintf("%.2f", $totalSum);
    $totalSum =~ tr/./,/;

    return $c->render( status => 200, openapi => {
        total => $checkouts_count,
        totalItems => $totalItems,
        totalSum => $totalSum,
        records => $results
    });
}

sub get_guarantor_id {
    my ($patron_id) = @_;

    my $dbh = C4::Context->dbh;
    my $sth=$dbh->prepare('SELECT guarantor_id FROM borrower_relationships WHERE guarantee_id = ?');

    $sth->execute($patron_id) or return 0;
    my @guarantors=$sth->fetchrow_array();
    return $guarantors[0];
}

=head3 _populate_paging_params
my @columns = Koha::Old::Checkouts->columns;
_populate_paging_params($c->openapi->valid_input, $dbix_params, 'issue_id', \@columns);
Process offset, limit, sort and order params from the input and set dbix_params accordingly
=cut

sub _populate_paging_params {
    my ($dbix_params, $c, $default_sort, $columns) = @_;

    my $offset = $c->validation->param('offset');
    my $limit  = $c->validation->param('limit');
    my $sort   = $c->validation->param('sort');
    my $order  = $c->validation->param('order');

    if (defined $offset) {
        $dbix_params->{offset} = $offset;
    }
    if (defined $limit) {
        $dbix_params->{rows} = $limit;
    }
    if ($default_sort) {
        if (defined $order && $order =~ /^desc/i) {
            $dbix_params->{order_by} = { '-desc' => $default_sort };
        }
        else {
            $dbix_params->{order_by} = { '-asc' => $default_sort };
        }
    }
    if (defined $sort) {
        if (grep(/^$sort$/, @{$columns})) {
            if (keys %{$dbix_params->{'order_by'}}) {
                foreach my $param (keys %{$dbix_params->{'order_by'}}) {
                    $dbix_params->{order_by}->{$param} = $sort;
                }
            } else {
                $dbix_params->{order_by}->{'-asc'} = $sort;
            }
        }
    }
}

1;