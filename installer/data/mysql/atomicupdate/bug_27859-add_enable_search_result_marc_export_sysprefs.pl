use Modern::Perl;

return {
    bug_number => "27859",
    description => "Add system preferences",
    up => sub {
        my ($args) = @_;
        my ($dbh, $out) = @$args{qw(dbh out)};

        $dbh->do(q{ INSERT IGNORE INTO systempreferences (variable, value, options, explanation, type) VALUES ('EnableElasticsearchSearchResultExport', 1, NULL, 'Enable search result export', 'YesNo') });
        say $out "Added new system preference 'EnableElasticsearchSearchResultExport'";

        $dbh->do(q{ INSERT IGNORE INTO systempreferences (variable, value, options, explanation, type) VALUES ('ElasticsearchSearchResultExportCustomFormats', '', NULL, 'Search result export custom formats', 'textarea') });
        say $out "Added new system preference 'ElasticsearchSearchResultExportCustomFormats'";

        $dbh->do(q{ INSERT IGNORE INTO systempreferences (variable, value, options, explanation, type) VALUES ('ElasticsearchSearchResultExportLimit', NULL, NULL, 'Search result export limit', 'integer') });
        say $out "Added new system preference 'ElasticsearchSearchResultExportLimit'";

        $dbh->do(q{ UPDATE systempreferences SET options = 'base64ISO2709|ARRAY' WHERE variable = 'ElasticsearchMARCFormat' });
        $dbh->do(q{ UPDATE systempreferences SET value = 'base64ISO2709' WHERE variable = 'ElasticsearchMARCFormat' AND value = 'ISO2709' });
        say $out "Rename preference value in 'ElasticsearchMARCFormat' system preference";
    },
}
