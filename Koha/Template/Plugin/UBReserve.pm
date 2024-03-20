package Koha::Template::Plugin::UBReserve;
use Modern::Perl;
use base qw( Template::Plugin );
use Koha::Patrons;

sub isPickup {
    my ($self, $reserve) = @_;
    return 1 if (!defined $reserve);
    my $reservenotes = $reserve->reservenotes();
    return 0 if ($reservenotes =~ /^L.netyp: Skicka/);
    my $borrowernumber = $reserve->borrowernumber();
    my $categorycode = Koha::Patrons->find($borrowernumber)->categorycode();
    return 0 if ($categorycode =~ /^B/);
    return 1;
}

1;
