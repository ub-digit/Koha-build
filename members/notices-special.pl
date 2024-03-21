#!/usr/bin/perl

# Displays sent notices for a given borrower

# Copyright (c) 2009 BibLibre
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
use C4::Auth qw( get_template_and_user );
use C4::Output qw( output_and_exit_if_error output_and_exit output_html_with_http_headers );
use CGI qw ( -utf8 );
use C4::Members;
use C4::Letters qw( GetPreparedLetter EnqueueLetter );
use Koha::Patrons;
use Koha::Patron::Categories;
use Koha::Patron::Password::Recovery qw( SendPasswordRecoveryEmail ValidateBorrowernumber );
use Koha::DateUtils qw( dt_from_string );

my $input=CGI->new;


my $letter_code = $input->param('letter_code');

my ($template, $loggedinuser, $cookie)= get_template_and_user({template_name => "members/notices.tt",
				query => $input,
				type => "intranet",
                flagsrequired => {superlibrarian => 1},
				});

my $logged_in_user = Koha::Patrons->find( $loggedinuser );
output_and_exit_if_error( $input, $cookie, $template, { module => 'members', logged_in_user => $logged_in_user, current_patron => $logged_in_user } );

# Getting the messages
my $queued_messages = Koha::Notice::Messages->search({letter_code => $letter_code, time_queued => { '>' => dt_from_string()->subtract( months => 3 ) }});

$template->param(
    patron             => $logged_in_user,
    QUEUED_MESSAGES    => $queued_messages,
    borrowernumber     => undef,
    # sentnotices        => 1,
);
output_html_with_http_headers $input, $cookie, $template->output;

