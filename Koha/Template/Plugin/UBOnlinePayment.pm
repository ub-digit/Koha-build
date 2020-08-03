package Koha::Template::Plugin::UBOnlinePayment;
use Modern::Perl;
use Template::Plugin;
use base qw( Template::Plugin );
use C4::Koha;
use C4::Context;
sub Active {
    return C4::Context->config("online_payments");
}
sub URL {
    return C4::Context->config("online_payments_portal_url");
}

1;