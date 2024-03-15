#!/usr/bin/perl

# Copyright 2015 Koha Development team
#
# This file is part of Koha
#
# Koha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Koha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Koha; if not, see <http://www.gnu.org/licenses>.

use Modern::Perl;

use Test::More tests => 14;

use C4::Biblio;
use C4::Context;
use C4::Items;

use Koha::Biblios;
use Koha::Item::Transfer::Limits;
use Koha::Items;
use Koha::Library;
use Koha::Libraries;
use Koha::Database;
use Koha::CirculationRules;
use Koha::Cache::Memory::Lite;

use t::lib::Mocks;
use t::lib::TestBuilder;

my $schema = Koha::Database->new->schema;
$schema->storage->txn_begin;

# Cleanup default_branch_item_rules
my $dbh     = C4::Context->dbh;
$dbh->do('DELETE FROM circulation_rules');

my $builder = t::lib::TestBuilder->new;
my $nb_of_libraries = Koha::Libraries->search->count;
my $new_library_1 = Koha::Library->new({
    branchcode => 'my_bc_1',
    branchname => 'my_branchname_1',
    branchnotes => 'my_branchnotes_1',
    marcorgcode => 'US-MyLib',
})->store;
my $new_library_2 = Koha::Library->new({
    branchcode => 'my_bc_2',
    branchname => 'my_branchname_2',
    branchnotes => 'my_branchnotes_2',
})->store;

is( Koha::Libraries->search->count,         $nb_of_libraries + 2,  'The 2 libraries should have been added' );

my $retrieved_library_1 = Koha::Libraries->find( $new_library_1->branchcode );
is( $retrieved_library_1->branchname, $new_library_1->branchname, 'Find a library by branchcode should return the correct library' );

$retrieved_library_1->delete;
is( Koha::Libraries->search->count, $nb_of_libraries + 1, 'Delete should have deleted the library' );

# Stockrotation relationship testing

my $new_library_sr = $builder->build({ source => 'Branch' });

$builder->build({
    source => 'Stockrotationstage',
    value  => { branchcode_id => $new_library_sr->{branchcode} },
});
$builder->build({
    source => 'Stockrotationstage',
    value  => { branchcode_id => $new_library_sr->{branchcode} },
});
$builder->build({
    source => 'Stockrotationstage',
    value  => { branchcode_id => $new_library_sr->{branchcode} },
});

my $srstages = Koha::Libraries->find($new_library_sr->{branchcode})
    ->stockrotationstages;
is( $srstages->count, 3, 'Correctly fetched stockrotationstages associated with this branch');

isa_ok( $srstages->next, 'Koha::StockRotationStage', "Relationship correctly creates Koha::Objects." );

$schema->storage->txn_rollback;

subtest '->get_effective_marcorgcode' => sub {

    plan tests => 4;

    $schema->storage->txn_begin;

    my $library_1 = $builder->build_object({ class => 'Koha::Libraries',
                                             value => { marcorgcode => 'US-MyLib' } });
    my $library_2 = $builder->build_object({ class => 'Koha::Libraries',
                                             value => { marcorgcode => undef } });

    t::lib::Mocks::mock_preference('MARCOrgCode', 'US-Default');

    is( $library_1->get_effective_marcorgcode, 'US-MyLib',
       'If defined, use library\'s own marc org code');
    is( $library_2->get_effective_marcorgcode, 'US-Default',
       'If not defined library\' marc org code, use the one from system preferences');

    t::lib::Mocks::mock_preference('MARCOrgCode', 'Blah');
    is( $library_2->get_effective_marcorgcode, 'Blah',
       'Fallback is always MARCOrgCode syspref');

    $library_2->marcorgcode('ThisIsACode')->store();
    is( $library_2->get_effective_marcorgcode, 'ThisIsACode',
       'Pick library_2 code');

    $schema->storage->txn_rollback;
};

subtest '->from_email_address' => sub {

    plan tests => 3;

    $schema->storage->txn_begin;

    my $library_1 = $builder->build_object(
        {
            class => 'Koha::Libraries',
            value => {
                branchemail   => 'from@mybranc.com',
            }
        }
    );

    t::lib::Mocks::mock_preference( 'KohaAdminEmailAddress', 'admin@mylibrary.com' );

    is( $library_1->from_email_address, $library_1->branchemail,
       'If defined, use branches branchemail address');

    $library_1->branchemail(undef)->store();
    is( $library_1->from_email_address, 'admin@mylibrary.com',
       'Fallback to KohaAdminEmailAddress email address when branchemail is undefined');

    t::lib::Mocks::mock_preference( 'KohaAdminEmailAddress', '' );
    is( $library_1->from_email_address, undef,
       'Return undef when branchemail and KohaAdminEmailAddress are both undefined');
    $schema->storage->txn_rollback;
};

