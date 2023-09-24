use Module::Build;
my $build = Module::Build->new(
    module_name => 'Array::Compare',
    dist_version => '4.0.0',
    license => 'perl',
    requires => {
        perl            => '5.10.0',
        Carp            => 0,
        Feature::Compat::Class => 0,
        ($] < 5.038 ? (Object::Pad => 0) : ()),
    },
    build_requires => {
        Test::NoWarnings => 0,
    },
    build_recommends => {
        Test::Pod           => 0,
        Test::Pod::Coverage => 0,
    },
    meta_merge => {
        'meta-spec' => { version => 2 },
        resources  => {
            repository => {
                type => 'git',
                url  => 'https://github.com/davorg/array-compare.git',
                web  => 'https://github.com/davorg/array-compare',
            },
            bugtracker => {
                web  => 'https://github.com/davorg/array-compare/issues',
            },
        },
    },
    create_makefile_pl => 'traditional',
);

$build->create_build_script;
