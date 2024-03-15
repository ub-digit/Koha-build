package Koha::Object::CachedFindExpiration;

use parent qw( Koha::Object Koha::CachedFind::Base );
use Modern::Perl;
use Data::Dumper;

=head1 NAME

Koha::Object::CachedFindExpiration

=head1 SYNOPSIS

    package Koha::Foo;

    use parent qw( Koha::Object::CachedFindExpiration );

=head1 API

=head2 Public methods

=head3 delete

=cut

sub delete {
    my ($self) = @_;
    $self->_find_cache_expire();
    $self->SUPER::delete();
}

# Not sure if necessary
sub store {
    my ($self) = @_;
    $self->_find_cache_expire();
    $self->SUPER::store();
}

sub _find_cache_expire {
    my ($self) = @_;
    my @primary_keys = $self->_result->id;
    my $cache_key = $self->_find_cache_cache_key(@primary_keys);
    $self->_find_cache_ids_cache_clear($cache_key);
    $self->_find_cache_args_cache_clear();
}

=head1 AUTHOR

Koha Development Team <http://koha-community.org/>

=cut

1;
