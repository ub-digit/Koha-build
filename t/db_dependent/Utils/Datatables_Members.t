#!/usr/bin/perl

# This file is part of Koha.
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

use Test::More tests => 53;

use C4::Context;
use C4::Members;

use Koha::Library;
use Koha::Patrons;
use Koha::Patron::Categories;

use t::lib::Mocks;
use t::lib::TestBuilder;

use Koha::Database;

use_ok( "C4::Utils::DataTables::Members" );

my $schema = Koha::Database->new->schema;
$schema->storage->txn_begin;

my $builder = t::lib::TestBuilder->new;

my $library = $builder->build({
    source => "Branch",
});

my $patron = $builder->build_object({ class => 'Koha::Patrons', value => { flags => 1 } });
t::lib::Mocks::mock_userenv({ patron => $patron });

my $branchcode=$library->{branchcode};

my $john_doe = $builder->build({
        source => "Borrower",
        value => {
            cardnumber   => '123456',
            firstname    => 'John',
            surname      => 'Doe',
            branchcode   => $branchcode,
            dateofbirth  => '1983-03-01',
            userid       => 'john.doe',
            initials     => 'pacman',
            flags        => 0,
        },
});

my $john_smith = $builder->build({
        source => "Borrower",
        value => {
            cardnumber   => '234567',
            firstname    => 'John',
            surname      => 'Smith',
            branchcode   => $branchcode,
            dateofbirth  => '1982-02-01',
            userid       => 'john.smith',
            flags        => 0,
        },
});

my $jane_doe = $builder->build({
        source => "Borrower",
        value => {
            cardnumber   => '345678',
            firstname    => 'Jane',
            surname      => 'Doe',
            branchcode   => $branchcode,
            dateofbirth  => '1983-03-01',
            userid       => 'jane.doe',
            flags        => 0,
        },
});
my $jeanpaul_dupont = $builder->build({
        source => "Borrower",
        value => {
            cardnumber   => '456789',
            firstname    => 'Jean Paul',
            surname      => 'Dupont',
            branchcode   => $branchcode,
            dateofbirth  => '1982-02-01',
            userid       => 'jeanpaul.dupont',
            flags        => 0,
        },
});
my $dupont_brown = $builder->build({
        source => "Borrower",
        value => {
            cardnumber   => '567890',
            firstname    => 'Dupont',
            surname      => 'Brown',
            branchcode   => $branchcode,
            dateofbirth  => '1979-01-01',
            userid       => 'dupont.brown',
            flags        => 0,
        },
});

# Set common datatables params
my %dt_params = (
    iDisplayLength   => 10,
    iDisplayStart    => 0
);

t::lib::Mocks::mock_preference('DefaultPatronSearchFields', '');

# Search "John Doe"
my $search_results = C4::Utils::DataTables::Members::search({
    searchmember     => "John Doe",
    searchfieldstype => 'standard',
    searchtype       => 'contain',
    branchcode       => $branchcode,
    dt_params        => \%dt_params
});

is( $search_results->{ iTotalDisplayRecords }, 1,
    "John Doe has only one match on $branchcode (Bug 12595)");

ok( $search_results->{ patrons }[0]->{ cardnumber } eq $john_doe->{ cardnumber }
    && ! $search_results->{ patrons }[1],
    "John Doe is the only match (Bug 12595)");

# Search "Jane Doe"
$search_results = C4::Utils::DataTables::Members::search({
    searchmember     => "Jane Doe",
    searchfieldstype => 'standard',
    searchtype       => 'contain',
    branchcode       => $branchcode,
    dt_params        => \%dt_params
});

is( $search_results->{ iTotalDisplayRecords }, 1,
    "Jane Doe has only one match on $branchcode (Bug 12595)");

is( $search_results->{ patrons }[0]->{ cardnumber },
    $jane_doe->{ cardnumber },
    "Jane Doe is the only match (Bug 12595)");

# Search "John"
$search_results = C4::Utils::DataTables::Members::search({
    searchmember     => "John",
    searchfieldstype => 'standard',
    searchtype       => 'contain',
    branchcode       => $branchcode,
    dt_params        => \%dt_params
});