subtest '->inbound_email_address' => sub {

    plan tests => 5;

    $schema->storage->txn_begin;

    my $library_1 = $builder->build_object(
        {
            class => 'Koha::Libraries',
            value => {
                branchemail   => 'from@mybranc.com',
                branchreplyto => 'reply@mybranch.com'
            }
        }
    );

    t::lib::Mocks::mock_preference( 'KohaAdminEmailAddress', 'admin@mylibrary.com' );
    t::lib::Mocks::mock_preference( 'ReplytoDefault', 'reply@mylibrary.com' );

    is( $library_1->inbound_email_address, $library_1->branchreplyto,
       'If defined, use branches replyto address');

    $library_1->branchreplyto(undef)->store();
    is( $library_1->inbound_email_address, $library_1->branchemail,
       'Fallback to branches email address when branchreplyto is undefined');

    $library_1->branchemail(undef)->store();
    is( $library_1->inbound_email_address, 'reply@mylibrary.com',
       'Fallback to ReplytoDefault email address when branchreplyto and branchemail are undefined');

    t::lib::Mocks::mock_preference( 'ReplytoDefault', '' );
    is( $library_1->inbound_email_address, 'admin@mylibrary.com',
       'Fallback to KohaAdminEmailAddress email address when branchreplyto, branchemail and ReplytoDefault are undefined');

    t::lib::Mocks::mock_preference( 'KohaAdminEmailAddress', '' );
    is( $library_1->inbound_email_address, undef,
       'Return undef when  email address when branchreplyto, branchemail, ReplytoDefault and KohaAdminEmailAddress are undefined');
    $schema->storage->txn_rollback;
};

subtest '->inbound_ill_address' => sub {

    plan tests => 7;

    $schema->storage->txn_begin;

    my $library_1 = $builder->build_object(
        {
            class => 'Koha::Libraries',
            value => {
                branchemail   => 'from@mylibrary.com',
                branchreplyto => 'reply@mylibrary.com',
                branchillemail => 'ill@mylibrary.com'
            }
        }
    );

    t::lib::Mocks::mock_preference( 'KohaAdminEmailAddress', 'admin@mylibrary.com' );
    t::lib::Mocks::mock_preference( 'ReplytoDefault', 'reply@mylibrary.com' );
    t::lib::Mocks::mock_preference( 'ILLDefaultStaffEmail', 'illdefault@mylibrary.com' );

    is( $library_1->inbound_ill_address, $library_1->branchillemail,
       'If defined, use library branchillemail address');

    $library_1->branchillemail(undef)->store();
    is( $library_1->inbound_ill_address, 'illdefault@mylibrary.com',
       'Fallback to ILLDefaultStaffEmail preference when branchillemail is undefined');

    t::lib::Mocks::mock_preference( 'ILLDefaultStaffEmail', undef );
    is( $library_1->inbound_ill_address, $library_1->branchreplyto,
       'Fallback to library replyto address when ILLDefaultStaffEmail is undefined');

    $library_1->branchreplyto(undef)->store();
    is( $library_1->inbound_ill_address, $library_1->branchemail,
       'Fallback to branches email address when branchreplyto is undefined');

    $library_1->branchemail(undef)->store();
    is( $library_1->inbound_ill_address, 'reply@mylibrary.com',
       'Fallback to ReplytoDefault email address when branchreplyto and branchemail are undefined');

    t::lib::Mocks::mock_preference( 'ReplytoDefault', '' );
    is( $library_1->inbound_ill_address, 'admin@mylibrary.com',
       'Fallback to KohaAdminEmailAddress email address when branchreplyto, branchemail and ReplytoDefault are undefined');

    t::lib::Mocks::mock_preference( 'KohaAdminEmailAddress', '' );
    is( $library_1->inbound_ill_address, undef,
       'Return undef when  email address when branchreplyto, branchemail, ReplytoDefault and KohaAdminEmailAddress are undefined');

    $schema->storage->txn_rollback;
};

