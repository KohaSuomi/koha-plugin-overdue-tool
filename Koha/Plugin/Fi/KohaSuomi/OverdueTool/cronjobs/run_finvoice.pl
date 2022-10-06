#!/usr/bin/perl -w

# Copyright 2021 Koha-Suomi Oy
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

use strict;
use warnings;

BEGIN {
    # find Koha's Perl modules
    # test carefully before changing this
    use FindBin;
    eval { require "$FindBin::Bin/../kohalib.pl" };
}

use
  CGI; # NOT a CGI script, this is just to keep C4::Templates::gettemplate happy
use C4::Context;
use Koha::DateUtils;
use C4::Letters;
use File::Spec;
use Getopt::Long;
use Data::Dumper;
use POSIX qw(strftime);
use Koha::Notice::Messages;
use XML::LibXML;
use Encode qw(decode encode);
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Copy;
use YAML::XS;
use Net::SFTP::Foreign;
use Koha::Plugins;
use Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Finvoice;


sub usage {
    print STDERR <<USAGE;
Usage: $0 OUTPUT_DIRECTORY
  Will print all waiting print notices to
  OUTPUT_DIRECTORY .

  -p --path         Config file path for sftp (Mandatory). See example file config.yaml.example.
  -c --config       Config name. See example file config.yaml.example. (Mandatory)
  -v --validate     Validate the Finvoice messages.
  --xsd             XSD file path for validation.
  --zip             Create zip from xml files
  --pretty          Create human readable xml files

USAGE
    exit $_[0];
}

my ( $help, $config, $path, $validate, $xsd, $zip, $pretty);

GetOptions(
    'h|help'     => \$help,
    'p|path=s'   => \$path,
    'c|config=s' => \$config,
    'v|validate' => \$validate,
    'xsd=s'      => \$xsd,
    'zip'        => \$zip,
    'pretty'     => \$pretty
) || usage(1);

usage(0) if ($help);

my $output_directory = $ARGV[0];

if ( !$output_directory || !-d $output_directory || !-w $output_directory ) {
    print STDERR
"Error: You must specify a valid and writeable directory to dump the print notices in.\n";
    usage(1);
}

if(!$path) {
    print "Define config file output path for sftp\n";
    exit;
}

if(!$config) {
    print "Define config name\n";
    exit;
}

if ($validate && !$xsd) {
    print "Define path to xsd file\n";
    exit;
}

my $configfile = eval { YAML::XS::LoadFile($path) };
exit unless $configfile->{$config};
my $finvoiceconfig = $configfile->{$config};

my @librarycodes = $finvoiceconfig->{libraries};

if(!@librarycodes) {
    print "Define librarycodes to config file\n";
    exit;
}

my $today     = Koha::DateUtils::dt_from_string()->ymd;
my $notices = Koha::Notice::Messages->search({letter_code => 'ODUECLAIM', message_transport_type => 'finvoice', status => 'pending', from_address => {'=' => [@librarycodes]}});
exit unless $notices;

my $tmppath = $output_directory ."/tmp/";

my @message_ids;
foreach my $notice (@{$notices->unblessed}) {
    my $patron = Koha::Patrons->find($notice->{borrowernumber});
    my $doc = process_xml($notice);
    my $xmlschema = XML::LibXML::Schema->new(location => $xsd);
	eval {$xmlschema->validate($doc);};
    if ($@ && $validate) {
        print "$notice->{message_id} failed with $@\n";
        C4::Letters::_set_message_status(
        { message_id => $notice->{message_id}, status => 'failed', delivery_note => "Finvoice template error, check the logs." } );
    } else {
        my $xmlFile = $notice->{from_address}.'_'.$notice->{message_id}."_".$today. ".xml";
        #Write xml to file
        open(my $fh, '>', $tmppath.$xmlFile);
        print $fh $doc->toString($pretty);
        close $fh;
        push @message_ids, $notice->{message_id};
    }

}
if (@message_ids) {

    chdir $tmppath;
    my @files = <*.xml>;
    my $archivepath = $output_directory.'/archived/';
    if ($zip) {
        my $zipwrite = Archive::Zip->new();
        my $zipFile = $config."-kirjasto-finvoice-".$today. ".zip";
        foreach my $file (@files) {
            $zipwrite->addFile( $file );
        }

        unless ( $zipwrite->writeToFileNamed($tmppath . $zipFile) == AZ_OK ) {
            die 'error creating zip-file';
        }

        foreach my $file (@files) {
            unlink $file;
        }

        my @zipfiles = <*.zip>;

        foreach my $file (@zipfiles) {
            sftp_transfer($file, $archivepath.$file);
        }
    } else {

        foreach my $file (@files) {
            sftp_transfer($file, $archivepath.$file);
        }
    }

    foreach my $message_id (@message_ids) {
        C4::Letters::_set_message_status(
            { message_id => $message_id, status => 'sent'} );
    }
} else {
    print "Not any notices processed\n";
}

sub sftp_transfer {
    my ($file, $archivepath) = @_;

    # Connect and send with SFTP
    my $sftp = Net::SFTP::Foreign->new('host' => $finvoiceconfig->{host}, 
                                       'port' => $finvoiceconfig->{port} || '22', 
                                       'user' => $finvoiceconfig->{username},
                                       'password' => $finvoiceconfig->{password});

    if ( $sftp->error ) {
        die "Logging in to SFTP server failed with: ".$sftp->error."\n";
    }

    unless ( $sftp->put($tmppath.$file, $finvoiceconfig->{filepath}.$file.'.part', copy_perms => 0, copy_time => 0)) {
        die "Transferring file to SFTP server failed with: ".$sftp->error."\n";
    }

    unless ( $sftp->rename($finvoiceconfig->{filepath}.$file.'.part', $finvoiceconfig->{filepath}.$file)) {
        die "Renaming a file on SFTP server failed with: ".$sftp->error."\n";
    }


    move ("$tmppath$file", "$archivepath") or die "The move operation failed: $!";

}