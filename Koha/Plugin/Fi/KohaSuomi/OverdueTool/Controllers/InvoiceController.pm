package Koha::Plugin::Fi::KohaSuomi::OverdueTool::Controllers::InvoiceController;

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

use C4::Log;

use Koha::Notice::Messages;
use Koha::Patron::Message;
use C4::Letters;
use POSIX qw(strftime);

use Koha::Items;
use Koha::Account;
use Koha::Patron;

use C4::Context;

use Try::Tiny;
use XML::LibXML;

sub set {
    my $c = shift->openapi->valid_input or return;

    return try {
        my $patron_id = $c->validation->param('patron_id');
        my $body = $c->req->json;

        my $preview = $body->{preview} || 0;

        my %tables = ( 'borrowers' => $patron_id, 'branches' => $body->{branchcode} );

        my $repeatdata;

        my %params;
        $params{"module"} = $body->{module};
        $params{"letter_code"} = $body->{letter_code};
        $params{"branchcode"} = $body->{branchcode} || '';
        $params{"tables"} = \%tables;
        $params{"lang"} = $body->{lang} || 'default';
        my @items;
        my $count = 1;
        my $totalfines = 0;
        my @itemnumbers;
        my $lastdatedue;
        my $lastissuedate;
        foreach my $repeat (@{$body->{repeat}}) {
            my ($y, $m, $d) = $repeat->{date_due} =~ /^(\d\d\d\d)-(\d\d)-(\d\d)/;
            my ($iy, $im, $id) = $repeat->{issuedate} =~ /^(\d\d\d\d)-(\d\d)-(\d\d)/;
            my $finvoice_date = $y.$m.$d;
            if ($finvoice_date > $lastdatedue || !$lastdatedue) {
                $lastdatedue = $body->{message_transport_type} eq 'finvoice' ? $finvoice_date : $d.'.'.$m.'.'.$y;
                $lastissuedate = $body->{message_transport_type} eq 'finvoice' ? $iy.$im.$id : $id.'.'.$im.'.'.$iy;
            }
            $repeat->{replacementprice} =~ tr/,/./;
            if ($body->{addreplacementprice} && !$preview) {
                my $accountline = Koha::Account::Lines->search({borrowernumber => $patron_id, itemnumber => $repeat->{itemnumber}, accounttype => 'B'});
                unless (@{$accountline->unblessed}) {
                    Koha::Account::Line->new({ 
                        borrowernumber => $patron_id, 
                        amountoutstanding => $repeat->{replacementprice}, 
                        amount => $repeat->{replacementprice},
                        note => 'Korvaushinta',
                        accounttype => 'B',
                        itemnumber => $repeat->{itemnumber},
                    })->store();
                }
            }
            $totalfines = $totalfines + $repeat->{replacementprice};
            $repeat->{replacementprice} =~ tr/./,/;
            my $item = {
                count => $count,
                itemnumber => $repeat->{itemnumber},
                replacementprice => $repeat->{replacementprice},
                finvoice_date => $finvoice_date,
                date_due => $d.'.'.$m.'.'.$y,
                enumchron => $repeat->{enumchron},
                itype => $repeat->{itype},
                itemcallnumber => $repeat->{itemcallnumber},
                barcode => $repeat->{barcode}
            };
            if ($body->{overduefines}) {
                my $overdueline = Koha::Account::Lines->find({borrowernumber => $patron_id, itemnumber => $repeat->{itemnumber}, accounttype => 'FU'});
                $item->{overduefine} = $overdueline ? $overdueline->amountoutstanding : 0;
                $totalfines = $totalfines + $item->{overduefine};
            }
            my $biblio = {
                title => _escape_string($repeat->{title}),
                author => _escape_string($repeat->{author}),
            };
            
            push @items, {"items" => $item, "biblio" => $biblio, "biblioitems" => $repeat->{biblionumber}};
            push @itemnumbers, {itemnumber => $repeat->{itemnumber}, biblionumber => $repeat->{biblionumber}};
            $count++
        }
        $params{"repeat"} = {$body->{repeat_type} => \@items};
        $params{"message_transport_type"} = $body->{message_transport_type} || 'pdf';
        
        my $now = strftime "%d%m%Y", localtime;
        my $finvoice_now = strftime "%Y%m%d", localtime;
        my $timestamp = strftime "%d.%m.%Y %H:%M", localtime;
        my $date = time + (14 * 24 * 60 * 60);
        my $duedate = strftime "%d.%m.%Y", localtime($date);
        my $finvoice_duedate = strftime "%Y%m%d", localtime($date);
        my $invoicefine = $body->{invoicefine};
        $invoicefine =~ tr/,/./;
        $totalfines = $totalfines + $invoicefine if $invoicefine;
        $totalfines = sprintf("%.2f", $totalfines);
        $totalfines =~ tr/./,/;

        my $reference;
        if ($body->{addreferencenumber} && !$preview) {
            $reference =_reference_number($body->{librarygroup}, $body->{increment});
        }

        $params{"substitute"} = {
            finvoice_today => $finvoice_now,
            finvoice_duedate => $finvoice_duedate,
            invoice_duedate => $duedate,
            lastitemduedate => $lastdatedue,
            lastitemissuedate => $lastissuedate,
            totalfines => $totalfines,
            referencenumber => $reference,
            invoicefine => $body->{invoicefine}, 
            accountnumber => $body->{accountnumber},
            biccode => $body->{biccode},
            businessid => $body->{businessid},
            issueborname => $body->{firstname}.' '.$body->{surname},
            issueborbarcode => $body->{cardnumber},
            grouplibrary => $body->{grouplibrary},
            groupaddress => $body->{groupaddress},
            groupzipcode => $body->{groupzipcode}, 
            groupcity => $body->{groupcity},
            groupphone => $body->{groupphone},
        };


        if ($body->{guarantee}) {
            my $guarantee = Koha::Patrons->find($body->{guarantee});
            $params{"substitute"}{"issueborname"} = $guarantee->firstname.' '.$guarantee->surname;
            $params{"substitute"}{"issueborbarcode"} = $guarantee->cardnumber;
        }

        if (!$preview) {
            $params{"substitute"}{"invoicenumber"} = $body->{invoicenumber};
            _update_invoice_number($params{"substitute"}{"invoicenumber"});
        }

        my $notice = C4::Letters::GetPreparedLetter(%params);

        $notice->{content} =~ s/>\s+</></g; if $body->{message_transport_type} eq "finvoice"

        my $message_id;

        unless ($preview) {
        
            $message_id = C4::Letters::EnqueueLetter(
                            {   letter                 => $notice,
                                borrowernumber         => $patron_id,
                                message_transport_type => $params{"message_transport_type"},
                                from_address => $body->{branchcode},
                            }
                        );

            foreach my $item (@itemnumbers) {
                my $item_object = Koha::Items->find($item->{itemnumber});
                $item_object->set({new_status => $message_id, notforloan => $body->{notforloan_status}});
                $item_object->store;
            }

            if ($body->{debarment}) {

                Koha::Patron::Debarments::AddUniqueDebarment({
                    borrowernumber => $patron_id,
                    type           => 'OVERDUES',
                    comment        => "Lainauskielto laskutetusta aineistosta",
                });
                if ($body->{guarantee}) {
                    Koha::Patron::Debarments::AddUniqueDebarment({
                        borrowernumber => $body->{guarantee},
                        type           => 'OVERDUES',
                        comment        => "Lainauskielto laskutetusta aineistosta",
                    });
                }
            }

            if ($body->{patronmessage}) {
                Koha::Patron::Message->new(
                    {
                        borrowernumber => $patron_id,
                        branchcode     => $body->{branchcode},
                        message_type   => 'L',
                        message        => $body->{patronmessage},
                    }
                )->store;
            }

            if ($body->{guaranteemessage}) {
                Koha::Patron::Message->new(
                    {
                        borrowernumber => $body->{guarantee},
                        branchcode     => $body->{branchcode},
                        message_type   => 'L',
                        message        => $body->{guaranteemessage},
                    }
                )->store;
            }
        }
        
        return $c->render(status => 201, openapi => {message_id => $message_id, notice => $notice->{content}});
    }
    catch {
        warn Data::Dumper::Dumper $_;
        return $c->render(status => 500, openapi => {error => 'Something went wrong, check the logs!'});
    };
}