subtest 'cash_registers' => sub {
    plan tests => 3;

    $schema->storage->txn_begin;

    my $library = $builder->build_object( { class => 'Koha::Libraries' } );
    my $register1 = $builder->build_object(
        {
            class => 'Koha::Cash::Registers',
            value  => { branch => $library->branchcode },
        }
    );
    my $register2 = $builder->build_object(
        {
            class => 'Koha::Cash::Registers',
            value  => { branch => $library->branchcode },
        }
    );

    my $registers = $library->cash_registers;
    is( ref($registers), 'Koha::Cash::Registers',
'Koha::Library->cash_registers should return a set of Koha::Cash::Registers'
    );
    is( $registers->count, 2,
        'Koha::Library->cash_registers should return the correct cash registers'
    );

    $register1->delete;
    is( $library->cash_registers->next->id, $register2->id,
        'Koha::Library->cash_registers should return the correct cash registers'
    );

    $schema->storage->txn_rollback;
};

subtest 'get_hold_libraries and validate_hold_sibling' => sub {

    plan tests => 12;

    $schema->storage->txn_begin;

    my $library1 = $builder->build_object( { class => 'Koha::Libraries' } );
    my $library2 = $builder->build_object( { class => 'Koha::Libraries' } );
    my $library3 = $builder->build_object( { class => 'Koha::Libraries' } );
    my $library4 = $builder->build_object( { class => 'Koha::Libraries' } );
    my $library5 = $builder->build_object( { class => 'Koha::Libraries' } );

    my $root1 = $builder->build_object( { class => 'Koha::Library::Groups', value => { ft_local_hold_group => 1 } } );
    my $root2 = $builder->build_object( { class => 'Koha::Library::Groups', value => { ft_local_hold_group => 1 } } );
    # G1
    $builder->build_object( { class => 'Koha::Library::Groups', value => { parent_id => $root1->id, branchcode => $library1->branchcode } } );
    $builder->build_object( { class => 'Koha::Library::Groups', value => { parent_id => $root1->id, branchcode => $library2->branchcode } } );
    # G2
    $builder->build_object( { class => 'Koha::Library::Groups', value => { parent_id => $root2->id, branchcode => $library3->branchcode } } );
    $builder->build_object( { class => 'Koha::Library::Groups', value => { parent_id => $root2->id, branchcode => $library4->branchcode } } );
    $builder->build_object( { class => 'Koha::Library::Groups', value => { parent_id => $root2->id, branchcode => $library5->branchcode } } );

    my @hold_libraries_1 = ($library1, $library2);
    my @hold_libraries_2 = ($library3, $library4, $library5);

    my @result = $library1->get_hold_libraries()->as_list;
    # library1 and library2 are siblings
    is(scalar(@result), 2, 'get_hold_libraries returns 2 libraries');

    my %map = map {$_->branchcode, 1} @result;

    foreach my $hold_library ( @hold_libraries_1 ) {
        ok(exists $map{$hold_library->branchcode}, 'library in hold group');
    }

    @result = $library3->get_hold_libraries()->as_list;
    # library3, library4 and library5 are siblings
    is(scalar(@result), 3, 'get_hold_libraries returns 3 libraries');

    %map = map {$_->branchcode, 1} @result;

    foreach my $hold_library ( @hold_libraries_2 ) {
        ok(exists $map{$hold_library->branchcode}, 'library in hold group');
    }

    ok($library1->validate_hold_sibling( { branchcode => $library2->branchcode } ), 'Library 2 is a valid hold sibling');
    ok(!$library1->validate_hold_sibling( { branchcode => $library3->branchcode } ), 'Library 3 is not a valid hold sibling');

    ok($library3->validate_hold_sibling( { branchcode => $library4->branchcode } ), 'Library 4 is a valid hold sibling');
    ok($library3->validate_hold_sibling( { branchcode => $library5->branchcode } ), 'Library 5 is a valid hold sibling');
    ok(!$library3->validate_hold_sibling( { branchcode => $library2->branchcode } ), 'Library 2 is not a valid hold sibling');

    $schema->storage->txn_rollback;

};

