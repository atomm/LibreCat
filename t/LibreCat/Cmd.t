use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Slurp;
use App::Cmd::Tester;
use LibreCat::CLI;
use Data::Dumper;

my $pkg;
my @cmd_pkg;

BEGIN {
    $pkg = 'LibreCat::Cmd';
    use_ok $pkg;
    @cmd_pkg = map {
        $_ =~ s/\.pm$//;
        'LibreCat::Cmd::' . $_;
    } read_dir('lib/LibreCat/Cmd/');

    use_ok $_ for @cmd_pkg;
}

require_ok $pkg;

require_ok $_ for @cmd_pkg;

foreach (@cmd_pkg) {
    $_ =~ s/LibreCat::Cmd:://;
    my $result = test_app(qq|LibreCat::CLI| => [$_, "--help"]);
    ok $result->stdout, "printed what we expected for $_";
    # note Dumper $result->error;
    # is $result->error, undef, "threw no exceptions for help for $_";
    # is $result->stderr, '', "nothing sent to stderr for $_";
}

my $result = test_app(qq|LibreCat::CLI| => [qw()]);

like $result->stdout, qr/help:/, 'printed what we expected';
is $result->error,    undef,     'threw no exceptions';
is $result->stderr,   '',        'nothing sent to sderr';

$result = test_app('LibreCat::CLI' => [qw(help)]);

like $result->stdout, qr/commands:/, 'printed what we expected';
is $result->error,    undef,         'threw no exceptions';
is $result->stderr,   '',            'nothing sent to sderr';

$result = test_app('LibreCat::CLI' => [qw(-h)]);

like $result->stdout, qr/commands:/, 'printed what we expected';
is $result->error,    undef,         'threw no exceptions';
is $result->stderr,   '',            'nothing sent to sderr';

$result = test_app('LibreCat::CLI' => [qw(--help)]);

like $result->stdout, qr/commands:/, 'printed what we expected';
is $result->error,    undef,         'threw no exceptions';
is $result->stderr,   '',            'nothing sent to sderr';

done_testing;
