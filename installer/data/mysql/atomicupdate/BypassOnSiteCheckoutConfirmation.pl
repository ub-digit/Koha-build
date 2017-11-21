use Modern::Perl;

return {
    bug_number => "",
    description => "Add system preference",
    up => sub {
        my ($args) = @_;
        my ($dbh, $out) = @$args{qw(dbh out)};
        # Do you stuffs here
        $dbh->do(q{INSERT IGNORE INTO systempreferences ( `variable`, `value`, `options`, `explanation`, `type`) VALUES ('BypassOnSiteCheckoutConfirmation', '', '', 'Bypass confirmation when On-site is ticked and item notforloan has any of the listed statuses. Example -3|-2|-1', 'free')});
        # Print useful stuff here
        say $out "System preference added";
    },
}
z