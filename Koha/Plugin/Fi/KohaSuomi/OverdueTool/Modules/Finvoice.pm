package Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Finvoice;

use utf8;
use Modern::Perl;
use Exporter;
use XML::LibXML;
use XML::LibXSLT;
use Encode qw(decode encode);
use POSIX qw(strftime);
use Text::Unaccent;
use C4::Context;
use Koha::DateUtils qw( dt_from_string );

my $fetchSSN = 1;
eval "use Koha::Plugin::Fi::KohaSuomi::SsnProvider::Modules::Database";
if ( $@ ) {
     $fetchSSN = 0;
}


our @ISA = qw(Exporter);
our @EXPORT = qw(process_xml finvoice_to_html);

sub process_xml {
    my ( $notice, $noescape, $testssn ) = @_;

    my $parser = XML::LibXML->new(recover => 1);
    $notice->{content} =~ s/&/&amp;/sg;
    my $data = Encode::encode( "iso-8859-15", $notice->{content});
    my $doc = $parser->load_xml(string => $data);
    my $timestamp = strftime "%Y-%m-%dT%H:%M:%S%z", localtime;
    $timestamp = substr $timestamp, 0, -2;
    $timestamp .= ':00';
    $doc->findnodes("Finvoice/MessageTransmissionDetails/MessageDetails/MessageIdentifier")->[0]->appendTextNode($notice->{message_id});
    $doc->findnodes("Finvoice/MessageTransmissionDetails/MessageDetails/MessageTimeStamp")->[0]->appendTextNode($timestamp);
    my $ssn;

    if ($fetchSSN) {
        require Koha::Plugin::Fi::KohaSuomi::SsnProvider::Modules::Database;
        my $ssndb = Koha::Plugin::Fi::KohaSuomi::SsnProvider::Modules::Database->new();
        $ssn = $ssndb->getSSNByBorrowerNumber( $notice->{borrowernumber} );
    }

    if (!$ssn && $testssn) {
        require Koha::Plugin::Fi::KohaSuomi::SsnProvider::Modules::TestSSN;
        my $testssn = eval { Koha::Plugin::Fi::KohaSuomi::SsnProvider::Modules::TestSSN->new() };
        if ($@) {
            die "Could not load TestSSN module: $@";
        }
        $ssn = $testssn->generate($notice->{borrowernumber});
        print "Generated test SSN: $ssn for borrowernumber: $notice->{borrowernumber}\n" if $ssn;
    }

    $doc->findnodes("Finvoice/BuyerPartyDetails/BuyerPartyIdentifier")->[0]->appendTextNode($ssn) if $ssn;

    # my $name = $doc->findnodes("Finvoice/BuyerPartyDetails/BuyerOrganisationName")->[0];
    # my $newname = _escape_string($name->textContent);
    # $name->removeChildNodes;
    # $name->appendText($newname); 

    for my $invoicerow ($doc->findnodes("Finvoice/InvoiceRow")) {
        my ($row) = $invoicerow->findnodes('ArticleName');
        my $newvalue = !$noescape ? _escape_string($row->textContent) : $row->textContent;
        my $max_length = 99;
        if(length($newvalue) > $max_length){
            # if the string is longer than the max length, truncate it
            my $diff = $max_length - length($newvalue);
            $newvalue = substr($newvalue, 0, $diff);
        }
        $row->removeChildNodes;
        $row->appendText($newvalue);
        # Remove RowIdentifierDate, not sure if this is creating an error in the invoice processing
        my ($daterow) = $invoicerow->findnodes('RowIdentifierDate');
        $daterow->parentNode->removeChild($daterow) if $daterow;
    }

    return $doc;
}

sub finvoice_to_html {
    my ($notice, $patron) = @_;

    my $xslt = XML::LibXSLT->new();
    my $parser = XML::LibXML->new();

    my $plugin_path = C4::Context->config('pluginsdir') . '/Koha/Plugin/Fi/KohaSuomi/OverdueTool/finvoice/finvoice-to-html.xsl';
    my $style_doc = $parser->parse_file($plugin_path);
    my $stylesheet = $xslt->parse_stylesheet($style_doc);
    my $finvoice = $notice->{content};
    $finvoice =~ s/encoding="ISO-8859-15"/encoding="UTF-8"/;
    my $xml_doc = $parser->parse_string($finvoice);
    my $message_timestamp = $xml_doc->findnodes('//MessageDetails/MessageTimeStamp')->[0];
    if ($message_timestamp) {
        $message_timestamp->removeChildNodes();
        $message_timestamp->appendText(dt_from_string($notice->{updated_on})->strftime('%d.%m.%Y'));
    };

    my $message_invoicedate = $xml_doc->findnodes('//InvoiceDetails/PaymentTermsDetails/InvoiceDueDate')->[0];
    if ($message_invoicedate) {
        my $invoice_date = $message_invoicedate->textContent;
        if ($invoice_date) {
            $message_invoicedate->removeChildNodes();
            $message_invoicedate->appendText(_convert_finvoice_date($invoice_date));
        }
    }

    my $date_rows = $xml_doc->findnodes('//InvoiceRow/RowIdentifierDate');
    foreach my $date_row ($date_rows->get_nodelist) {
        my $date = $date_row->textContent;
        if ($date) {
            $date_row->removeChildNodes();
            $date_row->appendText(_convert_finvoice_date($date));
        }
    }
    my $borrower_name = $xml_doc->createElement('BuyerContactPersonName');
    $borrower_name->appendText($patron->firstname . ' ' . $patron->surname . ' (' . $patron->cardnumber . ')');
    my $buyer_party_details = $xml_doc->findnodes('//BuyerPartyDetails')->[0];
    $buyer_party_details->appendChild($borrower_name) if $buyer_party_details;

    my $buyer_name = $xml_doc->findnodes('//BuyerPartyDetails/BuyerOrganisationName')->[0];
    if ($buyer_name) {
        my $newname = $buyer_name->textContent;
        $newname =~ s/^(\S+)\s+(\S+)/$1 . ' ' . uc($2)/e;
        $buyer_name->removeChildNodes;
        $buyer_name->appendText($newname);
    }

    my $results = $stylesheet->transform($xml_doc);
    my $html = $stylesheet->output_string($results);

    # Ensure the HTML is treated as UTF-8
    $html = Encode::decode('UTF-8', $html);

    return $html;
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

sub _convert_finvoice_date {
    my ($date) = @_;
    my ($year, $month, $day) = $date =~ /^(\d{4})(\d{2})(\d{2})$/;
    return "$day.$month.$year";
}

1;