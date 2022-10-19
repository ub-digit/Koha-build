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
    if (blessed($attribute)) {
        $attribute = $attribute->unblessed;
    }
    if (isInList($attribute->{'code'}, 'HiddenExtendedAttributes')) {return 0;}
    return 1;
}

sub isEditable {
    my ($self, $attribute) = @_;

    if (getLoggedInUser()->is_superlibrarian) {return 1;}
    if (blessed($attribute)) {
        $attribute = $attribute->unblessed;
    }
    if (isInList($attribute->{'code'}, 'NonEditableExtendedAttributes')) {return 0;}
    return 1;
}

sub hasSecretValue {
    my ($self, $attribute) = @_;

    if (getLoggedInUser()->is_superlibrarian) {return 0;}
    if (blessed($attribute)) {
        $attribute = $attribute->unblessed;
    }
    if (isInList($attribute->{'code'}, 'SecretExtendedAttributes')) {return 1;}
    return 0;
}

sub getHiddenAttributes {
    if (getLoggedInUser()->is_superlibrarian) {return "";}

    # The hidden attributes are declared as | separated list in the preferences HiddenExtendedAttributes and SecretExtendedAttributes.
    my $hidden_prefvalue = C4::Context->preference('HiddenExtendedAttributes');
    my $secret_prefvalue = C4::Context->preference('SecretExtendedAttributes');
    my @hidden_attributes = split( /\|/, $hidden_prefvalue || q|| );
    my @secret_attributes = split( /\|/, $secret_prefvalue || q|| );
    my @hidden_attributes = (@hidden_attributes, @secret_attributes);
    # Join the two lists by coma and remove duplicates
    my %seen;
    my @hidden_attributes = grep { !$seen{$_}++ } @hidden_attributes;
    return join(',', @hidden_attributes);
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
