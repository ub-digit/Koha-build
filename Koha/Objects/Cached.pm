package Koha::Objects::Cached;

use parent qw( Koha::Objects Koha::Objects::Cached::Base );
use Modern::Perl;

=head1 NAME

Koha::Object::Cached

=head1 SYNOPSIS

    package Koha::Foo;

    use parent qw( Koha:Objects::Cached );

=head1 API

=head2 Class Methods

=cut

=head3 find

Overloaded I<find> method that provides in memory caching by arguments.

=cut

sub find {
    my ($class, @args) = @_;
    my $cache_key = $class->_objects_cache_cache_key('find', @args);
    # Store in the args bucket if has column value condiditions
    # or for some reason the attributes argument is provided
    my $has_options = @args > 1 && ref $args[$#args] eq 'HASH';
    my $cache = !($has_options && defined $args[$#args]->{cache} && !$args[$#args]->{cache});
    my $cache_bucket = ref $args[0] eq 'HASH' || $has_options ? 'args' : 'ids';
    my $object;
    if ($cache) {
        $object = $class->_objects_cache_get($cache_key, $cache_bucket);
    }
    if (!defined $object) {
        $object = $class->SUPER::find(@args);
        $object //= 'undef';
        $class->_objects_cache_set($cache_key, $object, $cache_bucket) if $cache;
    }
    elsif ($object ne 'undef' && defined $object->{'_cache'}) {
        # Clear object cache if set
        delete $object->{'_cache'};
    }
    return $object eq 'undef' ? undef : $object;
}

=head3 search

Overloaded I<search> method that provides in memory caching by arguments.

=cut

sub search {
    my ($class, $cond, $attrs) = @_;
    my $has_resultset = ref($class) && $class->{_resultset};
    $attrs //= {};
    $attrs->{cache} //= 1 unless $has_resultset;

    if ($has_resultset || !$attrs->{cache}) {
        return $class->SUPER::search($cond, $attrs);
    }
    else {
        my @args;
        push(@args , $cond) if defined $cond;
        # Don't include if only contains "cache" key
        push(@args, $attrs) unless keys %{$attrs} == 1 && defined $attrs->{cache};
        my $cache_key = $class->_objects_cache_cache_key('search', @args);
        my $objects = $class->_objects_cache_get($cache_key, 'args');
        if ($objects) {
            $objects->reset;
        }
        else {
            $objects = $class->SUPER::search($cond, $attrs);
            $class->_objects_cache_set($cache_key, $objects, 'args');
        }
        return $objects;
    }
}

=head1 AUTHOR

David Gustafsson <david.gustafsson@ub.gu.se>

=cut

1;
