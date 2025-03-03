use Modern::Perl;
use Koha::Installer::Output qw(say_warning say_success say_info);

return {
    bug_number  => "39229",
    description => "Search unique extended attributes on patron quicksearch",
    up          => sub {
        my ($args) = @_;
        my ( $dbh, $out ) = @$args{qw(dbh out)};

        # Do you stuffs here
        $dbh->do(
            q{ INSERT IGNORE INTO `systempreferences`(`variable`, `value`, `options`, `explanation`, `type`) VALUES ('UniqueExtendedAttributesQuickSearch', '0', NULL, 'Enable first running a search against all unique attributes when using the patron search bar, if a patron is found redirect to that patron without performing a full search. This can significantly improve performance if unique attributes are commonly searached for and the number of patrons is sufficiently large.', 'YesNo') }
        );

        # sysprefs
        say $out "Added new system preference 'UniqueExtendedAttributesQuickSearch'";
    },
};
