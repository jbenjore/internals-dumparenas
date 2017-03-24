use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  'ABSTRACT' => 'Dump perl memory',
  'AUTHOR' => 'Josh Jore <jjore@cpan.org>',
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'LICENSE' => 'perl',
  'NAME' => 'Internals::DumpArenas',
  'VERSION_FROM' => 'lib/Internals/DumpArenas.pm',
  'SIGN' => 1,
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
