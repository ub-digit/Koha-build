package Koha::Template::Plugin::ExtendedAttributeProperties;
use Modern::Perl;
use Template::Plugin;
use base qw( Template::Plugin );
use C4::Context;
use Scalar::Util qw( blessed );

use Data::Dumper;

sub isVisible {
    my ($self, $attribute) = @_;

    if (getLoggedInUser()->is_superlibrarian) {return 1;}
    if (isInList($attribute->{'code'}, 'HiddenExtendedAttributes')) {return 0;}
    return 1;
}

sub isEditable {
    my ($self, $attribute) = @_;

    if (getLoggedInUser()->is_superlibrarian) {return 1;}
    if (isInList($attribute->{'code'}, 'NonEditableExtendedAttributes')) {return 0;}
    return 1;
}

sub hasSecretValue {
    my ($self, $attribute) = @_;

    if (getLoggedInUser()->is_superlibrarian) {return 0;}
    if (isInList($attribute->{'code'}, 'SecretExtendedAttributes')) {return 1;}
    return 0;
}

sub getLoggedInUser {
    my $loggedinborrowernumber = C4::Context->userenv->{'number'};
    my $loggedinuser = Koha::Patrons->find($loggedinborrowernumber);
    return $loggedinuser;
}

sub isInList {
    my ($attributecode, $prefname) = @_;

    if (C4::Context->preference($prefname)) {
        my $prefvalue = C4::Context->preference($prefname);
        my @attributes = split( /\|/, $prefvalue || q|| );
        foreach (@attributes) {
            if ($attributecode eq $_) { return 1; }
        }
    }
    return 0;
}

1;
