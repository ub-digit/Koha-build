package Koha::Template::Plugin::UBCatGroup;
use Modern::Perl;
use Template::Plugin;
use base qw( Template::Plugin );
use Koha::Patrons;
use C4::Koha;
use C4::Context;
use Data::Dumper;
use utf8;

sub getCatGroup {
    my ($self, $borrower) = @_;
    my $categorycode = $borrower->categorycode();
    my $av = Koha::AuthorisedValues->search({ category => "CATGROUP", authorised_value => $categorycode });
    if ($av->count) {
        return $av->next->lib;
    }
    else {
        # This should be handled by including all patron category codes in the authorised values table for CATGROUP
        return $categorycode;
    }
}

1;
