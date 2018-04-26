use Modern::Perl;

return {
    bug_number => "",
    description => "Add system preference",
    up => sub {
        my ($args) = @_;
        my ($dbh, $out) = @$args{qw(dbh out)};
        # Do you stuffs here
        $dbh->do(q{INSERT IGNORE INTO systempreferences ( `variable`, `value`, `options`, `explanation`, `type`) VALUES ('enableOpacCatalogBrowsing', '1', '', 'Toggle the search box visibility.', 'YesNo')});
        $dbh->do(q{INSERT IGNORE INTO systempreferences ( `variable`, `value`, `options`, `explanation`, `type`) VALUES ('linkToExternalSite', '0', '', 'Links to external site', 'YesNo')});
        $dbh->do(q{INSERT IGNORE INTO systempreferences ( `variable`, `value`, `options`, `explanation`, `type`) VALUES ('externalSiteURL', '', null, 'URL to external site', 'Free')});
        # Print useful stuff here
        say $out "System preference added";
    },
}
