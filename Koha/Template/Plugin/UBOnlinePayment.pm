package Koha::Template::Plugin::UBOnlinePayment;
use Modern::Perl;
use Template::Plugin;
use base qw( Template::Plugin );
use C4::Koha;
use Koha::Patrons;
use C4::Context;

sub Active {
    return C4::Context->config("online_payments");
}
sub URL {
    return C4::Context->config("online_payment_portal_url");
}

sub ExternalInfoURLSv {
    return C4::Context->config("online_payment_info_url_sv");
}

sub ExternalInfoURLEn {
    return C4::Context->config("online_payment_info_url_en");
}


sub isExcludedFromOnlinePayment {
    my $borrowernumber = C4::Context->userenv->{number};
    my $patron = Koha::Patrons->find( $borrowernumber );
    my $categorycode = $patron->categorycode;
    my $strCategories = C4::Context->config("online_payment_exclude_patron_categories");
    my @categories = split(/\|/, $strCategories);
    if (grep { $_ eq $categorycode } @categories) {
        return 1;
    }
    return 0;
}


1;