use Modern::Perl;

return {
    bug_number => "",
    description => "Add system preferences for HiddenExtendedAttributes, NonEditableExtendedAttributes and SecretExtendedAttributes (Branch gub-dev-extended-attributes-visibility-properties)",
    up => sub {
        my ($args) = @_;
        my ($dbh, $out) = @$args{qw(dbh out)};
        # Do you stuffs here
        $dbh->do(q{INSERT IGNORE INTO systempreferences (`variable`, `value`, `options`, `explanation`, `type`) VALUES ('HiddenExtendedAttributes', '', null, 'Define hidden extended attributes', 'multiple')});
        $dbh->do(q{INSERT IGNORE INTO systempreferences (`variable`, `value`, `options`, `explanation`, `type`) VALUES ('NonEditableExtendedAttributes', '', null, 'Define non-editable extended attributes', 'multiple')});
        $dbh->do(q{INSERT IGNORE INTO systempreferences (`variable`, `value`, `options`, `explanation`, `type`) VALUES ('SecretExtendedAttributes', '', null, 'Define extended attributes with secret values', 'multiple')});
        # Print useful stuff here
        say $out "System preferences added";
    },
}