sub update {
    my $c = shift->openapi->valid_input or return;

    my $notice;
    return try {
        my $notice_id = $c->validation->param('notice_id');
        $notice = Koha::Notice::Messages->find($notice_id);
        my $body = $c->req->json;

        $notice->set($body);
        return $c->render( status => 204, openapi => {}) unless $notice->is_changed;
        $notice->store;
        return $c->render( status => 200, openapi => $notice);
    }
    catch {
        unless ($notice) {
            return $c->render( status  => 404,
                               openapi => { error => "Notice not found" } );
        } else {
            return $c->render( status  => 500,
                               openapi => { error => "Something went wront, check the logs!" } );
        }
    };
}

sub _escape_string {
    my ($string) = @_;

    $string =~ s/&/&amp;/sg;
    $string =~ s/</&lt;/sg;
    $string =~ s/>/&gt;/sg;
    $string =~ s/"/&quot;/sg;
    
    return $string;
}

sub _reference_number {
    my ($librarygroup, $increment) = @_;
    my $dbh = C4::Context->dbh;
    my $sth_refnumber=$dbh->prepare('SELECT plugin_value FROM plugin_data WHERE plugin_class = "Koha::Plugin::Fi::KohaSuomi::OverdueTool" AND plugin_key = "REFNO_'.$librarygroup.'";');

    $sth_refnumber->execute() or return 0;
    my @refno=$sth_refnumber->fetchrow_array();
    
    my $sth_update = $dbh->prepare('UPDATE plugin_data SET plugin_value = ? WHERE plugin_class = "Koha::Plugin::Fi::KohaSuomi::OverdueTool" AND plugin_key = "REFNO_'.$librarygroup.'";');
    $sth_update->execute($refno[0]+$increment);

    return $refno[0] . _ref_checksum($refno[0]);
}

