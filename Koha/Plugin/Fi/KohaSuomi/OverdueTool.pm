package Koha::Plugin::Fi::KohaSuomi::OverdueTool;

## It's good practice to use Modern::Perl
use Modern::Perl;

## Required for all plugins
use base qw(Koha::Plugins::Base);

## We will also need to include any Koha libraries we want to access
use C4::Context;
use utf8;
use JSON;

## Here we set our plugin version
our $VERSION = "2.1.0";

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name            => 'Laskutustyökalu',
    author          => 'Johanna Räisä',
    date_authored   => '2020-12-28',
    date_updated    => "2025-03-05",
    minimum_version => '21.11.00.000',
    maximum_version => undef,
    version         => $VERSION,
    description     => 'Laskutustyökalu laskujen lähetykseen. (Paikalliskannat)',
};

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
