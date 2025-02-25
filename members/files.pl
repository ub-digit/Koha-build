#!/usr/bin/perl

# Copyright 2012 ByWater Solutions
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

use CGI qw ( -utf8 );

use C4::Auth qw( get_template_and_user );
use C4::Output qw( output_and_exit_if_error output_and_exit output_html_with_http_headers );
use C4::Members;

use Koha::Patrons;
use Koha::Patron::Files;
use Koha::Patron::Categories;

my $cgi = CGI->new;

my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {
        template_name   => "members/files.tt",
        query           => $cgi,
        type            => "intranet",
        flagsrequired   => { borrowers => 'edit_borrowers' },
    }
);
$template->param( 'borrower_files' => 1 );

my $borrowernumber = $cgi->param('borrowernumber');

my $logged_in_user = Koha::Patrons->find( $loggedinuser );
my $patron         = Koha::Patrons->find($borrowernumber);
output_and_exit_if_error( $cgi, $cookie, $template, { module => 'members', logged_in_user => $logged_in_user, current_patron => $patron } );

my $bf = Koha::Patron::Files->new( borrowernumber => $borrowernumber ); # FIXME Should be $patron->get_files. Koha::Patron::Files needs to be Koha::Objects based first

my $op = $cgi->param('op') || '';

if ( $op eq 'download' ) {
    my $file_id = $cgi->param('file_id');
    my $file = $bf->GetFile( id => $file_id );

    print $cgi->header(
        -type       => $file->{'file_type'},
        -charset    => 'utf-8',
        -attachment => $file->{'file_name'}
    );
    print $file->{'file_content'};
}
else {

    my $patron_category = $patron->category;
    $template->param( patron => $patron );

    my %errors;

    if ( $op eq 'cud-upload' ) {
        my $uploaded_file = $cgi->upload('uploadfile');

        if ($uploaded_file) {
            my $filename = $cgi->param('uploadfile');
            my $mimetype = $cgi->uploadInfo($filename)->{'Content-Type'};

            $errors{'empty_upload'} = 1 if ( -z $uploaded_file );

            if (%errors) {
                $template->param( errors => %errors );
            }
            else {
                my $file_content;
                while (<$uploaded_file>) {
                    $file_content .= $_;
                }

                my $rv = $bf->AddFile(
                    name    => $filename,
                    type    => $mimetype,
                    content => $file_content,
                    description => scalar $cgi->param('description'),
                );
                $errors{upload_failed} = 1 unless $rv;
            }
        }
        else {
            $errors{'no_file'} = 1;
        }
    } elsif ( $op eq 'cud-delete' ) {
        $bf->DelFile( id => scalar $cgi->param('file_id') );
    }

    $template->param(
        files => Koha::Patron::Files->new( borrowernumber => $borrowernumber )->GetFilesInfo(),
        errors => \%errors,
    );
    output_html_with_http_headers $cgi, $cookie, $template->output;
}

=head1 AUTHOR

Kyle M Hall <kyle@bywatersolutions.com>

=cut
