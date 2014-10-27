package MT::SubForm::Util;

use strict;
use base qw(Exporter);
use Data::Dumper;
use MT::Util;
use MT::Util::YAML;

our @EXPORT = qw(plugin pp lookup_schema_by_field);

sub plugin {
    MT->component('SubForm');
}

sub pp { print STDERR Dumper(@_); }

sub lookup_schema_by_field {
    my ( $ctx, %args ) = @_;
    my $blog = $ctx->stash('blog');
    my @blog_ids = ( 0, $blog ? ($blog->id) : () );

    my $field;
    if ( $args{field} ) {
        $field = $args{field};
    } elsif ( my $basename = $args{basename} ) {
        $field = MT->model('field')->load({
            blog_id     => \@blog_ids,
            basename    => $basename,
        });
    } elsif ( my $tag = $args{tag} ) {
        $field = MT->model('field')->load({
            blog_id     => \@blog_ids,
            tag         => $tag,
        });
    }

    return unless $field;

    if ( $field->type eq 'sub_form_with_schema' ) {
        my $schema = MT->model('sub_form_schema')->load($field->options || 0)
            || return;

        my $hash = $schema->schema_hash;
        $hash->{mtTemplate} ||= $schema->template;
        return $hash;
    } elsif ( $field->type =~ /_yaml$/ ) {
        return yaml2hash($field->options);
    } elsif ( $field->type =~ /_json$/ ) {
        return json2hash($field->options);
    }
}

1;