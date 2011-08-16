use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Sendmail::QidTrace',
    license             => 'perl',
    dist_author         => q{Jeff M},
    dist_version_from   => 'bin/qidtrace',
    build_requires => {
#         'Test::More' => 0,
    },
#    add_to_cleanup      => [ 'System-Command-*' ],
);

$builder->create_build_script();