subtest 'get_float_libraries and validate_float_sibling' => sub {

    plan tests => 4;

    $schema->storage->txn_begin;

    my $library1 = $builder->build_object( { class => 'Koha::Libraries' } );
    my $library2 = $builder->build_object( { class => 'Koha::Libraries' } );
    my $library3 = $builder->build_object( { class => 'Koha::Libraries' } );
    my $library4 = $builder->build_object( { class => 'Koha::Libraries' } );

    my $root1 = $builder->build_object( { class => 'Koha::Library::Groups', value => { ft_local_float_group => 1 } } );
    my $root2 = $builder->build_object( { class => 'Koha::Library::Groups', value => { ft_local_float_group => 1 } } );

    # Float group 1
    $builder->build_object(
        { class => 'Koha::Library::Groups', value => { parent_id => $root1->id, branchcode => $library1->branchcode } }
    );
    $builder->build_object(
        { class => 'Koha::Library::Groups', value => { parent_id => $root1->id, branchcode => $library2->branchcode } }
    );

    # Float group 2
    $builder->build_object(
        { class => 'Koha::Library::Groups', value => { parent_id => $root2->id, branchcode => $library3->branchcode } }
    );
    $builder->build_object(
        { class => 'Koha::Library::Groups', value => { parent_id => $root2->id, branchcode => $library4->branchcode } }
    );

    my @libraries1 = $library1->get_float_libraries()->as_list;
    is( scalar @libraries1, '2', '1st float group contains 2 libraries' );

    my @libraries2 = $library3->get_float_libraries()->as_list;
    is( scalar @libraries2, '2', '2nd float group also contains 2 libraries' );

    ok(
        $library1->validate_float_sibling( { branchcode => $library2->branchcode } ),
        "Library1 and library2 belong in to the same float group."
    );
    ok(
        $library3->validate_float_sibling( { branchcode => $library4->branchcode } ),
        "Library3 and library5 belong in to the same float group."
    );

    $schema->storage->txn_rollback;
};

subtest 'outgoing_transfers' => sub {
    plan tests => 3;

    $schema->storage->txn_begin;

    my $library = $builder->build_object( { class => 'Koha::Libraries' } );
    my $transfer1 = $builder->build_object(
        {
            class => 'Koha::Item::Transfers',
            value  => { frombranch => $library->branchcode },
        }
    );
    my $transfer2 = $builder->build_object(
        {
            class => 'Koha::Item::Transfers',
            value  => { frombranch => $library->branchcode },
        }
    );

    my $outgoing_transfers = $library->outgoing_transfers;
    is( ref($outgoing_transfers), 'Koha::Item::Transfers',
'Koha::Library->outgoing_transfers should return a set of Koha::Item::Transfers'
    );
    is( $outgoing_transfers->count, 2,
        'Koha::Library->outgoing_transfers should return the correct number of transfers'
    );

    $transfer1->delete;
    is( $library->outgoing_transfers->next->id, $transfer2->id,
        'Koha::Library->outgoing_transfers should return the correct transfers'
    );

    $schema->storage->txn_rollback;
};

