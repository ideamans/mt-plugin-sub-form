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
    $ctx->stash('sub_form_schema', $args{schema}) if $args{schema};

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
<mt:SubForm>
    text: <mt:SubFormValue name="text">
    single: <mt:SubFormValue name="single" key="label">
    multiple: <mt:SubFormValue name="multiple" glue=",">
    multiple: <mt:SubFormValue name="multiple" key="label" glue=",">
    multiple: <mt:SubFormValues name="multiple">[<mt:SubFormValue />]</mt:SubFormValues>
    multiple: <mt:SubFormValues name="multiple">[<mt:SubFormValue key="label" />]</mt:SubFormValues>
    multiple: <mt:IfSubFormHas name="multiple" eq="1">has 1</mt:IfSubFormHas>
    multiple: <mt:IfSubFormHas name="multiple" key="label" eq="OPTION1">has OPTION1</mt:IfSubFormHas>
    multiple: <mt:IfSubFormHas name="multiple" eq="3">has 3</mt:IfSubFormHas>
    multiple: <mt:IfSubFormHas name="multiple" key="label" eq="OPTION3">has OPTION3</mt:IfSubFormHas>
    nothing: <mt:IfSubFormHas name="mothing">has nothing</mt:IfSubFormHas>
</mt:SubForm>
EOT

    $args{data} = {
        text => [ { value => 'TEXT1' } ],
        multiple => [ { value => '1', label => 'OPTION1' }, { value => '2', label => 'OPTION2' } ],
        single => [ { value => '3', label => 'OPTION3' } ],
    };

    $args{expect} = <<'EOH';
    text: TEXT1
    single: OPTION3
    multiple: 1,2
    multiple: OPTION1,OPTION2
    multiple: [1][2]
    multiple: [OPTION1][OPTION2]
    multiple: has 1
    multiple: has OPTION1
    multiple: 
    multiple: 
    nothing: 
EOH

    test_template(%args);
}

sub template_schema {
    my %args;

    $args{schema} = MT->model('sub_form_schema')->new;
    $args{schema}->template(<<'EOT');
<mt:SubForm>
    text: <mt:SubFormValue name="text">
    single: <mt:SubFormValue name="single" key="label">
    multiple: <mt:SubFormValue name="multiple" glue=",">
    multiple: <mt:SubFormValue name="multiple" key="label" glue=",">
    multiple: <mt:SubFormValues name="multiple">[<mt:SubFormValue />]</mt:SubFormValues>
    multiple: <mt:SubFormValues name="multiple">[<mt:SubFormValue key="label" />]</mt:SubFormValues>
    multiple: <mt:IfSubFormHas name="multiple" eq="1">has 1</mt:IfSubFormHas>
    multiple: <mt:IfSubFormHas name="multiple" key="label" eq="OPTION1">has OPTION1</mt:IfSubFormHas>
    multiple: <mt:IfSubFormHas name="multiple" eq="3">has 3</mt:IfSubFormHas>
    multiple: <mt:IfSubFormHas name="multiple" key="label" eq="OPTION3">has OPTION3</mt:IfSubFormHas>
    nothing: <mt:IfSubFormHas name="mothing">has nothing</mt:IfSubFormHas>
</mt:SubForm>
EOT

    $args{template} = <<'EOT';
<mt:SubFormBuild>
EOT

    $args{data} = {
        text => [ { value => 'TEXT1' } ],
        multiple => [ { value => '1', label => 'OPTION1' }, { value => '2', label => 'OPTION2' } ],
        single => [ { value => '3', label => 'OPTION3' } ],
    };

    $args{expect} = <<'EOH';
    text: TEXT1
    single: OPTION3
    multiple: 1,2
    multiple: OPTION1,OPTION2
    multiple: [1][2]
    multiple: [OPTION1][OPTION2]
    multiple: has 1
    multiple: has OPTION1
    multiple: 
    multiple: 
    nothing: 
EOH

    test_template(%args);
}

sub main {
    my $mt = MT->instance;
    my $class = shift;

    $verbose = $class->SUPER::main(@_);

    uses;
    template_basic;
    template_schema;
}

__PACKAGE__->main() unless caller;

done_testing();


