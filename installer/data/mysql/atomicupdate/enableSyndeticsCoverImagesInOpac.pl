use Modern::Perl;

return {
    bug_number => "",
    description => "Add system preference",
    up => sub {
        my ($args) = @_;
        my ($dbh, $out) = @$args{qw(dbh out)};
        # Do you stuffs here
        $dbh->do(q{INSERT IGNORE INTO systempreferences ( `variable`, `value`, `options`, `explanation`, `type`) VALUES ('enableCoverImagesInOpacList', '1', '', 'Show cover images in opac list', 'YesNo')});
        # Print useful stuff here
        say $out "System preference added";
    },
}