sub _ref_checksum {
    my $ref=reverse(shift);
    my $checkSum=0;
    my @weights=(7,3,1);
    my $i=0;

    for my $refNumber (split //, $ref) {
        $i=0 if $i==@weights;
        $checkSum=$checkSum+($refNumber*$weights[$i]);
        $i++;
    }

    my $nextTen=$checkSum+9;
    $nextTen=$nextTen-($nextTen%10);
    
    return $nextTen-$checkSum;
}

sub _invoice_number {
    my $dbh = C4::Context->dbh;
    my $sth_invoicenumber=$dbh->prepare('SELECT plugin_value FROM plugin_data WHERE plugin_class = "Koha::Plugin::Fi::KohaSuomi::OverdueTool" AND plugin_key = "invoicenumber";');

    $sth_invoicenumber->execute() or return 0;
    my $invoiceno=$sth_invoicenumber->fetchrow();
    return $invoiceno;
}

sub _update_invoice_number {
    my ($invoicenumber) = @_;
    my $dbh = C4::Context->dbh;
    my $sth_update = $dbh->do('UPDATE plugin_data SET plugin_value = '.$invoicenumber.' WHERE plugin_class ="Koha::Plugin::Fi::KohaSuomi::OverdueTool" AND plugin_key = "invoicenumber" AND plugin_value < '.$invoicenumber.';');
}


1;