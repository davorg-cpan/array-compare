use warnings;
use strict;
use Test::More 'no_plan';
use Test::NoWarnings;

use Data::Dumper;

use_ok('Array::Compare');

my $comp = Array::Compare->new;

my @A = (qw/0 1 2 3 4 5 6 7 8/);
my @B = (qw/0 1 2 3 4 5 X 7 8/);
my @C = @A;

my %skip1 = (6 => 1);
my %skip2 = (5 => 1);
my %skip3 = (6 => 0);

ok(! $comp->compare(\@A, \@B), 'Compare two different arrays - should fail');

$comp->Skip(\%skip1);
ok($comp->compare(\@A, \@B),
   'Compare two different arrays but ignore differing column - should succeed');

$comp->NoSkip();
ok(! $comp->compare(\@A, \@B),
  'Compare two different arrays after reset Skip - should fail');

$comp->Skip(\%skip2);
ok(! $comp->compare(\@A, \@B),
   'compare two different arrays but ignore non-differing column - should fail');

$comp->Skip(\%skip3);
ok(! $comp->compare(\@A, \@B),
   'Compare two different arrays but ignore differing column (badly) - should fail as skip value is 0');

$comp->Sep('|');
ok($comp->compare(\@A, \@C),
   'Change separator and compare two identical arrays - should succeed');

# These tests should generate fatal errors - hence the evals

eval { print $comp->compare(1, \@A) };
ok($@, 'Compare a number with an array');

eval { print $comp->compare(\@A, 1) };
ok($@, 'Compare an array with a number');

eval { print $comp->compare(\@A) };
ok($@, 'Call compare with only one argument');

is($comp->full_compare([undef, 2, undef], [1, undef, undef]), 2,
   'Full compare');

# Switch to full comparison
diag $comp->DefFull;
$comp->DefFull(1);
diag $comp->DefFull;
ok($comp->DefFull, 'DefFull is now true');
$comp->Skip({});

# @A and @B differ in column 6
# Array context
my @diffs = $comp->compare(\@A, \@B);
is(@diffs, 1, 'Correct number of diffs');
is($diffs[0], 6, 'First diff is correct');

# Scalar context
my $diffs =  $comp->compare(\@A, \@B);
is($diffs, 1, 'Correct number of diffs (scalar context)');

# @A and @B differ in column 6 (which we ignore)
$comp->Skip(\%skip1);
# Array context
@diffs = $comp->compare(\@A, \@B);
is(@diffs, 0, 'Correct number of diffs using skip');

# Scalar context
$diffs = $comp->compare(\@A, \@B);
is($diffs, 0, 'Correct number of diffs using skip (scalar context)');

# @A and @C are the same
# Array context
@diffs = $comp->compare(\@A, \@C);
is(@diffs, 0, 'No diffs');

# Scalar context
$diffs = $comp->compare(\@A, \@C);
is($diffs, 0, 'No diffs (scalar context)');

# Test arrays of differing length
my @D = (0 .. 5);
my @E = (0 .. 10);

$comp->DefFull(0);
ok( ! $comp->compare(\@D, \@E), 'Arrays of different lengths are different');

$comp->DefFull(1);
@diffs = $comp->compare(\@D, \@E);
is(@diffs, 5, 'Correct number of diffs');

@diffs = $comp->compare(\@E, \@D);
is(@diffs, 5, 'Correct number of diffs (reversed args)');

$diffs = $comp->compare(\@D, \@E);
is($diffs, 5, 'Correct number of diffs (scalar context)');

# Test Perms
my @F = (1 .. 5);
my @G = qw(5 4 3 2 1);
my @H = qw(3 4 1 2 5);
my @I = qw(4 3 6 5 2);

ok($comp->perm(\@F, \@G), 'Correct perm');
ok($comp->perm(\@F, \@H), 'Correct perm again');
ok(! $comp->perm(\@F, \@I), 'Correctly incorrect perm');

my @J = ('array with', 'white space');
my @K = ('array  with', "white\tspace");
ok($comp->compare(\@J, \@K), 'Correct whitespace check');

# Turn off whitespace
$comp->WhiteSpace(0);
ok(! $comp->compare(\@J, \@K), 'Correct while ignoring whitepace');

$comp->DefFull(0);
ok($comp->compare(\@J, \@K), 'Correct simple check ignoring whitespace');

# Turn on whitespace
$comp->WhiteSpace(1);
ok(! $comp->compare(\@J, \@K), 'Correct simple check with whitespace') or do {
  diag Dumper \@J;
  diag Dumper \@K;
  diag "WhiteSpace = ", $comp->WhiteSpace;
};

my @L = qw(ArRay WiTh DiFfErEnT cAsEs);
my @M = qw(aRrAY wItH dIfFeReNt CaSeS);
ok(! $comp->compare(\@L, \@M), 'Correct case sensitive check');

# Turn of case sensitivity
$comp->Case(0);
ok($comp->compare(\@L, \@M), 'Correct check ignoring case');

$comp->DefFull(1);
ok(! $comp->compare(\@L, \@M), 'Correct full check ignoring case');

my @N = (undef, 1 .. 3);
my @O = (undef, 1 .. 3);

$comp->DefFull(0);
ok($comp->compare(\@N, \@O), 'Correct check including undef');

$comp->DefFull(1);
ok(! $comp->compare(\@N, \@O), 'Correct full check including undef');
