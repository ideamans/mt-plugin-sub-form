package MT::SubForm::CustomFields;

use strict;
use warnings;
use MT::SubForm::Util;
use MT::Request;

sub _common_field_html_param {
    my ( $tmpl_param ) = @_;

    $tmpl_param->{plugin_version} = plugin->{version};
    $tmpl_param->{debug_mode} = $MT::DebugMode;
    $tmpl_param->{build_error} = undef;

    $tmpl_param->{sub_form_lang} = MT->current_language;
    $tmpl_param->{sub_form_lang} =~ s/_.+//;

    # Including css, js?
    my $cache = MT::Request->instance->cache('sub_form') || {};
    $tmpl_param->{sub_form_head} = $cache->{sub_form_head};
    $cache->{sub_form_head} = 1;

    MT::Request->instance->cache('sub_form', $cache);
}

sub sub_form_html_params {
    my ( $key, $tmpl_key, $tmpl_param ) = @_;
    my $app = MT->instance;

    if ( $tmpl_key eq 'field_html' ) {
        _common_field_html_param($tmpl_param);
        my $schema = MT->model('sub_form_schema')->new;
        $schema->schema_html($tmpl_param->{options});
        $tmpl_param->{built_schema_html} = $schema->build_schema_html;
    } elsif ( $tmpl_key eq 'options_field' ) {
        unless ( $tmpl_param->{id} ) {
            $tmpl_param->{options} = plugin->translate("_default_options_html");
        }

        my $blog_id = $app->can('blog') && $app->blog ? $app->blog->id : 0;
        $tmpl_param->{sub_form_preview_url} = $app->uri(
            mode => 'preview_sub_form',
            args => {
                blog_id => $blog_id,
            },
        );
    }

    1;
}

sub sub_form_schema_params {
    my ( $key, $tmpl_key, $tmpl_param ) = @_;

    if ( $tmpl_key eq 'field_html' ) {
        _common_field_html_param($tmpl_param);
        if ( my $schema = MT->model('sub_form_schema')->load($tmpl_param->{options} || 0) ) {
            my $id = $schema->id;

            my $cache = MT::Request->instance->cache('sub_form') || {};
            $tmpl_param->{schema_head_included} = $cache->{"schema_head_included_$id"};
            $cache->{"schema_head_included_$id"} = 1;

            $tmpl_param->{built_schema_head} = $schema->build_schema_head;
            $tmpl_param->{build_error} = $schema->errstr
                unless defined $tmpl_param->{built_schema_head};

            $tmpl_param->{built_schema_html} = $schema->build_schema_html;
            $tmpl_param->{build_error} = $schema->errstr
                unless defined $tmpl_param->{built_schema_html};
        }
    } elsif ( $tmpl_key eq 'options_field' ) {
        my $app = MT->instance;
        my @blog_ids = $app->can('blog') && $app->blog ? ( $app->blog->id ) : ();
        push @blog_ids, 0;

        my @sub_form_schemas = MT->model('sub_form_schema')->load({blog_id => \@blog_ids});

        my $options = $tmpl_param->{options} || '';
        $tmpl_param->{sub_form_schemas} = [ map {
            {
                label       => $_->name,
                value       => $_->id,
                selected    => $_->id eq $options ? 1 : 0,
            }
        } @sub_form_schemas ];
    }
}

sub sub_form_validate {
    my ( $value ) = @_;
    my $app = MT->instance;

    $value;
}

sub template_param_edit_field {
    my ( $cb, $app, $param, $tmpl ) = @_;

    my $header = $tmpl->getElementById('header_include');
    my $node = $tmpl->createElement('setvarblock', { name => 'html_head', append => 1 });
    $node->innerHTML(q{
        <mt:include name="cms/sub_form_html_head.tmpl" component="SubForm">
    });
    $tmpl->insertBefore($node, $header);

    1;
}

1;