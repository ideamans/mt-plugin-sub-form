package MT::SubForm::CMS::Schema;

use strict;
use warnings;
use MT::SubForm::Util;

sub edit {
    my ( $cb, $app, $id, $obj, $param ) = @_;
    return $app->permission_denied
        unless $app->permissions->can_do('edit_custom_fields');

    my $blog_id = $app->can('blog') && $app->blog ? $app->blog->id : 0;
    $param->{sub_form_preview_url} = $app->uri(
        mode => 'preview_sub_form',
        args => {
            blog_id => $blog_id,
        },
    );

    $app->setup_editor_param($param);

    $param->{schema_head} ||= plugin->translate('_default_options_head');
    $param->{schema_html} ||= plugin->translate('_default_options_html');
    $param->{template} = plugin->translate('_default_schema_template');

    $param->{output} = File::Spec->catfile( plugin->{full_path},
        'tmpl', 'cms', 'edit_sub_form_schema.tmpl' );
}

sub preview {
    my ( $app ) = @_;
    return $app->permission_denied
        unless $app->permissions->can_do('edit_custom_fields');

    my $schema = MT->model('sub_form_schema')->new;
    $schema->set_values({
        schema_head     => $app->param('schema_head'),
        schema_html     => $app->param('schema_html'),
    });

    if ( $schema->validate ) {
        $app->json_result({
            schema_head => $schema->schema_head,
            schema_html => $schema->schema_html,
        });
    } else {
        $app->json_error($schema->errstr);
    }
}

sub save_filter {
    my ( $cb, $app ) = @_;
    return $app->permission_denied
        unless $app->permissions->can_do('edit_custom_fields');

    my %values = $app->param_hash;

    my $name = $app->param('name');
    return $cb->error(plugin->translate('Name is required.'))
        if !defined $name || $name eq '';

    my $schema = MT->model('sub_form_schema')->new;
    $schema->set_values(\%values);
    return $cb->error($schema->errstr) unless $schema->validate;

    1;
}

sub pre_save {
    my ( $cb, $app, $obj ) = @_;
    return $app->permission_denied
        unless $app->permissions->can_do('edit_custom_fields');

    1;
}

1;