package Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Config;

use Modern::Perl;
use Exporter;
use C4::Context;
use Koha::LibraryCategories;
use Mojo::JSON;

our @ISA = qw(Exporter);
our @EXPORT = qw(get_branch_settings check_overdue_rules set_group_settings get_group_settings);

sub set_group_settings {
    my ( $saved ) = @_;
    my $library_categories = Koha::LibraryCategories->search({});
    my $categories = $saved;
    foreach my $category (@{$library_categories->unblessed}) {
        if ($category->{categorycode} =~ /LASKU/i) {
            my $add = 1;
            if ($saved) {
                foreach my $s (@{$saved}) {
                    if ($s->{groupname} eq $category->{categorycode}) {
                        $add = 0;
                    }
                }
            }
            if ($add) {
                my $settings = {
                    groupname => $category->{categorycode}, 
                    increment => '', 
                    addreferencenumber => Mojo::JSON->false, 
                    debarment => Mojo::JSON->false, 
                    addreplacementprice => Mojo::JSON->false,
                    overduefines =>  Mojo::JSON->false,
                    invoicefine => ''
                };
                push @{$categories}, $settings;
            }
        }
    }
    
    return $categories;
}

sub get_group_settings {
    my ( $saved, $group ) = @_;
    my $increment;
    my $addreferencenumber;
    my $debarment;
    my $addreplacementprice;
    my $overduefines;
    my $invoicefine;
    foreach my $s (@{$saved}) {
        if ($s->{groupname} eq $group) {
            $increment = $s->{increment};
            $addreferencenumber = $s->{addreferencenumber};
            $debarment = $s->{addreferencenumber};
            $addreplacementprice = $s->{addreplacementprice};
            $overduefines = $s->{overduefines};
            $invoicefine = $s->{invoicefine};

        }
    }
    
    return ($addreferencenumber, $increment, $debarment, $addreplacementprice, $overduefines, $invoicefine);
}

sub get_branch_settings {
    my ( $userbranch ) = @_;

    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("SELECT categorycode FROM branchrelations WHERE branchcode = ?");
    $sth->execute($userbranch);
    my $branchgroup;
    my @invoiceletter;
    while (my $categorycode = $sth->fetchrow_array) {
        if ($categorycode =~ /LASKU/i) {
            $branchgroup = $categorycode;
        }

        if ($categorycode =~ /Finvoice/i) {
            push @invoiceletter, 'FINVOICE';
        } elsif ($categorycode =~ /PDFBill/i) {
            push @invoiceletter,'ODUECLAIM';
        }
        
    }
    $sth->finish;

    my @branches = Koha::LibraryCategories->find( $branchgroup )->libraries;
    my @branchcodes;
    if (@branches) {
        foreach my $branch (@branches) {
            push @branchcodes, $branch->branchcode;
        }
    } else {
        push @branchcodes, $userbranch;
    }

    return {librarygroup => $branchgroup, libraries => \@branchcodes, invoiceletters => \@invoiceletter};
}

sub check_overdue_rules {
    my ( $branch, $delaymonths ) = @_;

    my %delay;
    my $fine;
    my $delayperiod;
    my $delaytime;
    my @categorycodes;

    my $dbh = C4::Context->dbh;
    my $sth;
    $sth = $dbh->prepare("SELECT * FROM overduerules WHERE branchcode = ?");
    $sth->execute($branch);
    if (my $data = $sth->fetchrow_hashref) {
        push @categorycodes, $data->{categorycode};
        while (my $row = $sth->fetchrow_hashref) {
            push @categorycodes, $row->{categorycode};
        }
        if ($data->{delay3}) {
            $delaytime = $data->{delay3};
            $delayperiod = '3';
            $fine = $data->{fine3};
        } elsif ($data->{delay2}) {
            $delaytime =$data->{delay2};
            $delayperiod= '2';
            $fine = $data->{fine2};
        } elsif ($data->{delay1}) {
            $delaytime =$data->{delay1};
            $delayperiod = '1';
            $fine = $data->{fine1};
        }
        $sth->finish;
    } else {
        my $isth = $dbh->prepare("SELECT * FROM overduerules");
        $isth->execute();
        if (my $idata = $isth->fetchrow_hashref) {
            push @categorycodes, $idata->{categorycode};
            while (my $row = $isth->fetchrow_hashref) {
                push @categorycodes, $row->{categorycode};
            }
            if ($idata->{delay3}) {
                $delaytime = $idata->{delay3};
                $delayperiod = '3';
                $fine = $idata->{fine3};
            } elsif ($idata->{delay2}) {
                $delaytime = $idata->{delay2};
                $delayperiod = '2';
                $fine = $idata->{fine2};
            } elsif ($idata->{delay1}) {
                $delaytime = $idata->{delay1};
                $delayperiod = '1';
                $fine = $idata->{fine1};
            }
        }
        $isth->finish;
    }

    $delay{delaytime} = $delaytime;
    $delay{delayperiod} = $delayperiod;
    $delay{delayfine} = $fine;
    $delay{delaymonths} = 0+$delaymonths;
    $delay{categorycodes} = \@categorycodes;

    return \%delay;

}
