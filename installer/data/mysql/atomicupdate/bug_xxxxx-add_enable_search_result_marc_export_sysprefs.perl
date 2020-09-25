$DBversion = 'XXX';  # will be replaced by the RM
if( CheckVersion( $DBversion ) ) {
  $dbh->do(q{INSERT IGNORE INTO systempreferences (variable, value, options, explanation, type) VALUES ('EnableSearchResultMARCExport', 1, NULL, 'Enable search result MARC export', 'YesNo') });
  $dbh->do(q{INSERT IGNORE INTO systempreferences (variable, value, options, explanation, type) VALUES ('SearchResultMARCExportLimit', NULL, NULL, 'Search result MARC export limit', 'integer') });

  #NewVersion( $DBversion, XXXXX, "Add EnableSearchResultMARCExport system prefernce");
}
