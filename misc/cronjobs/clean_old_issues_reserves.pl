#!/usr/bin/perl

use strict;
use warnings;

use Koha::Script -cron;
use C4::Context;
use Koha::Patrons;
use Modern::Perl;

my $dbh = C4::Context->dbh();

my $sth = $dbh->prepare("DELETE FROM old_issues WHERE timestamp < DATE_SUB(NOW(), INTERVAL 3 YEAR);");
my $res = $sth->execute();
$sth = $dbh->prepare("DELETE FROM old_reserves WHERE timestamp < DATE_SUB(NOW(), INTERVAL 3 YEAR);");
$res = $sth->execute();
