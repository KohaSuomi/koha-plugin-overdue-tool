#!/usr/bin/perl

use Modern::Perl;
use FindBin qw($Bin);
use lib "$Bin/../../../../../..";

use Test::More;
use Test::MockModule;
use Test::MockObject;

use C4::Context;
use Koha::Database;
use Koha::DateUtils qw(dt_from_string);
use t::lib::TestBuilder;

my $schema = Koha::Database->new->schema;
my $builder = t::lib::TestBuilder->new;

use_ok('Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Finvoice');

my $finvoice_xml = <<'END_XML';
<?xml version="1.0" encoding="ISO-8859-15"?>
<Finvoice>
  <MessageTransmissionDetails>
    <MessageDetails>
      <MessageIdentifier/>
      <MessageTimeStamp/>
    </MessageDetails>
  </MessageTransmissionDetails>
  <SellerPartyDetails>
    <SellerOrganisationName>SELLER NAME HERE</SellerOrganisationName>
    <SellerStreetName>Testikatu 1</SellerStreetName>
    <SellerPostCodeIdentifier>00100</SellerPostCodeIdentifier>
    <SellerTownName>Helsinki</SellerTownName>
    <SellerPartyIdentifier>1234567-8</SellerPartyIdentifier>
  </SellerPartyDetails>
  <BuyerPartyDetails>
    <BuyerPartyIdentifier/>
    <BuyerOrganisationName>Testi Ostaja</BuyerOrganisationName>
    <BuyerStreetName>Ostajakatu 2</BuyerStreetName>
    <BuyerPostCodeIdentifier>00200</BuyerPostCodeIdentifier>
    <BuyerTownName>Helsinki</BuyerTownName>
  </BuyerPartyDetails>
  <InvoiceDetails>
    <InvoiceNumber>INV-001</InvoiceNumber>
    <PaymentTermsDetails>
      <InvoiceDueDate>20260101</InvoiceDueDate>
    </PaymentTermsDetails>
  </InvoiceDetails>
  <EpiDetails>
    <EpiRemittanceInfoIdentifier>RF123456</EpiRemittanceInfoIdentifier>
  </EpiDetails>
  <InvoiceRow>
    <ArticleName>Test Article</ArticleName>
    <ArticleIdentifier>B123</ArticleIdentifier>
    <RowFreeText>Lisatieto 1</RowFreeText>
    <UnitPriceNetAmount>5.00</UnitPriceNetAmount>
  </InvoiceRow>
  <InvoiceTotalVatIncludedAmount>5.00</InvoiceTotalVatIncludedAmount>
</Finvoice>
END_XML

sub create_notice {
    my ($content) = @_;
    return {
        content      => $content,
        message_id   => 'MSG001',
        borrowernumber => '123',
    };
}

sub build_mock_patron {
    my (%args) = @_;
    my $patron = Test::MockObject->new;
    $args{firstname}  //= 'Testi';
    $args{surname}    //= 'Asiakas';
    $args{cardnumber} //= 'C123';
    $patron->mock('firstname', sub { $args{firstname} });
    $patron->mock('surname', sub { $args{surname} });
    $patron->mock('cardnumber', sub { $args{cardnumber} });
    return $patron;
}

subtest 'Seller name unchanged when short and no parenthesis' => sub {
    plan tests => 1;
    my $notice = create_notice($finvoice_xml);
    my $doc = Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Finvoice::process_xml($notice, 0, 0);
    my $seller_name = $doc->findnodes("Finvoice/SellerPartyDetails/SellerOrganisationName")->[0]->textContent;
    is($seller_name, 'SELLER NAME HERE', 'Short name without parenthesis is unchanged');
};

subtest 'Seller name truncated at parenthesis' => sub {
    plan tests => 1;
    my $xml = $finvoice_xml;
    $xml =~ s/SELLER NAME HERE/Company Name (Oy)/;
    my $notice = create_notice($xml);
    my $doc = Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Finvoice::process_xml($notice, 0, 0);
    my $seller_name = $doc->findnodes("Finvoice/SellerPartyDetails/SellerOrganisationName")->[0]->textContent;
    is($seller_name, 'Company Name', 'Name truncated at parenthesis');
};

