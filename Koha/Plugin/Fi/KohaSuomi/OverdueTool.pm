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
our $VERSION = "1.6.6";

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name            => 'Laskutustyökalu',
    author          => 'Johanna Räisä',
    date_authored   => '2020-12-28',
    date_updated    => "2022-02-07",
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

sub api {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};
    my $data = JSON::decode_json($cgi->param('POSTDATA'));
    $self->store_data(
        {
            delaymonths           => $data->{'params'}->{'delaymonths'},
            maxyears              => $data->{'params'}->{'maxyears'},
            invoicelibrary        => $data->{'params'}->{'invoicelibrary'},
            invoicenotforloan     => $data->{'params'}->{'invoicenotforloan'},
            groupsettings         => $data->{'params'}->{'groupsettings'},

        }
    );

    print $cgi->header( -type => 'text/json', -charset => 'UTF-8' );
    print JSON::to_json({message => 'success'});
    exit 0;
}

sub configure {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $template = $self->get_template({ file => 'config.tt' });
    my $settings = $self->retrieve_data('groupsettings') ? JSON::from_json($self->retrieve_data('groupsettings')) : [];
    my $groupsettings = set_group_settings($settings);

    my $json = {
        delaymonths => $self->retrieve_data('delaymonths'),
        maxyears => $self->retrieve_data('maxyears'),
        invoicelibrary => $self->retrieve_data('invoicelibrary'),
        invoicenotforloan => $self->retrieve_data('invoicenotforloan'),
        groupsettings => $groupsettings
    };
    $template->param(
        data => JSON::to_json($json),
    );

    print $cgi->header(-charset    => 'utf-8');
    print $template->output();

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
    my $groupsettings = $self->retrieve_data('groupsettings') || '[]';
    my $overduerules = check_overdue_rules($branch, $self->retrieve_data("delaymonths"));
    my $newsettings = get_group_settings(JSON::from_json($groupsettings), $branchsettings->{librarygroup});
    
    my $json = {
        userlibrary => $branch,
        maxyears => $self->retrieve_data('maxyears'),
        libraries => $branchsettings->{libraries},
        librarygroup => $branchsettings->{librarygroup},
        invoiceletters => $branchsettings->{invoiceletters},
        overduerules => $overduerules,
        invoicelibrary => $self->retrieve_data('invoicelibrary'),
        invoicenotforloan => $self->retrieve_data('invoicenotforloan'),
        debarment => $newsettings->{debarment},
        addreplacementprice   => $newsettings->{addreplacementprice},
        addreferencenumber  => $newsettings->{addreferencenumber},
        increment   => $newsettings->{increment},
        overduefines => $newsettings->{overduefines},
        invoicefine => $newsettings->{invoicefine},
        accountnumber => $newsettings->{accountnumber},
        biccode => $newsettings->{biccode},
        businessid => $newsettings->{businessid},
        patronmessage => $newsettings->{patronmessage}, 
        guaranteemessage => $newsettings->{guaranteemessage},
        grouplibrary => $newsettings->{grouplibrary},
        groupaddress => $newsettings->{groupaddress},
        groupzipcode => $newsettings->{groupzipcode}, 
        groupcity => $newsettings->{groupcity},
        groupphone => $newsettings->{groupphone},

    };
    $template->param(
        data => JSON::to_json($json)
    );

    print $cgi->header(-charset    => 'utf-8');
    print $template->output();
}

1;
