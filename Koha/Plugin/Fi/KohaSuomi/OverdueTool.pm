package Koha::Plugin::Fi::KohaSuomi::OverdueTool;

## It's good practice to use Modern::Perl
use Modern::Perl;

## Required for all plugins
use base qw(Koha::Plugins::Base);

## We will also need to include any Koha libraries we want to access
use C4::Context;
use Koha::DateUtils qw( dt_from_string );
use utf8;
use JSON;

## Here we set our plugin version
our $VERSION = "2.1.0";

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    author          => 'Johanna Räisä',
    date_authored   => '2020-12-28',
    date_updated    => "2025-03-05",
    minimum_version => '21.11.00.000',
    maximum_version => undef,
    version         => $VERSION,
};

sub get_localized_metadata {
    my ($self) = @_;
    my $lang = C4::Languages::getlanguage() || 'en';
    my ($name, $description);

    if ( $lang eq 'sv-SE' ) {
        $name = "Faktureringverktyg";
        $description = "Faktureringsverktyg för att skicka fakturor. (Lokala databaser)";
    } elsif ( $lang eq 'fi-FI' ) {
        $name = "Laskutustyökalu";
        $description = "Laskutustyökalu laskujen lähetykseen. (Paikalliskannat)";
    } else {
        $name = "Invoicing tool";
        $description = "Invoicing tool for sending invoices. (Local databases)";
    }
    return ($name, $description);
}

## This is the minimum code required for a plugin's 'new' method
## More can be added, but none should be removed
sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    ## Here, we call the 'new' method for our base class
    ## This runs some additional magic and checking
    ## and returns our actual $self
    my $self = $class->SUPER::new($args);

    my ($name, $description) = $self->get_localized_metadata();
    $self->{'metadata'}->{'name'} = $name;
    $self->{'metadata'}->{'description'} = $description;

    return $self;
}

## The existance of a 'report' subroutine means the plugin is capable
## of running a report. This example report can output a list of patrons
## either as HTML or as a CSV file. Technically, you could put all your code
## in the report method, but that would be a really poor way to write code
## for all but the simplest reports

sub tool {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $user = C4::Context->userenv;
    my @patrons = split(',', $self->retrieve_data('allowedpatrons'));
    my $allow = $user->{'flags'} == 1 ? 1 : 0;

    foreach my $borrowernumber (@patrons) {
        if ($borrowernumber eq $user->{'number'}) {
            $allow = 1;
            last;
        }
    }

    if ($allow) {
        my $template = $self->get_template({ file => 'tool.tt' });
        print $cgi->header(-charset    => 'utf-8');
        print $template->output();
    } else {
        print $cgi->header(-type => 'text/plain', -status => '403 Forbidden');
    }
    
}

sub configure {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $template = $self->get_template({ file => 'config.tt' });
    print $cgi->header(-charset    => 'utf-8');
    print $template->output();

}

## This is the 'install' method. Any database tables or other setup that should
## be done when the plugin if first installed should be executed in this method.
## The installation method should always return true if the installation succeeded
## or false if it failed.
sub install() {
    my ( $self, $args ) = @_;

    $self->table_inserts();
    
}

## This is the 'upgrade' method. It will be triggered when a newer version of a
## plugin is installed over an existing older version of a plugin
sub upgrade {
    my ( $self, $args ) = @_;

    return 1;
}

## This method will be run just before the plugin files are deleted
## when a plugin is uninstalled. It is good practice to clean up
## after ourselves!
sub uninstall() {
    my ( $self, $args ) = @_;

    $self->table_deletes();
}

sub api_routes {
    my ( $self, $args ) = @_;

    my $spec_str = $self->mbf_read('openapi.json');
    my $spec     = decode_json($spec_str);

    return $spec;
}

sub api_namespace {
    my ( $self ) = @_;
    
    return 'kohasuomi';
}