subtest 'Seller name truncated at 35 characters when too long' => sub {
    plan tests => 2;
    my $xml = $finvoice_xml;
    $xml =~ s/SELLER NAME HERE/Very Long Company Name That Exceeds Limit/;
    my $notice = create_notice($xml);
    my $doc = Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Finvoice::process_xml($notice, 0, 0);
    my $seller_name = $doc->findnodes("Finvoice/SellerPartyDetails/SellerOrganisationName")->[0]->textContent;
    is(length($seller_name), 35, 'Name truncated to 35 characters');
    is($seller_name, 'Very Long Company Name That Exceeds', 'Name truncated correctly');
};

subtest 'Seller name truncated at parenthesis then at 35 chars' => sub {
    plan tests => 1;
    my $xml = $finvoice_xml;
    $xml =~ s/SELLER NAME HERE/Long Name Company That Exceeds Thirty Five (Ltd)/;
    my $notice = create_notice($xml);
    my $doc = Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Finvoice::process_xml($notice, 0, 0);
    my $seller_name = $doc->findnodes("Finvoice/SellerPartyDetails/SellerOrganisationName")->[0]->textContent;
    is($seller_name, 'Long Name Company That Exceeds Thir', 'Name truncated at parenthesis first, then 35 chars');
};

subtest 'Seller name with spaces before parenthesis' => sub {
    plan tests => 1;
    my $xml = $finvoice_xml;
    $xml =~ s/SELLER NAME HERE/Company Name   (Extra Info)/;
    my $notice = create_notice($xml);
    my $doc = Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Finvoice::process_xml($notice, 0, 0);
    my $seller_name = $doc->findnodes("Finvoice/SellerPartyDetails/SellerOrganisationName")->[0]->textContent;
    is($seller_name, 'Company Name', 'Spaces before parenthesis removed');
};

subtest 'InvoiceRow ArticleName escaping' => sub {
    plan tests => 1;
    my $xml = $finvoice_xml;
    $xml =~ s/Test Article/Test & Article/;
    my $notice = create_notice($xml);
    my $doc = Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Finvoice::process_xml($notice, 0, 0);
    my $article_name = $doc->findnodes("Finvoice/InvoiceRow/ArticleName")->[0]->textContent;
    like($article_name, qr/Test.*Article/, 'ArticleName processed');
};

subtest 'RowIdentifierDate removed from InvoiceRow' => sub {
    plan tests => 1;
    my $xml = $finvoice_xml;
    $xml =~ s|<ArticleName>Test Article</ArticleName>|<ArticleName>Test</ArticleName>\n    <RowIdentifierDate>20260101</RowIdentifierDate>|;
    my $notice = create_notice($xml);
    my $doc = Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Finvoice::process_xml($notice, 0, 0);
    my $date_row = $doc->findnodes("Finvoice/InvoiceRow/RowIdentifierDate")->[0];
    ok(!$date_row, 'RowIdentifierDate removed');
};

subtest 'MessageIdentifier is set' => sub {
    plan tests => 1;
    my $notice = create_notice($finvoice_xml);
    $notice->{message_id} = 'TEST_MSG_123';
    my $doc = Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Finvoice::process_xml($notice, 0, 0);
    my $msg_id = $doc->findnodes("Finvoice/MessageTransmissionDetails/MessageDetails/MessageIdentifier")->[0]->textContent;
    is($msg_id, 'TEST_MSG_123', 'MessageIdentifier is set from notice');
};

subtest 'MessageTimeStamp is set' => sub {
    plan tests => 1;
    my $notice = create_notice($finvoice_xml);
    my $doc = Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Finvoice::process_xml($notice, 0, 0);
    my $timestamp = $doc->findnodes("Finvoice/MessageTransmissionDetails/MessageDetails/MessageTimeStamp")->[0]->textContent;
    like($timestamp, qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\+0[23]:00$/, 'MessageTimeStamp is set in ISO format');
};

subtest 'Multiple InvoiceRows are processed' => sub {
    plan tests => 2;
    my $xml = $finvoice_xml;
    $xml =~ s|</InvoiceRow>|</InvoiceRow>\n  <InvoiceRow>\n    <ArticleName>Second Article</ArticleName>\n  </InvoiceRow>|;
    my $notice = create_notice($xml);
    my $doc = Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Finvoice::process_xml($notice, 0, 0);
    my @rows = $doc->findnodes("Finvoice/InvoiceRow");
    is(scalar @rows, 2, 'Both InvoiceRows exist');
    my @articles = $doc->findnodes("Finvoice/InvoiceRow/ArticleName");
    is(scalar @articles, 2, 'Both ArticleNames exist');
};