is( $search_results->{ iTotalDisplayRecords }, 2,
    "There are two John at $branchcode");

is( $search_results->{ patrons }[0]->{ cardnumber },
    $john_doe->{ cardnumber },
    "John Doe is the first result");

is( $search_results->{ patrons }[1]->{ cardnumber },
    $john_smith->{ cardnumber },
    "John Smith is the second result");

# Search "Doe"
$search_results = C4::Utils::DataTables::Members::search({
    searchmember     => "Doe",
    searchfieldstype => 'standard',
    searchtype       => 'contain',
    branchcode       => $branchcode,
    dt_params        => \%dt_params
});

is( $search_results->{ iTotalDisplayRecords }, 2,
    "There are two Doe at $branchcode");

is( $search_results->{ patrons }[0]->{ cardnumber },
    $john_doe->{ cardnumber },
    "John Doe is the first result");

is( $search_results->{ patrons }[1]->{ cardnumber },
    $jane_doe->{ cardnumber },
    "Jane Doe is the second result");

# Search "Smith" as surname - there is only one occurrence of Smith
$search_results = C4::Utils::DataTables::Members::search({
    searchmember     => "Smith",
    searchfieldstype => 'surname',
    searchtype       => 'contain',
    branchcode       => $branchcode,
    dt_params        => \%dt_params
});

is( $search_results->{ iTotalDisplayRecords }, 1,
    "There is one Smith at $branchcode when searching for surname");

is( $search_results->{ patrons }[0]->{ cardnumber },
    $john_smith->{ cardnumber },
    "John Smith is the first result");

# Search "Dupont" as surname - Dupont is used both as firstname and surname, we
# Should only fin d the user with Dupont as surname
$search_results = C4::Utils::DataTables::Members::search({
    searchmember     => "Dupont",
    searchfieldstype => 'surname',
    searchtype       => 'contain',
    branchcode       => $branchcode,
    dt_params        => \%dt_params
});

is( $search_results->{ iTotalDisplayRecords }, 1,
    "There is one Dupont at $branchcode when searching for surname");

is( $search_results->{ patrons }[0]->{ cardnumber },
    $jeanpaul_dupont->{ cardnumber },
    "Jean Paul Dupont is the first result");

# Search "Doe" as surname - Doe is used twice as surname
$search_results = C4::Utils::DataTables::Members::search({
    searchmember     => "Doe",
    searchfieldstype => 'surname',
    searchtype       => 'contain',
    branchcode       => $branchcode,
    dt_params        => \%dt_params
});

is( $search_results->{ iTotalDisplayRecords }, 2,
    "There are two Doe at $branchcode when searching for surname");

is( $search_results->{ patrons }[0]->{ cardnumber },
    $john_doe->{ cardnumber },
    "John Doe is the first result");

is( $search_results->{ patrons }[1]->{ cardnumber },
    $jane_doe->{ cardnumber },
    "Jane Doe is the second result");

# Search by userid
$search_results = C4::Utils::DataTables::Members::search({
    searchmember     => "john.doe",
    searchfieldstype => 'standard',
    searchtype       => 'contain',
    branchcode       => $branchcode,
    dt_params        => \%dt_params
});

is( $search_results->{ iTotalDisplayRecords }, 1,
    "John Doe is found by userid, standard search (Bug 14782)");

$search_results = C4::Utils::DataTables::Members::search({
    searchmember     => "john.doe",
    searchfieldstype => 'userid',
    searchtype       => 'contain',
    branchcode       => $branchcode,
    dt_params        => \%dt_params
});

is( $search_results->{ iTotalDisplayRecords }, 1,
    "John Doe is found by userid, userid search (Bug 14782)");

$search_results = C4::Utils::DataTables::Members::search({
    searchmember     => "john.doe",
    searchfieldstype => 'surname',
    searchtype       => 'contain',
    branchcode       => $branchcode,
    dt_params        => \%dt_params
});

is( $search_results->{ iTotalDisplayRecords }, 0,
    "No members are found by userid, surname search");

