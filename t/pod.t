use File::Find;
my @pod;
BEGIN {
  find sub { push @pod, $File::Find::name if /\.pm$/ }, 'blib';
}

use Test::Pod tests => scalar @pod;

pod_file_ok($_) for @pod;
