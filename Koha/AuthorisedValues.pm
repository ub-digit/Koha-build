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
# along with Koha; if not, see <http://www.gnu.org/licenses>.

use Modern::Perl;


use Koha::Database;

use Koha::AuthorisedValue;
use Koha::MarcSubfieldStructures;
use Koha::Cache::Memory::Lite;

use base qw(Koha::Objects::Cached Koha::Objects::Limit::Library);

=head1 NAME

Koha::AuthorisedValues - Koha Authorised value Object set class

=head1 API

=head2 Class Methods

=cut

sub search_by_marc_field {
    my ( $self, $params ) = @_;
    my $frameworkcode = $params->{frameworkcode} || '';
    my $tagfield      = $params->{tagfield};
    my $tagsubfield   = $params->{tagsubfield};

    return unless $tagfield or $tagsubfield;

    return $self->SUPER::search(
        {   'marc_subfield_structures.frameworkcode' => $frameworkcode,
            ( defined $tagfield    ? ( 'marc_subfield_structures.tagfield'    => $tagfield )    : () ),
            ( defined $tagsubfield ? ( 'marc_subfield_structures.tagsubfield' => $tagsubfield ) : () ),
        },
        {
            join => { category => 'marc_subfield_structures' },
            order_by => [ 'category', 'lib', 'lib_opac' ],
        }
    );
}

sub search_by_koha_field {
    my ( $self, $params ) = @_;
    my $frameworkcode    = $params->{frameworkcode} || '';
    my $kohafield        = $params->{kohafield};
    my $category         = $params->{category};

    return unless $kohafield;

    return $self->SUPER::search(
        {   'marc_subfield_structures.frameworkcode' => $frameworkcode,
            'marc_subfield_structures.kohafield'     => $kohafield,
            ( defined $category ? ( category_name    => $category )         : () ),
        },
        {   join     => { category => 'marc_subfield_structures' },
            distinct => 1,
            order_by => [ 'category', 'lib', 'lib_opac' ],
        }
    );
}

sub find_by_koha_field {
    my ( $self, $params ) = @_;
    my $frameworkcode    = $params->{frameworkcode} || '';
    my $kohafield        = $params->{kohafield};
    my $authorised_value = $params->{authorised_value};

    my $av = $self->SUPER::search(
        {   'marc_subfield_structures.frameworkcode' => $frameworkcode,
            'marc_subfield_structures.kohafield'     => $kohafield,
            'me.authorised_value'                    => $authorised_value,
        },
        {   join     => { category => 'marc_subfield_structures' },
            distinct => 1,
        }
    );
    return $av->next;
}

sub get_description_by_koha_field {
    my ( $self, $params ) = @_;
    my $frameworkcode    = $params->{frameworkcode} || '';
    my $kohafield        = $params->{kohafield};
    my $authorised_value = $params->{authorised_value};

    return {} unless defined $authorised_value;

    my $av = $self->find_by_koha_field($params);
    return defined $av ? { lib => $av->lib, opac_description => $av->opac_description } : {};
}

sub get_descriptions_by_koha_field {
    my ( $self, $params ) = @_;
    my $frameworkcode = $params->{frameworkcode} || '';
    my $kohafield = $params->{kohafield};

    my @avs = $self->search_by_koha_field($params)->as_list;
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

    my $category = $params->{category};
    my $value = $params->{authorised_value};

    my $cache = Koha::Caches->get_instance();
    my $cache_key = "AV_descriptions:$category";
    my $descriptions = $cache->get_from_cache($cache_key, { unsafe => 1 });

    unless (defined $descriptions) {
        $descriptions = {
            map {
                $_->authorised_value => {
                    lib => $_->lib,
                    opac_description => $_->opac_description
                }
            } $self->search(
                {
                    category => $category
                }
            )->as_list
        };
        $cache->set_in_cache($cache_key, $descriptions);
    }
    return defined $descriptions->{$value} ? $descriptions->{$value} : {};
}

=head3 get_descriptions_by_marc_field

    Return cached descriptions when looking up by MARC field/subfield

=cut

sub get_descriptions_by_marc_field {
    my ( $self, $params ) = @_;
    my $frameworkcode = $params->{frameworkcode} || '';
    my $tagfield      = $params->{tagfield};
    my $tagsubfield   = $params->{tagsubfield};

    return {} unless defined $params->{tagfield};

    my $descriptions = {};
    my @avs          = $self->search_by_marc_field($params)->as_list;
    foreach my $av (@avs) {
        $descriptions->{ $av->authorised_value } = $av->lib;
    }
    return $descriptions;
}

sub categories {
    my ( $self ) = @_;
    my $rs = $self->_resultset->search(
        undef,
        {
            select => ['category'],
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

sub object_class {
    return 'Koha::AuthorisedValue';
}

=head1 AUTHOR

Kyle M Hall <kyle@bywatersolutions.com>

=cut

1;