my $attribute_type = Koha::Patron::Attribute::Type->new(
    {
        code             => 'ATM_1',
        description      => 'my attribute type',
        staff_searchable => 1
    }
)->store;

Koha::Patrons->find( $john_doe->{borrowernumber} )->extended_attributes(
    [
        {
            code      => $attribute_type->code,
            attribute => 'the default value for a common user'
        }
    ]
);
Koha::Patrons->find( $jane_doe->{borrowernumber} )->extended_attributes(
    [
        {
            code      => $attribute_type->code,
            attribute => 'the default value for another common user'
        }
    ]
);
Koha::Patrons->find( $john_smith->{borrowernumber} )->extended_attributes(
    [
        {
            code      => $attribute_type->code,
            attribute => 'Attribute which not appears even if contains "Dupont"'
        }
    ]
);

t::lib::Mocks::mock_preference('ExtendedPatronAttributes', 1);
$search_results = C4::Utils::DataTables::Members::search({
    searchmember     => "common user",
    searchfieldstype => 'standard',
    searchtype       => 'contain',
    branchcode       => $branchcode,
    dt_params        => \%dt_params
});

is( $search_results->{ iTotalDisplayRecords}, 2, "There are 2 common users" );

t::lib::Mocks::mock_preference('ExtendedPatronAttributes', 0);
$search_results = C4::Utils::DataTables::Members::search({
    searchmember     => "common user",
    searchfieldstype => 'standard',
    searchtype       => 'contain',
    branchcode       => $branchcode,
    dt_params        => \%dt_params
});
is( $search_results->{ iTotalDisplayRecords}, 0, "There are still 2 common users, but the patron attribute is not searchable " );

$search_results = C4::Utils::DataTables::Members::search({
    searchmember     => "Jean Paul",
    searchfieldstype => 'standard',
    searchtype       => 'start_with',
    branchcode       => $branchcode,
    dt_params        => \%dt_params
});

is( $search_results->{ iTotalDisplayRecords }, 1,
    "Jean Paul Dupont is found using start with and two terms search 'Jean Paul' (Bug 15252)");

$search_results = C4::Utils::DataTables::Members::search({
    searchmember     => "Jean Pau",
    searchfieldstype => 'standard',
    searchtype       => 'start_with',
    branchcode       => $branchcode,
    dt_params        => \%dt_params
});

is( $search_results->{ iTotalDisplayRecords }, 1,
    "Jean Paul Dupont is found using start with and two terms search 'Jean Pau' (Bug 15252)");

$search_results = C4::Utils::DataTables::Members::search({
    searchmember     => "Jea Pau",
    searchfieldstype => 'standard',
    searchtype       => 'start_with',
    branchcode       => $branchcode,
    dt_params        => \%dt_params
});

is( $search_results->{ iTotalDisplayRecords }, 0,
    "Jean Paul Dupont is not found using start with and two terms search 'Jea Pau' (Bug 15252)");

$search_results = C4::Utils::DataTables::Members::search({
    searchmember     => "Jea Pau",
    searchfieldstype => 'standard',
    searchtype       => 'contain',
    branchcode       => $branchcode,
    dt_params        => \%dt_params
});

is( $search_results->{ iTotalDisplayRecords }, 1,
    "Jean Paul Dupont is found using contains and two terms search 'Jea Pau' (Bug 15252)");

my @datetimeprefs = ("dmydot","iso","metric","us");
my %dates_in_pref = (
        dmydot  => ["01.02.1982","01.03.1983","01.01.1979","01.01.1988"],
        iso     => ["1982-02-01","1983-03-01","1979-01-01","1988-01-01"],
        metric  => ["01/02/1982","01/03/1983","01/01/1979","01/01/1988"],
        us      => ["02/01/1982","03/01/1983","01/01/1979","01/01/1988"],
        );
