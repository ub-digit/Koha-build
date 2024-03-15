package Koha::Object::CachedExpiration;

use parent qw( Koha::Object Koha::Objects::Cached::Base );
use Modern::Perl;
use Data::Dumper;

=head1 NAME

Koha::Object::CachedExpiration

=head1 SYNOPSIS

    package Koha::Foo;

    use parent qw( Koha::Object::CachedExpiration );

=head1 API

=head2 Class Methods

=cut

=head3 delete

Overloaded I<delete> method for cache expiration

=cut

sub delete {
    my ($self) = @_;
    $self->_objects_cache_expire();
    $self->SUPER::delete();
}

=head3 store

Overloaded I<store> method for cache expiration

=cut

sub store {
    my ($self) = @_;
    $self->_objects_cache_expire();
    $self->SUPER::store();
}

=head2 Internal methods

=head3 _objects_cache_expire

=cut

sub _objects_cache_expire {
    my ($self) = @_;
    if ($self->_result->in_storage) {
        my @primary_keys = $self->_result->id;
        my $ids_cache_key = $self->_objects_cache_cache_key('find', @primary_keys);
        $self->_objects_cache_clear($ids_cache_key);
    }
}

=head1 AUTHOR

David Gustafsson <david.gustafsson@ub.gu.se>

=cut

1;