subtest 'cache tests' => sub {
    plan tests => 24;

    $schema->storage->txn_begin;

    my $library1 = $builder->build_object(
        {
            class => 'Koha::Libraries',
            value  => {
                branchname => 'My library'
            }
        }
    );
    my $library2 = $builder->build_object(
        {
            class => 'Koha::Libraries',
            value  => {
                branchname => 'My other library'
            }
        }
    );

    # Since build_object calls find internally
    # we first have to flush the cache since these
    # objects are now already cached
    Koha::Cache::Memory::Lite->get_instance()->flush();

    my $ids_bucket = Koha::Libraries->_objects_cache_bucket('ids');
    ok(!%{$ids_bucket}, 'Find cache has been cleared after flushing memory cache');

    my $cached_library = Koha::Libraries->find($library1->branchcode);
    Koha::Libraries->find($library2->branchcode);

    my $cached_library_ids_bucket = Koha::Libraries->_objects_cache_get(
        Koha::Libraries->_objects_cache_cache_key('find', $library1->branchcode),
        'ids'
    );
    is (ref($cached_library_ids_bucket), 'Koha::Library', 'Library should be cached after previously have been fetched');
    is ($cached_library_ids_bucket->branchcode, $library1->branchcode, 'The cashed library should be the expected library');

    # Set property of library by-passing the cache expiration logic
    # so we can veriy library is not only present in cache by also
    # properly retrieved in find
    $cached_library->_result->set_column('branchname', 'My library in cache');
    $cached_library = Koha::Libraries->find($library1->branchcode);
    is (
        $cached_library->branchname,
        'My library in cache',
        'The cashed library returned by find should be the cached library'
    );

    $library1->branchname('My expired library');
    $cached_library_ids_bucket = Koha::Libraries->_objects_cache_get(
        Koha::Libraries->_objects_cache_cache_key('find', $library1->branchcode),
        'ids'
    );
    is (
        $cached_library_ids_bucket,
        undef,
        'Cache has been expired after changing library property'
    );

    $cached_library = Koha::Libraries->_objects_cache_get(
        Koha::Libraries->_objects_cache_cache_key('find', $library2->branchcode),
        'ids'
    );
    is (
        ref($cached_library),
        'Koha::Library', 'Cache should still contain other cached libraries'
    );

    my $stored_library = Koha::Libraries->find($library1->branchcode);
    is (
        $stored_library->branchname,
        'My library',
        'Library is fetched from database after cache has been expired'
    );

    $cached_library = Koha::Libraries->_objects_cache_get(
        Koha::Libraries->_objects_cache_cache_key('find', $library1->branchcode),
        'ids'
    );
    is (
        ref($cached_library),
        'Koha::Library',
        'Library should be cached after previously have been fetched'
    );

    $library1->store();
    $cached_library = Koha::Libraries->_objects_cache_get(
        Koha::Libraries->_objects_cache_cache_key('find', $library1->branchcode),
        'ids'
    );
    is ($cached_library, undef, 'Cache has been expired after saving library to database');

    Koha::Libraries->find($library1->branchcode, { key => 'primary' });
    $cached_library = Koha::Libraries->_objects_cache_get(
        Koha::Libraries->_objects_cache_cache_key('find', $library1->branchcode, { key => 'primary' }),
        'args'
    );
    is (
        ref($cached_library),
        'Koha::Library',
        'The args cache bucket should be used if find is called with the attrs argument'
    );
    my $cached_value;

    for my $method ('find', 'search') {

        Koha::Libraries->$method({ branchcode => $library1->branchcode });
        Koha::Libraries->$method({ branchcode => $library2->branchcode });

        $cached_value = Koha::Libraries->_objects_cache_get(
            Koha::Libraries->_objects_cache_cache_key($method, { branchcode => $library1->branchcode }),
            'args'
        );
        $cached_library = $method eq 'search' ? $cached_value->next : $cached_value;
        is (
            ref($cached_library),
            'Koha::Library',
            'Library should be cached after previously have been fetched, and use the args cache bucket ' . ($method eq 'find' ? 'if find was called with column conditions' : 'if search was called')
        );

        $cached_library->_result->set_column('branchname', 'My library in cache');
        $cached_value = Koha::Libraries->$method({ branchcode => $library1->branchcode });
        $cached_library = $method eq 'search' ? $cached_value->next : $cached_value;
        is (
            $cached_library->branchname,
            'My library in cache',
            "The cashed library returned by $method should be the cached library, using the args cache bucket"
        );

        $cached_library->branchname('My expired library');
        $cached_value = Koha::Libraries->_objects_cache_get(
            Koha::Libraries->_objects_cache_cache_key($method, { branchcode => $library1->branchcode }),
            'args'
        );
        is (
            $cached_value,
            undef,
            'Cache has been expired after changing branchname, using the args cache bucket'
        );

        $cached_value = Koha::Libraries->_objects_cache_get(
            Koha::Libraries->_objects_cache_cache_key($method, { branchcode => $library2->branchcode }),
            'args'
        );
        is (
            $cached_value,
            undef,
            'The whole args cache bucket has been emptied after triggering cache expiration'
        );
    }

    Koha::Libraries->find($library2->branchcode);

    my $libraries = Koha::Libraries->search({ branchcode => $library1->branchcode });
    $libraries->next;
    is($libraries->next, undef, 'Cached libraries search result iterator has been exhausted');

    $libraries = Koha::Libraries->search({ branchcode => $library1->branchcode });
    is(ref($libraries->next), 'Koha::Library', 'Cached libraries search result iterator has been reset');


    my $cached_libraries = Koha::Libraries->_objects_cache_get(
        Koha::Libraries->_objects_cache_cache_key('search', { 'branchcode' => $library1->branchcode }),
        'args'
    );
    is (
        ref($cached_libraries),
        'Koha::Libraries',
        'Libraries should be cached after previously have been fetched'
    );

    $library1->delete();
    $cached_libraries = Koha::Libraries->_objects_cache_get(
        Koha::Libraries->_objects_cache_cache_key('search', { 'branchcode' => $library1->branchcode }),
        'args'
    );
    is ($cached_libraries, undef, 'Search cache has been expired after deleting library');

    $cached_library = Koha::Libraries->_objects_cache_get(
        Koha::Libraries->_objects_cache_cache_key('find', $library2->branchcode),
        'ids'
    );
    is (
        ref($cached_library),
        'Koha::Library',
        'Library should be cached after previously have been fetched'
    );
    $library2->delete();
    $cached_library = Koha::Libraries->_objects_cache_get(
        Koha::Libraries->_objects_cache_cache_key('find', $library2->branchcode),
        'ids'
    );
    is ($cached_library, undef, 'Find cache has been expired after deleting library');

    $schema->storage->txn_rollback;
}
