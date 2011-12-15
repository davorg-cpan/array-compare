use Module::Build;
my $build = Module::Build->new(
	module_name => 'Array::Compare',
	license => 'perl',
	requires => {
		perl    => '5.6.0',
		Carp    => 0,
		Moose	=> 0,
	},
        build_requires => {
                Test::NoWarnings => 0,
        },
	build_recommends => {
		Test::Pod           => 0,
		Test::Pod::Coverage => 0,
	},
        create_makefile_pl => 'traditional',
);

$build->create_build_script;

