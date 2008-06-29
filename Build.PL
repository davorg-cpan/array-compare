use Module::Build;
my $build = Module::Build->new(
        dist_version => '1.16',
	module_name => 'Array::Compare',
	license => 'perl',
	requires => {
		perl                => '5.6.0',
		Carp                => 0,
	},
	build_recommends => {
		Test::Pod           => 0,
		Test::Pod::Coverage => 0,
	},
        create_makefile_pl => 'traditional',
);

$build->create_build_script;

