package Koha::Objects::CachedFind;

use parent qw( Koha::Objects Koha::CachedFind::Base );
use Modern::Perl;

=head1 NAME

Koha::Object::CachedFind

=head1 SYNOPSIS

    package Koha::Foo;

    use parent qw( Koha:Objects::CachedFind );

=head1 API

=head2 Public methods

=head3 set_additional_fields

=cut

sub find {
    my ($class, @args) = @_;
    my $object;
    my $cache_key = $class->_find_cache_cache_key(@args);

    # Stor in the args bucket if has column value condiditions
    # or for some reason the attributes argument is provided
    if (ref $args[0] eq 'HASH' || @args > 1 && ref $args[$#args] eq 'HASH') {
        $object = $class->_find_cache_args_cache_get($cache_key);
        unless ($object) {
            $object = $class->_find_cache_args_cache_get($cache_key);
            $object = $class->SUPER::find(@args);
            $class->_find_cache_args_cache_set($cache_key, $object);
        }
    }
    else {
        $object = $class->_find_cache_ids_cache_get($cache_key);
        unless ($object) {
            $object = $class->SUPER::find(@args);
            $class->_find_cache_ids_cache_set($cache_key, $object);
        }
    }
    return $object;
}

=head1 AUTHOR

Koha Development Team <http://koha-community.org/>

=cut

1;
