package Koha::CachedFind::Base;

use Modern::Perl;
use Data::Dumper;
use Digest::MD5 qw( md5_hex );

use Koha::Cache::Memory::Lite;

=head1 NAME

Koha::CachedFind::Base

=head1 API

=head2 Public methods

=head3 delete

=cut

sub _find_cache_cache_key {
    my ($self, @args) = @_;
    local $Data::Dumper::Sortkeys = 1;
    return md5_hex(Dumper(\@args));
}

sub _find_cache_ids_cache_bucket_key {
    my ($self) = @_;
    return $self->_type . 'CachedFindIds';

}

sub _find_cache_args_cache_bucket_key {
    my ($self) = @_;
    return $self->_type . 'CachedFindArgs';
}


sub _find_cache_ids_cache {
    my ($self) = @_;
    my $memory_cache = Koha::Cache::Memory::Lite->get_instance();
    my $bucket_key = $self->_find_cache_ids_cache_bucket_key();
    my $cache = $memory_cache->get_from_cache($bucket_key);
    unless ($cache) {
        $cache = {};
        $memory_cache->set_in_cache($bucket_key, $cache);
    }
    return $cache;
}

sub _find_cache_args_cache {
    my ($self) = @_;
    my $memory_cache = Koha::Cache::Memory::Lite->get_instance();
    my $bucket_key = $self->_find_cache_args_cache_bucket_key();
    my $cache = $memory_cache->get_from_cache($bucket_key);
    unless ($cache) {
        $cache = {};
        $memory_cache->set_in_cache($bucket_key, $cache);
    }
    return $cache;
}

sub _find_cache_ids_cache_get {
    my ($self, $cache_key) = @_;
    my $cache = $self->_find_cache_ids_cache();
    return exists $cache->{$cache_key} ? $cache->{$cache_key} : undef;
}

sub _find_cache_ids_cache_set {
    my ($self, $cache_key, $object) = @_;
    my $cache = $self->_find_cache_ids_cache();
    $cache->{$cache_key} = $object;
}

sub _find_cache_args_cache_get {
    my ($self, $cache_key) = @_;
    my $cache = $self->_find_cache_args_cache();
    return exists $cache->{$cache_key} ? $cache->{$cache_key} : undef;
}

sub _find_cache_args_cache_set {
    my ($self, $cache_key, $object) = @_;
    my $cache = $self->_find_cache_args_cache();
    $cache->{$cache_key} = $object;
}

sub _find_cache_ids_cache_clear {
    my ($self, $cache_key) = @_;
    if ($cache_key) {
        my $cache = $self->_find_cache_ids_cache();
        delete $cache->{$cache_key};
    }
    else {
        my $memory_cache = Koha::Cache::Memory::Lite->get_instance();
        $memory_cache->clear_from_cache(
            $self->_find_cache_ids_cache_bucket_key()
        );
    }
}

sub _find_cache_args_cache_clear {
    my ($self) = @_;
    my $memory_cache = Koha::Cache::Memory::Lite->get_instance();
    $memory_cache->clear_from_cache(
        $self->_find_cache_args_cache_bucket_key()
    );
}

1;
