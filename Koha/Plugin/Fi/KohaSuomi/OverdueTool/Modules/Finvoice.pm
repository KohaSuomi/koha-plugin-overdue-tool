package Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Finvoice;

use Modern::Perl;
use Exporter;
use XML::LibXML;
use Encode qw(decode encode);
use POSIX qw(strftime);
use Text::Unaccent;

my $fetchSSN = 1;
eval "use Koha::Plugin::Fi::KohaSuomi::SsnProvider::Modules::Database";
if ( $@ ) {
     $fetchSSN = 0;
}


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

    if ($fetchSSN) {
        require Koha::Plugin::Fi::KohaSuomi::SsnProvider::Modules::Database;
        my $ssndb = Koha::Plugin::Fi::KohaSuomi::SsnProvider::Modules::Database->new();
        my $ssnkey = $ssndb->getSSNByBorrowerNumber( $notice->{borrowernumber} );
        my $ssn = $ssndb->getSSN($ssnkey);
        $doc->findnodes("Finvoice/BuyerPartyDetails/BuyerPartyIdentifier")->[0]->appendTextNode($ssn) if $ssn;
    }

    # my $name = $doc->findnodes("Finvoice/BuyerPartyDetails/BuyerOrganisationName")->[0];
    # my $newname = _escape_string($name->textContent);
    # $name->removeChildNodes;
    # $name->appendText($newname); 

    for my $invoicerow ($doc->findnodes("Finvoice/InvoiceRow")) {
        my ($row) = $invoicerow->findnodes('ArticleName');
        my $newvalue = _escape_string($row->textContent);
        $row->removeChildNodes;
        $row->appendText($newvalue); 
    }

    return $doc;
}


sub _escape_string {
    my ($string) = @_;
    my $newstring;
    my @chars = split(//, $string);
    
    foreach my $char (@chars) {
        my $oldchar = $char;
        unless ( $char =~ /[A-Za-z0-9ÅåÄäÖöÉéÜüÁá]/ ) {
            $char = 'Z'  if $char eq 'Ʒ';
            $char = 'z'  if $char eq 'ʒ';
            $char = 'B'  if $char eq 'ß';
            $char = '\'' if $char eq 'ʻ';
            $char = 'e'  if $char eq '€';
            $char = unac_string( 'utf-8', $char ) if "$oldchar" eq "$char";
        }
        $newstring .= $char;
    }
    
    return $newstring;
}