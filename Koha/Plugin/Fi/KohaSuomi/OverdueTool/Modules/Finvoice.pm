package Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Finvoice;

use Modern::Perl;
use Exporter;
use XML::LibXML;
use Encode qw(decode encode);
use POSIX qw(strftime);

our @ISA = qw(Exporter);
our @EXPORT = qw(process_xml);

sub process_xml {
    my ( $notice ) = @_;

    my $parser = XML::LibXML->new(recover => 1);
    my $data = Encode::encode( "iso-8859-15", $notice->{content});
    my $doc = $parser->load_xml(string => $data);
    my $timestamp = strftime "%Y-%m-%dT%H:%M:%S%z", localtime;
    $timestamp = substr $timestamp, 0, -2;
    $timestamp .= ':00';
    $doc->findnodes("Finvoice/MessageTransmissionDetails/MessageDetails/MessageIdentifier")->[0]->appendTextNode($notice->{message_id});
    $doc->findnodes("Finvoice/MessageTransmissionDetails/MessageDetails/MessageTimeStamp")->[0]->appendTextNode($timestamp);

    return $doc;
}