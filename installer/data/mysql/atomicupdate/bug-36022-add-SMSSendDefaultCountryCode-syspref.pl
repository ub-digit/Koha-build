use Modern::Perl;

return {
    bug_number  => "36022",
    description => "Add SMSSendDefaultCountryCode system preference",
    up          => sub {
        my ($args) = @_;
        my ( $dbh, $out ) = @$args{qw(dbh out)};

        $dbh->do(q{ INSERT IGNORE INTO systempreferences (variable, value, options, explanation, type) VALUES ('SMSSendDefaultCountryCode ', NULL, NULL, 'Default SMS::Send driver recipient phone number country code', 'Integer') });
        # sysprefs
        say $out "Added new system preference 'SMSSendDefaultCountryCode'";
    },
};
