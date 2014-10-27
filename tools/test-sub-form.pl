#!/usr/bin/perl
package MT::SubForm::Test;
use strict;
use warnings;
use FindBin;
use lib ("$FindBin::Bin/../lib", "$FindBin::Bin/../extlib");
use Test::More;

use MT;
use base qw( MT::Tool );
use Data::Dumper;

sub pp { print STDERR Dumper($_) foreach @_ }

my $VERSION = 0.1;
sub version { $VERSION }

sub help {
    return <<'HELP';
OPTIONS:
    -h, --help             shows this help.
HELP
}

sub usage {
    return '[--help]';
}


## options
my ( $blog_id, $user_id, $verbose );

sub options {
    return (
    )
}

sub uses {
    use_ok('MT::SubForm::Schema');
    use_ok('MT::SubForm::CMS::Asset');
    use_ok('MT::SubForm::CustomFields');
    use_ok('MT::SubForm::L10N::en_us');
    use_ok('MT::SubForm::L10N::ja');
    use_ok('MT::SubForm::L10N');
    use_ok('MT::SubForm::Util');
}

sub test_template {
    my %args = @_;

    require MT::Builder;
    require MT::Template::Context;
    my $ctx = MT::Template::Context->new;
    my $builder = MT::Builder->new;

    $ctx->stash('sub_form_data', $args{data}) if $args{data};

    my $tokens = $builder->compile($ctx, $args{template}) or die $ctx->errstr || 'Feild to compile.';
    defined ( my $result = $builder->build($ctx, $tokens) )
        or die $ctx->errstr || 'Failed to build.';

    $result =~ s/^\n+//gm;
    $result =~ s/\n\s*\n/\n/gm;
    my @nodes = split( /::/, (caller(1))[3] );
    is($result, $args{expect}, pop @nodes);
}

sub template_basic {
    my %args;
    $args{template} = <<'EOT';
EOT

    $args{data} = [
        { column1 => 'VALUE1-1', column2 => 'VALUE1-2', column3 => 'VALUE1-3' },
        { column1 => 'VALUE2-1', column2 => 'VALUE2-2', column3 => 'VALUE2-3' },
    ];

    $args{expect} = <<'EOH';
EOH

    test_template(%args);
}

sub main {
    my $mt = MT->instance;
    my $class = shift;

    $verbose = $class->SUPER::main(@_);

    uses;
    template_basic;
}

__PACKAGE__->main() unless caller;

done_testing();


