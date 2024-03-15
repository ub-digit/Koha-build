package Koha::Objects::Cached::Base;

use Modern::Perl;
use Digest::MD5 qw( md5_hex );
use Carp qw( croak );
use JSON;
use Data::Dumper;

use Koha::Cache::Memory::Lite;

=head1 NAME

Koha::Objects::Cached::Base

=head2 Internal methods

=head3 _objects_cache_cache_key

=cut

sub _objects_cache_cache_key {
    my ($self, @args) = @_;
    if (@args == 2 && !ref $args[1]) {
        return join(':', @args);
    }
    # JSON is much faster than Data::Dumper but throws
    # an exception for certain perl data strucures
    # (non boolean scalar refs for example which can
    # be used in DBIx conditions)
    my $cache_key = eval { md5_hex(JSON->new->canonical(1)->encode(\@args)) };
    if ($cache_key) {
        return $cache_key;
    } else {
        local $Data::Dumper::Sortkeys = 1;
        return md5_hex(Dumper(\@args));
    }
}

=head3 _objects_cache_bucket_key

=cut

sub _objects_cache_bucket_key {
    my ($self, $bucket) = @_;
    my %buckets = (
        'ids' => 'ObjectsCachedIds',
        'args' => 'ObjectsCachedArgs'
    );
    unless (exists $buckets{$bucket}) {
        croak "Invalid cache bucket $bucket";
    }
    return $self->_type . $buckets{$bucket};


}

=head3 _objects_cache_bucket

=cut

sub _objects_cache_bucket {
    my ($self, $bucket) = @_;
    my $memory_cache = Koha::Cache::Memory::Lite->get_instance();
    my $bucket_key = $self->_objects_cache_bucket_key($bucket);
    my $cache = $memory_cache->get_from_cache($bucket_key);
    unless ($cache) {
        $cache = {};
        $memory_cache->set_in_cache($bucket_key, $cache);
    }
    return $cache;
}

=head3 _objects_cache_get

=cut

sub _objects_cache_get {
    my ($self, $cache_key, $bucket) = @_;
    my $cache = $self->_objects_cache_bucket($bucket);
    return exists $cache->{$cache_key} ? $cache->{$cache_key} : undef;
}

=head3 _objects_cache_set

=cut

sub _objects_cache_set {
    my ($self, $cache_key, $object, $bucket) = @_;
    my $cache = $self->_objects_cache_bucket($bucket);
    $cache->{$cache_key} = $object;
}

=head3 _objects_cache_clear

=cut

sub _objects_cache_clear {
    my ($self, $ids_cache_key) = @_;
    my $memory_cache = Koha::Cache::Memory::Lite->get_instance();
    if ($ids_cache_key) {
        my $cache = $self->_objects_cache_bucket('ids');
        delete $cache->{$ids_cache_key};
    }
    else {
        $memory_cache->clear_from_cache(
            $self->_objects_cache_bucket_key('ids')
        );
    }
    $memory_cache->clear_from_cache(
        $self->_objects_cache_bucket_key('args')
    );
}

=head1 AUTHOR

David Gustafsson <david.gustafsson@ub.gu.se>

=cut

1;
