package Koha::Plugin::Fi::KohaSuomi::OverdueTool;

## It's good practice to use Modern::Perl
use Modern::Perl;

## Required for all plugins
use base qw(Koha::Plugins::Base);

## We will also need to include any Koha libraries we want to access
use C4::Context;
use utf8;
use JSON;

use Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Config;

## Here we set our plugin version
our $VERSION = "1.0";

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name            => 'Laskutustyökalu',
    author          => 'Johanna Räisä',
    date_authored   => '2020-12-28',
    date_updated    => "2020-12-28",
    minimum_version => '17.05.00.000',
    maximum_version => undef,
    version         => $VERSION,
    description     => 'Laskutustyökalu laskujen lähetykseen',
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

    $self->tool_view();
}

## If your tool is complicated enough to needs it's own setting/configuration
## you will want to add a 'configure' method to your plugin like so.
## Here I am throwing all the logic into the 'configure' method, but it could
## be split up like the 'report' method is.
sub configure {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    unless ( $cgi->param('save') ) {
        my $template = $self->get_template({ file => 'configure.tt' });

        ## Grab the values we already have for our settings, if any exist
        $template->param(
            delaymonths => $self->retrieve_data('delaymonths'),
            maxyears => $self->retrieve_data('maxyears'),
            invoicelibrary => $self->retrieve_data('invoicelibrary'),
            invoicenotforloan => $self->retrieve_data('invoicenotforloan'),
            debarment => $self->retrieve_data('debarment'),
            addreplacementprice   => $self->retrieve_data('addreplacementprice'),

        );

        print $cgi->header(-charset    => 'utf-8');
        print $template->output();
    }
    else {
        $self->store_data(
            {
                delaymonths           => $cgi->param('delaymonths'),
                maxyears              => $cgi->param('maxyears'),
                invoicelibrary        => $cgi->param('invoicelibrary'),
                invoicenotforloan     => $cgi->param('invoicenotforloan'),
                debarment             => $cgi->param('debarment'),
                addreplacementprice   => $cgi->param('addreplacementprice'),

            }
        );
        $self->go_home();
    }
}

## This is the 'install' method. Any database tables or other setup that should
## be done when the plugin if first installed should be executed in this method.
## The installation method should always return true if the installation succeeded
## or false if it failed.
sub install() {
    my ( $self, $args ) = @_;

    return 1;
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

    return 1;
}

sub tool_view {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};
    my $template = $self->get_template({ file => 'tool.tt' });

    my $branch = C4::Context->userenv->{'branch'};
    my $branchsettings = get_branch_settings($branch);
    my $overduerules = check_overdue_rules($branch, $self->retrieve_data("delaymonths"));

    my $json = {
        userlibrary => $branch,
        maxyears => $self->retrieve_data('maxyears'),
        libraries => $branchsettings->{libraries},
        invoiceletters => $branchsettings->{invoiceletters},
        overduerules => $overduerules,
        invoicelibrary => $self->retrieve_data('invoicelibrary'),
        invoicenotforloan => $self->retrieve_data('invoicenotforloan'),
        debarment => $self->retrieve_data('debarment'),
        addreplacementprice   => $self->retrieve_data('addreplacementprice'),
    };
    $template->param(
        data => JSON::to_json($json)
    );

    print $cgi->header(-charset    => 'utf-8');
    print $template->output();
}

1;
