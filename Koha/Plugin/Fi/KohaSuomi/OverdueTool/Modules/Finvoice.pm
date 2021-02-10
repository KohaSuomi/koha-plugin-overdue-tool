package Koha::Plugin::Fi::KohaSuomi::OverdueTool::Modules::Finvoice;

use Modern::Perl;
use Exporter;
use XML::LibXML;
use Encode qw(decode encode);

our @ISA = qw(Exporter);
our @EXPORT = qw(process_xml);

sub process_xml {
    my ( $notice ) = @_;

    my $parser = XML::LibXML->new(recover => 1);
    my $data = Encode::encode( "iso-8859-15", $notice->{content});
    my $doc = $parser->load_xml(string => $data);

    # my @articlenames = $doc->getElementsByTagName('ArticleName');

    # foreach my $articlename (@articlenames) {
    #     my $content = $articlename;
    #     $content =~ s/&/&amp;/sg;
    #     #$content =~ s/</&lt;/sg;
    #     #$content =~ s/>/&gt;/sg;
    #     #$content =~ s/"/&quot;/sg;

    #     print Data::Dumper::Dumper $content;
    # }
    

    return $doc;
}