sub after_circ_action {
    my ( $self, $params ) = @_;

    # Only run on checkin actions, ignore checkouts and other actions
    return unless $params->{action} eq 'checkin';

    my $checkout = $params->{payload}->{checkout};
    my $borrowernumber = $checkout->borrowernumber;
    my $itemnumber = $checkout->itemnumber;

    # The notforloan value that indicates an item has been invoiced
    my $invoicedstatus = $self->retrieve_data('invoicenotforloan') || 6;

    my $dbh = C4::Context->dbh;

    # 1) Check if the returned item is invoiced (notforloan matches configured value).
    #    If not, this plugin has nothing to do.
    my $sth_item = $dbh->prepare("SELECT notforloan FROM items WHERE itemnumber = ?");
    $sth_item->execute($itemnumber);
    my ($notforloan) = $sth_item->fetchrow_array();
    return unless defined $notforloan && $notforloan == $invoicedstatus;

    # 2) Check if the patron has a debarment created by this plugin
    #    (type OVERDUES with the Finnish comment for invoiced material).
    #    If no matching debarment exists, nothing to remove.
    my $sth_debarment = $dbh->prepare(
        "SELECT borrower_debarment_id FROM borrower_debarments WHERE borrowernumber = ? AND type = 'OVERDUES' AND comment = 'Lainauskielto laskutetusta aineistosta'"
    );
    $sth_debarment->execute($borrowernumber);
    my ($debarment_id) = $sth_debarment->fetchrow_array();
    return unless $debarment_id;

    # 3) Check if the patron still has any overdue loans.
    #    If yes, keep the debarment — it serves a purpose.
    my $sth_overdue = $dbh->prepare(
        "SELECT 1 FROM issues JOIN items ON issues.itemnumber = items.itemnumber WHERE issues.borrowernumber = ? AND issues.date_due < NOW() LIMIT 1"
    );
    $sth_overdue->execute($borrowernumber);
    return if $sth_overdue->fetchrow_array();

    # 4) Check if the patron still has other invoiced items checked out.
    #    If yes, keep the debarment — those items may also need invoicing.
    my $sth_invoiced = $dbh->prepare(
        "SELECT 1 FROM issues JOIN items ON issues.itemnumber = items.itemnumber WHERE issues.borrowernumber = ? AND items.notforloan = ? LIMIT 1"
    );
    $sth_invoiced->execute($borrowernumber, $invoicedstatus);
    return if $sth_invoiced->fetchrow_array();

    # 5) All conditions met: remove all matching debarments for this patron.
    my $sth_delete = $dbh->prepare(
        "DELETE FROM borrower_debarments WHERE borrowernumber = ? AND type = 'OVERDUES' AND comment = 'Lainauskielto laskutetusta aineistosta'"
    );
    $sth_delete->execute($borrowernumber);

    # 6) Clear the debarred fields on the borrower record.
    my $sth_update = $dbh->prepare(
        "UPDATE borrowers SET debarred = NULL, debarredcomment = NULL WHERE borrowernumber = ? AND debarred IS NOT NULL"
    );
    $sth_update->execute($borrowernumber);

    return 1;
}

sub table_inserts {
    my ( $self ) = @_;

    my $dbh = C4::Context->dbh;
    $dbh->do("INSERT IGNORE INTO message_transport_types (message_transport_type) VALUES ('finvoice');");
    $dbh->do("INSERT IGNORE INTO message_transport_types (message_transport_type) VALUES ('pdf');");
    $dbh->do("INSERT IGNORE INTO plugin_data (plugin_class,plugin_key,plugin_value) VALUES ('Koha::Plugin::Fi::KohaSuomi::OverdueTool','invoicenumber','1');");
}

sub table_deletes {
    my ( $self ) = @_;

    my $dbh = C4::Context->dbh;
    $dbh->do("DELETE FROM message_transport_types where message_transport_type = 'finvoice';");
    $dbh->do("DELETE FROM message_transport_types where message_transport_type = 'pdf';");
}

1;
