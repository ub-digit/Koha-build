use Modern::Perl;

return {
    bug_number => "27859",
    description => "Add system preferences",
    up => sub {
        my ($args) = @_;
        my ($dbh, $out) = @$args{qw(dbh out)};
        $dbh->do(q{ INSERT IGNORE INTO systempreferences (variable, value, options, explanation, type) VALUES ('EnableSearchResultMARCExport', 1, NULL, 'Enable search result MARC export', 'YesNo') });
        $dbh->do(q{ INSERT IGNORE INTO systempreferences (variable, value, options, explanation, type) VALUES ('SearchResultMARCExportLimit', NULL, NULL, 'Search result MARC export limit', 'integer') });
        $dbh->do(q{ INSERT IGNORE INTO systempreferences (variable, value, options, explanation, type) VALUES ('SearchResultMARCExportFromAddress', NULL, NULL, 'Search result MARC export email from-address', 'short') });
        $dbh->do(q{ UPDATE systempreferences SET options = 'base64ISO2709|ARRAY' WHERE variable = 'ElasticsearchMARCFormat' });
        $dbh->do(q{ UPDATE systempreferences SET value = 'base64ISO2709' WHERE variable = 'ElasticsearchMARCFormat' AND value = 'ISO2709' });
        say $out "System preferences added";
    },
}
