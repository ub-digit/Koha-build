package Koha::AuthorisedValues;

# Copyright ByWater Solutions 2014
#
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
# along with Koha; if not, see <https://www.gnu.org/licenses>.

use Modern::Perl;

use Koha::Database;

use Koha::AuthorisedValue;
use Koha::MarcSubfieldStructures;

use base qw(Koha::Objects::Cached Koha::Objects::Limit::Library);

=head1 NAME

Koha::AuthorisedValues - Koha Authorised value Object set class

=head1 API

=head2 Class Methods

=cut

=head2 search_by_marc_field

Missing POD for search_by_marc_field.

=cut

sub search_by_marc_field {
    my ( $self, $params ) = @_;
    my $frameworkcode = $params->{frameworkcode} || '';
    my $tagfield      = $params->{tagfield};
    my $tagsubfield   = $params->{tagsubfield};

    return unless $tagfield or $tagsubfield;

    return $self->SUPER::search(
        {
            'marc_subfield_structures.frameworkcode' => $frameworkcode,
            ( defined $tagfield    ? ( 'marc_subfield_structures.tagfield'    => $tagfield )    : () ),
            ( defined $tagsubfield ? ( 'marc_subfield_structures.tagsubfield' => $tagsubfield ) : () ),
        },
        {
            join     => { category => 'marc_subfield_structures' },
            order_by => [ 'category', 'lib', 'lib_opac' ],
        }
    );
}

=head2 search_by_koha_field

Missing POD for search_by_koha_field.

=cut

sub search_by_koha_field {
    my ( $self, $params ) = @_;
    my $frameworkcode = $params->{frameworkcode} || '';
    my $kohafield     = $params->{kohafield};
    my $category      = $params->{category};

    return unless $kohafield;

    return $self->SUPER::search(
        {
            'marc_subfield_structures.frameworkcode' => $frameworkcode,
            'marc_subfield_structures.kohafield'     => $kohafield,
            ( defined $category ? ( category_name => $category ) : () ),
        },
        {
            join     => { category => 'marc_subfield_structures' },
            distinct => 1,
            order_by => [ 'category', 'lib', 'lib_opac' ],
        }
    );
}

=head2 find_by_koha_field

Missing POD for find_by_koha_field.

=cut

sub find_by_koha_field {
    my ( $self, $params ) = @_;
    my $frameworkcode    = $params->{frameworkcode} || '';
    my $kohafield        = $params->{kohafield};
    my $authorised_value = $params->{authorised_value};

    my $av = $self->SUPER::search(
        {
            'marc_subfield_structures.frameworkcode' => $frameworkcode,
            'marc_subfield_structures.kohafield'     => $kohafield,
            'me.authorised_value'                    => $authorised_value,
        },
        {
            join     => { category => 'marc_subfield_structures' },
            distinct => 1,
        }
    );
    return $av->next;
}

=head2 get_description_by_koha_field

Missing POD for get_description_by_koha_field.

=cut

sub get_description_by_koha_field {
    my ( $self, $params ) = @_;
    $params->{frameworkcode} //= '';

    return {} unless defined $params->{authorised_value};

    my $av = $self->find_by_koha_field($params);
    return defined $av ? { lib => $av->lib, opac_description => $av->opac_description } : {};
}

=head2 get_descriptions_by_koha_field

Missing POD for get_descriptions_by_koha_field.

=cut

sub get_descriptions_by_koha_field {
    my ( $self, $params ) = @_;
    $params->{frameworkcode} //= '';

    my @avs          = $self->search_by_koha_field($params)->as_list;
    my $descriptions = [
        map {
            {
                authorised_value => $_->authorised_value,
                lib              => $_->lib,
                opac_description => $_->opac_description
            }
        } @avs
    ];
    return @{$descriptions};
}

sub get_description_by_category_and_authorised_value {
    my ( $self, $params ) = @_;
    return unless defined $params->{category} and defined $params->{authorised_value};

    my $av = $self->search(
        {
            category         => $params->{category},
            authorised_value => $params->{authorised_value},
        }
    )->next;

    return $av
        ? {
        lib              => $av->lib,
        opac_description => $av->opac_description
        }
        : {};
}

=head3 get_descriptions_by_marc_field

    Return cached descriptions when looking up by MARC field/subfield

=cut

sub get_descriptions_by_marc_field {
    my ( $self, $params ) = @_;
    $params->{frameworkcode} //= '';

    return {} unless defined $params->{tagfield};

    my $descriptions = {};
    my @avs          = $self->search_by_marc_field($params)->as_list;
    foreach my $av (@avs) {
        $descriptions->{ $av->authorised_value } = $av->lib;
    }
    return $descriptions;
}

=head2 categories

Missing POD for categories.

=cut

sub categories {
    my ($self) = @_;
    my $rs = $self->_resultset->search(
        undef,
        {
            select   => ['category'],
            distinct => 1,
            order_by => 'category',
        },
    );
    return map $_->get_column('category'), $rs->all;
}

=head3 type

=cut

sub _type {
    return 'AuthorisedValue';
}

=head2 object_class

Missing POD for object_class.

=cut

sub object_class {
    return 'Koha::AuthorisedValue';
}

=head1 AUTHOR

Kyle M Hall <kyle@bywatersolutions.com>

=cut

1;