foreach my $dateformloo (@datetimeprefs){
    t::lib::Mocks::mock_preference('dateformat', $dateformloo);
    t::lib::Mocks::mock_preference('DefaultPatronSearchFields', 'surname,firstname,othernames,userid,dateofbirth');
    $search_results = C4::Utils::DataTables::Members::search({
        searchmember     => $dates_in_pref{$dateformloo}[0],
        searchfieldstype => 'standard',
        searchtype       => 'contain',
        branchcode       => $branchcode,
        dt_params        => \%dt_params
    });

    is( $search_results->{ iTotalDisplayRecords }, 2,
        "dateformat: $dateformloo Two borrowers have dob $dates_in_pref{$dateformloo}[0], standard search fields plus dob works");

    $search_results = C4::Utils::DataTables::Members::search({
        searchmember     => $dates_in_pref{$dateformloo}[2],
        searchfieldstype => 'standard',
        searchtype       => 'contain',
        branchcode       => $branchcode,
        dt_params        => \%dt_params
    });

    is( $search_results->{ iTotalDisplayRecords }, 1,
        "dateformat: $dateformloo One borrower has dob $dates_in_pref{$dateformloo}[2], standard search fields plus dob works");

    $search_results = C4::Utils::DataTables::Members::search({
        searchmember     => $dates_in_pref{$dateformloo}[1],
        searchfieldstype => 'dateofbirth',
        searchtype       => 'contain',
        branchcode       => $branchcode,
        dt_params        => \%dt_params
    });

    is( $search_results->{ iTotalDisplayRecords }, 2,
        "dateformat: $dateformloo Two borrowers have dob $dates_in_pref{$dateformloo}[1], dateofbirth search field works");

    $search_results = C4::Utils::DataTables::Members::search({
        searchmember     => $dates_in_pref{$dateformloo}[3],
        searchfieldstype => 'dateofbirth',
        searchtype       => 'contain',
        branchcode       => $branchcode,
        dt_params        => \%dt_params
    });

    is( $search_results->{ iTotalDisplayRecords }, 0,
        "dateformat: $dateformloo No borrowers have dob $dates_in_pref{$dateformloo}[3], dateofbirth search field works");

    $search_results = C4::Utils::DataTables::Members::search({
        searchmember     => $dates_in_pref{$dateformloo}[3],
        searchfieldstype => 'standard',
        searchtype       => 'contain',
        branchcode       => $branchcode,
        dt_params        => \%dt_params
    });

    is( $search_results->{ iTotalDisplayRecords }, 0,
        "dateformat: $dateformloo No borrowers have dob $dates_in_pref{$dateformloo}[3], standard search fields plus dob works");
}

# Date of birth formatting
t::lib::Mocks::mock_preference('dateformat', 'metric');
$search_results = C4::Utils::DataTables::Members::search({
    searchmember     => "01/02/1982",
    searchfieldstype => 'dateofbirth',
    dt_params        => \%dt_params
});
is( $search_results->{ iTotalDisplayRecords }, 2,
    "Sarching by date of birth should handle date formatted given the dateformat pref");
$search_results = C4::Utils::DataTables::Members::search({
    searchmember     => "1982-02-01",
    searchfieldstype => 'dateofbirth',
    dt_params        => \%dt_params
});
is( $search_results->{ iTotalDisplayRecords }, 2,
    "Sarching by date of birth should handle date formatted in iso");

subtest 'ExtendedPatronAttributes' => sub {
    plan tests => 2;
    t::lib::Mocks::mock_preference('ExtendedPatronAttributes', 1);
    $search_results = C4::Utils::DataTables::Members::search({
        searchmember     => "Dupont",
        searchfieldstype => 'standard',
        searchtype       => 'contain',
        branchcode       => $branchcode,
        dt_params        => \%dt_params
    });

    is( $search_results->{ iTotalDisplayRecords }, 3,
        "'Dupont' is contained in 2 surnames and a patron attribute. Patron attribute one should be displayed if searching in all fields (Bug 18094)");

    $search_results = C4::Utils::DataTables::Members::search({
        searchmember     => "Dupont",
        searchfieldstype => 'surname',
        searchtype       => 'contain',
        branchcode       => $branchcode,
        dt_params        => \%dt_params
    });

    is( $search_results->{ iTotalDisplayRecords }, 1,
        "'Dupont' is contained in 2 surnames and a patron attribute. Patron attribute one should not be displayed if searching in specific fields (Bug 18094)");
};

