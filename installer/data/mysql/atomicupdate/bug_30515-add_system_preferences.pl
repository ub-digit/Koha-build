use Modern::Perl;

return {
    bug_number => "30515",
    description => "Add system preferences for patron specific overdue notice preferences",
    up => sub {
        my ($args) = @_;
        my ($dbh, $out) = @$args{qw(dbh out)};

        $dbh->do(q{INSERT IGNORE INTO systempreferences (`variable`, `value`, `options`, `explanation`, `type`) VALUES ('UsePatronPreferencesForOverdueNotices', '0', NULL, 'Use patron specific messaging preferences for overdue notices if available', 'YesNo')});
        say $out "UsePatronPreferencesForOverdueNotices system preference added";

        $dbh->do(q{INSERT IGNORE INTO systempreferences (`variable`, `value`, `options`, `explanation`, `type`) VALUES ('UsePatronPreferencesForOverdueNoticesPrint', 'always', 'always|fallback|never', 'When to send print notices when using patron specific messaging preferences for overdue notices', 'Choice')});
        say $out "UsePatronPreferencesForOverdueNoticesPrint system preference added";
    },
}
