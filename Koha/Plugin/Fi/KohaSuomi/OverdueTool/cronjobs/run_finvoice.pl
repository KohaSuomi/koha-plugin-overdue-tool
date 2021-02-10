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
use Koha::Plugins;
use Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Finvoice;


sub usage {
    print STDERR <<USAGE;
Usage: $0 OUTPUT_DIRECTORY
  Will print all waiting print notices to
  OUTPUT_DIRECTORY/branchcode-CURRENT_DATE.pdf .

  -l --library  Get print notices by branchcode, can be repeated.
  -m --message  Choose which messages are printed, can be repeated.

USAGE
    exit $_[0];
}

my ( $stylesheet, $help, @branchcodes, @messagecodes, $claiming);

GetOptions(
    'h|help'  => \$help,
    'library=s' => \@branchcodes,
    'message=s' => \@messagecodes,
) || usage(1);

usage(0) if ($help);

my $output_directory = $ARGV[0];

if ( !$output_directory || !-d $output_directory || !-w $output_directory ) {
    print STDERR
"Error: You must specify a valid and writeable directory to dump the print notices in.\n";
    usage(1);
}

my $today     = output_pref( { dt => dt_from_string, dateonly => 1, dateformat => 'iso' } ) ;
my $notices = Koha::Notice::Messages->search({letter_code => 'FINVOICE', status => 'pending'});
my $xsd = "$FindBin::Bin/../finvoice/Finvoice3.0.xsd";
my $tmppath = $output_directory ."/tmp/";
exit unless ($notices);

my @message_ids;
foreach my $notice (@{$notices->unblessed}) {
    # $notice->{content} =~ s/&/&amp;/sg;
    my $doc = process_xml($notice);
    my $xmlschema = XML::LibXML::Schema->new(location => $xsd);
	eval {$xmlschema->validate($doc);};
    if ($@) {
        print "$notice->{message_id} failed with $@\n";
        C4::Letters::_set_message_status(
        { message_id => $notice->{message_id}, status => 'failed', delivery_note => "Finvoice template error, check logs." } );
    } else {
        my $xmlFile = $notice->{from_address}.'_'.$notice->{borrowernumber}."_".$today. ".xml";
        #Write xml to file
        open(my $fh, '>', $tmppath.$xmlFile);
        print $fh $doc->toString();
        close $fh;
        push @message_ids, $notice->{message_id};
    }

}
if (@message_ids) {
    my $zip = Archive::Zip->new();
    my $zipFile = "kirjasto-finvoice-".$today. ".zip";

    chdir $tmppath;
    my @files = <*.xml>;

    foreach my $file (@files) {
        $zip->addFile( $file );
    }

    unless ( $zip->writeToFileNamed($tmppath . $zipFile) == AZ_OK ) {
        die 'error creating zip-file';
    }

    foreach my $file (@files) {
        unlink $file;
    }

    my @zipfiles = <*.zip>;
    my $archivepath = $output_directory.'/archived/';
    foreach my $file (@zipfiles) {

    #   system ("sshpass -p $providerConfig->{pw} sftp $providerConfig->{user}\@$providerConfig->{host} > /dev/null 2>&1 << EOF
    # 	cd IN
    # 	put $tmppath$file
    # 	bye
    # 	EOF") == 0 or die "system failed: $!";

    move ("$tmppath$file", "$archivepath$file") or die "The move operation failed: $!";

    }

    foreach my $message_id (@message_ids) {
        C4::Letters::_set_message_status(
            { message_id => $message_id, status => 'sent'} );
    }
} else {
    print "Not any notices processed\n";
}