subtest 'Search by any borrowers field (bug 17374)' => sub {
    plan tests => 2;

    my $search_results = C4::Utils::DataTables::Members::search({
        searchmember     => "pacman",
        searchfieldstype => 'initials',
        searchtype       => 'contain',
        branchcode       => $branchcode,
        dt_params        => \%dt_params
    });
    is( $search_results->{ iTotalDisplayRecords }, 1, "We find only 1 patron when searching for initials 'pacman'" );

    is( $search_results->{ patrons }[0]->{ cardnumber }, $john_doe->{cardnumber}, "We find the correct patron when sesrching by initials" )
};

subtest 'Search with permissions' => sub {
    plan tests => 4;

    my $superlibrarian = $builder->build_object(
        {
            class => 'Koha::Patrons',
            value => { branchcode => $branchcode, flags => 1 }
        }
    );
    my $librarian_with_full_permission = $builder->build_object(
        {
            class => 'Koha::Patrons',
            value => { branchcode => $branchcode, flags => 4100 }
        }
    );    # 4100 = 4096 (2^12 suggestions) + 4 (2^2 catalogue)
    my $librarian_with_subpermission = $builder->build_object(
        { class => 'Koha::Patrons', value => { branchcode => $branchcode } } );
    C4::Context->dbh->do(
        q|INSERT INTO user_permissions(borrowernumber, module_bit, code) VALUES(?,?,?)|,
        undef,
        $librarian_with_subpermission->borrowernumber,
        12,
        'suggestions_manage'
    );

    my $search_results = C4::Utils::DataTables::Members::search(
        {
            searchmember     => "",
            searchfieldstype => 'standard',
            searchtype       => 'contain',
            branchcode       => $branchcode,
            has_permission   => {
                permission    => 'suggestions',
                subpermission => 'suggestions_manage'
            },
            dt_params => { iDisplayLength => 3, iDisplayStart => 0 },
        }
    );
    is( $search_results->{iTotalDisplayRecords},
        3, "We find 3 patrons with suggestions_manage permission" );
    is_deeply(
        [ sort map { $_->{borrowernumber} } @{ $search_results->{patrons} } ],
        [
            $superlibrarian->borrowernumber,
            $librarian_with_full_permission->borrowernumber,
            $librarian_with_subpermission->borrowernumber
        ],
        'We got the 3 patrons we expected'
    );

    C4::Context->dbh->do(
        q|INSERT INTO user_permissions(borrowernumber, module_bit, code) VALUES(?,?,?)|,
        undef,
        $librarian_with_subpermission->borrowernumber,
        13,
        'moderate_comments'
    );
    $search_results = C4::Utils::DataTables::Members::search(
        {
            searchmember     => "",
            searchfieldstype => 'standard',
            searchtype       => 'contain',
            branchcode       => $branchcode,
            has_permission   => {
                permission    => 'suggestions',
                subpermission => 'suggestions_manage'
            },
            dt_params => { iDisplayLength => 3, iDisplayStart => 0 },
        }
    );
    is( $search_results->{iTotalDisplayRecords},
        3, "We find 3 patrons with suggestions_manage permission" );
    is_deeply(
        [ sort map { $_->{borrowernumber} } @{ $search_results->{patrons} } ],
        [
            $superlibrarian->borrowernumber,
            $librarian_with_full_permission->borrowernumber,
            $librarian_with_subpermission->borrowernumber
        ],
        'We got the 3 patrons we expected'
    );

};

subtest 'return values' => sub {
    plan tests => 1;
    my $search_results = C4::Utils::DataTables::Members::search({
        searchmember     => "John Doe",
        searchfieldstype => 'standard',
        searchtype       => 'contain',
    });
    ok(exists $search_results->{patrons}->[0]->{othernames}, 'othernames should have been retrieved' );
};

# End
$schema->storage->txn_rollback;