subtest 'noescape flag prevents escaping' => sub {
    plan tests => 1;
    my $xml = $finvoice_xml;
    $xml =~ s/Test Article/Test & Article/;
    my $notice = create_notice($xml);
    my $doc = Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Finvoice::process_xml($notice, 1, 0);
    my $article_name = $doc->findnodes("Finvoice/InvoiceRow/ArticleName")->[0]->textContent;
    is($article_name, 'Test & Article', 'noescape flag preserves ampersand');
};

subtest '_escape_string handles special characters' => sub {
    plan tests => 2;
    my $result = Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Finvoice::_escape_string('Test');
    is($result, 'Test', 'Normal text unchanged');
    $result = Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Finvoice::_escape_string("Test \x{01B7}");
    like($result, qr/Test Z/, 'Ʒ converted to Z');
};

subtest '_convert_finvoice_date formats date correctly' => sub {
    plan tests => 1;
    my $result = Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Finvoice::_convert_finvoice_date('20260101');
    is($result, '01.01.2026', 'Date converted from YYYYMMDD to DD.MM.YYYY');
};

my $pluginsdir = "$Bin/../../../../../..";
my $plugin_path = $pluginsdir . '/Koha/Plugin/Fi/KohaSuomi/OverdueTool/finvoice/finvoice-to-html.xsl';
SKIP: {
    skip 'finvoice-to-html.xsl not found, cannot test finvoice_to_html', 4 unless -e $plugin_path;

    my $mock_context = Test::MockModule->new('C4::Context');
    my $original_config = \&C4::Context::config;
    $mock_context->mock('config', sub {
        my ($key) = @_;
        return $pluginsdir if $key eq 'pluginsdir';
        return $original_config->(@_);
    });

    sub create_html_notice {
        my ($content) = @_;
        return {
            content    => $content,
            updated_on => '2026-01-02 10:00:00',
        };
    }

    subtest 'finvoice_to_html transforms XML to HTML' => sub {
        plan tests => 5;
        my $notice = create_html_notice($finvoice_xml);
        my $patron = build_mock_patron();
        my $html = Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Finvoice::finvoice_to_html($notice, $patron);

        like($html, qr/Lasku/, 'HTML contains invoice header');
        like($html, qr/SELLER NAME HERE/, 'HTML contains seller organisation name');
        like($html, qr/INV-001/, 'HTML contains invoice number');
        like($html, qr/Test Article/, 'HTML contains article name');
        like($html, qr/Testi ASIAKAS \(C123\)/, 'HTML contains borrower contact person name');
    };

    subtest 'finvoice_to_html replaces MessageTimeStamp with updated_on date' => sub {
        plan tests => 1;
        my $notice = create_html_notice($finvoice_xml);
        my $patron = build_mock_patron();
        my $html = Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Finvoice::finvoice_to_html($notice, $patron);

        like($html, qr/02\.01\.2026/, 'MessageTimeStamp replaced with date from updated_on');
    };

    subtest 'finvoice_to_html converts InvoiceDueDate format' => sub {
        plan tests => 1;
        my $notice = create_html_notice($finvoice_xml);
        my $patron = build_mock_patron();
        my $html = Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Finvoice::finvoice_to_html($notice, $patron);

        like($html, qr/01\.01\.2026/, 'InvoiceDueDate converted to DD.MM.YYYY format');
    };

    subtest 'finvoice_to_html uses guarantor name when provided' => sub {
        plan tests => 1;
        my $notice = create_html_notice($finvoice_xml);
        my $patron = build_mock_patron();
        my $guarantor = build_mock_patron(
            firstname  => 'Takaaja',
            surname    => 'Vastuuhenkilo',
            cardnumber => 'C999',
        );
        my $html = Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Finvoice::finvoice_to_html($notice, $patron, $guarantor);

        like($html, qr/Takaaja VASTUUHENKILO/, 'Guarantor name used instead of patron name');
    };

    $mock_context->unmock_all;
}

done_testing();
