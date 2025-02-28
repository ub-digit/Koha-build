package Koha::Objects::Cached::Base;

use Modern::Perl;
use Digest::MD5 qw( md5_hex );
use Carp        qw( croak );
use JSON;
use Data::Dumper;

use Koha::Cache::Memory::Lite;

=head1 NAME

Koha::Objects::Cached::Base

=head2 Internal methods

=head3 _objects_cache_cache_key

my $cache_key = $self->_objects_cache_cache_key($method, @args);

Get the object/objects cache key for a particular method based on the method arguments.

=over 8

=item B<$method>

The current method, for example "find" or "search".

=item B<@args>

The method arguments.

=back

=cut

sub _objects_cache_cache_key {
    my ( $self, @args ) = @_;
    if ( @args == 2 && !ref $args[1] ) {
        return join( ':', @args );
    }

    # JSON is much faster than Data::Dumper but throws
    # an exception for certain perl data structures
    # (non boolean scalar refs for example which can
    # be used in DBIx conditions)
    my $cache_key = eval { md5_hex( JSON->new->canonical(1)->encode( \@args ) ) };
    if ($cache_key) {
        return $cache_key;
    } else {
        local $Data::Dumper::Sortkeys = 1;
        return md5_hex( Dumper( \@args ) );
    }
}

=head3 _objects_cache_bucket_key

my $bucket_key = $self->_objects_cache_bucket_key($bucket);

Get the full cache bucket key of the short hand C<$bucket> name for this object type.

=over 8

=item B<$bucket>

The bucket name, "ids" for the bucket key where objects retrieved by ids are stored,
or "args" for the bucket key where objects retrieved by more complex conditions are
stored.

=back

=cut

sub _objects_cache_bucket_key {
    my ( $self, $bucket ) = @_;
    my %buckets = (
        'ids'  => 'ObjectsCachedIds',
        'args' => 'ObjectsCachedArgs'
    );
    unless ( exists $buckets{$bucket} ) {
        croak "Invalid cache bucket $bucket";
    }
    return $self->_type . $buckets{$bucket};

}

=head3 _objects_cache_bucket

my $cache = _objects_cache_bucket($bucket);

Get the memory cache of the short hand C<$bucket> name for this object type.

=over 8

=item B<$bucket>

The bucket name, "ids" for the bucket key where objects retrieved by ids are stored,
or "args" for the bucket key where objects retrieved by more complex conditions are
stored.

=back

=cut

sub _objects_cache_bucket {
    my ( $self, $bucket ) = @_;
    my $memory_cache = Koha::Cache::Memory::Lite->get_instance();
    my $bucket_key   = $self->_objects_cache_bucket_key($bucket);
    my $cache        = $memory_cache->get_from_cache($bucket_key);
    unless ($cache) {
        $cache = {};
        $memory_cache->set_in_cache( $bucket_key, $cache );
    }
    return $cache;
}

=head3 _objects_cache_get

my $objects = $self->_objects_cache_get($cache_key, $bucket);

Get the cached object or objects for the C<$cache_key> and C<$bucket>

=cut

sub _objects_cache_get {
    my ( $self, $cache_key, $bucket ) = @_;
    my $cache = $self->_objects_cache_bucket($bucket);
    return exists $cache->{$cache_key} ? $cache->{$cache_key} : undef;
}

=head3 _objects_cache_set

$self->_objects_cache_set($cache_key, $bucket, $object);

Set the cached object or objects for the C<$cache_key> and C<$bucket>

=cut

sub _objects_cache_set {
    my ( $self, $cache_key, $object, $bucket ) = @_;
    my $cache = $self->_objects_cache_bucket($bucket);
    $cache->{$cache_key} = $object;
}

=head3 _objects_cache_clear

$self->_objects_cache_clear($ids_cache_key);

Clear objects cache, if $ids_cache_key is provided only that
key will be purged from the 'ids' cache bucket.

=cut

sub _objects_cache_clear {
    my ( $self, $ids_cache_key ) = @_;
    my $memory_cache = Koha::Cache::Memory::Lite->get_instance();
    if ($ids_cache_key) {
        my $cache = $self->_objects_cache_bucket('ids');
        delete $cache->{$ids_cache_key};
    } else {
        $memory_cache->clear_from_cache( $self->_objects_cache_bucket_key('ids') );
    }
    $memory_cache->clear_from_cache( $self->_objects_cache_bucket_key('args') );
}

=head1 AUTHOR

David Gustafsson <david.gustafsson@ub.gu.se>

=cut

1;
