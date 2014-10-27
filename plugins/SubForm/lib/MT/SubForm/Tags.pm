package MT::SubForm::Tags;

use strict;
use warnings;
use utf8;

use Data::Dumper;
use MT::Util;
use MT::SubForm::Util;

sub _context_schema {
    my ( $ctx, $args, $cond ) = @_;
    my $blog = $ctx->stash('blog');
    my $schema;

    if ( $args->{schema} ) {
        $schema = $args->{schema};
    } elsif ( my $basename = $args->{basename} ) {
        defined( $schema = lookup_schema_by_field($ctx, basename => $basename ) )
            || return $ctx->error(plugin->translate('SubForm Customfield which basename is "[_1]" is not found.', $basename));
    } elsif ( my $tag = $args->{tag} ) {
        defined( $schema = lookup_schema_by_field($ctx, tag => $tag ) )
            || return $ctx->error(plugin->translate('SubForm Customfield which tag is "[_1]" is not found.', $tag));
    } elsif ( my $field = $ctx->stash('field') ) {
        defined( $schema = lookup_schema_by_field($ctx, field => $field ) )
            || return $ctx->error(plugin->translate('SubForm Customfield which basename is "[_1]" is not found.', $field->basename));
    } elsif ( $ctx->stash('sub_form_schema') ) {
        $schema = $ctx->stash('sub_form_schema');
    } else {
        return '';
    }

    if ( ref $schema eq '' ) {
        # Parse as JSON
        $schema = eval { MT::Util::from_json($schema) }
            || return $ctx->error(plugin->translate('SubForm Customfield has no JSON hash schema.'));
    }

    return $ctx->error(plugin->translate('SubForm Customfield has no JSON hash schema.'))
        if ref $schema ne 'HASH';

    return $ctx->error(plugin->translate('SubForm Customfield has no columns array in schema.'))
        if ref $schema->{columns} ne 'ARRAY';

    foreach my $col ( @{$schema->{columns}} ) {
        return $ctx->error(plugin->translate('SubForm has invalid column definision in columns.'))
            if ref $col ne 'HASH';
        return $ctx->error(plugin->translate('SubForm has column without name in column definition.'))
            unless $col->{name};
    }

    $schema;
}

sub _context_data {
    my ( $ctx, $args, $cond ) = @_;
    my $data;

    if ( my $field = $ctx->stash('field') ) {
        $args->{tag} ||= $field->tag;
    }

    if ( $args->{data} ) {
        $data = $args->{data};
    } elsif ( my $tag = $args->{tag} ) {
        $tag =~ s/^MT:?//i;
        my %tag_args = map { delete $args->{$_} }
            map { s/^tag://; $_ }
            grep { /^tag:/ }
            keys %$args;

        $data = $ctx->tag( $tag, \%tag_args, $cond );
    } elsif ( $ctx->stash('sub_form_data') ) {
        $data = $ctx->stash('sub_form_data');
    } elsif ( my $schema = $ctx->stash('sub_form_schema') ) {
        $data = $schema->{initData};
    } else {
        return '';
    }

    if ( ref $data eq '' ) {
        # Parse ad JSON
        return '' if $data eq '';
        $data = eval { MT::Util::from_json($data) }
            || return $ctx->error(plugin->translate('SubForm data is not JSON format.'));
    }

    return $ctx->error(plugin->translate('SubForm data is not an array of hash.'))
        if ref $data ne 'ARRAY';

    foreach my $hash ( @$data ) {
        return $ctx->error(plugin->translate('SubForm data is not an array of hash.'))
             if ref $hash ne 'HASH';
    }

    $data;
}

sub _require_context_schema {
    my ( $ctx, $args, $cond ) = @_;
    defined( my $schema = _context_schema(@_) ) || return;
    return $ctx->error(plugin->translate('No SubForm schema context. Set SubForm customfield basename as basename attribute of SubFormColumns or SubForm template tag.'))
        unless $schema;

    $schema;
}

sub _require_context_data {
    my ( $ctx, $args, $cond ) = @_;
    defined( my $data = _context_data(@_) ) || return;
    return $ctx->error(plugin->translate('No SubForm data context. Set SubForm tag as tag attribute or set JSON data as data attribute of SubFormRows, SubForm template tag.'))
        unless $data;

    $data;
}

sub _require_context_column {
    my ( $ctx, $args, $cond ) = @_;
    defined( my $schema = _require_context_schema(@_) ) || return;

    my $col;
    if ( $ctx->stash('sub_form_column') ) {
        $col = $ctx->stash('sub_form_column');
    } elsif ( my $name = ( $args->{col} || $args->{column} ) ) {
        $col = ( grep { $_->{name} eq $name } @{$schema->{columns}} )[0]
            || return $ctx->error(plugin->translate('No column definition named "[_1]".', $name));
    } elsif ( defined ( my $index = $args->{index} ) ) {
        $col = $schema->{columns}->[$index]
            || return $ctx->error(plugin->translate('No column indexed [_1].', $name));
    }

    $col || return $ctx->error(plugin->translate('No SubForm column context. Set column, col or index attribute in [_1] or use [_1] tag inside mt:SubFormColumns.'), $ctx->stash('tag'));
}

sub _require_context_row {
    my ( $ctx, $args, $cond ) = @_;
    defined( my $data = _require_context_data(@_) ) || return;
    return '' if ref $data ne 'ARRAY';

    my $row;
    if ( defined $args->{row} ) {
        $row = $data->[int($args->{row})] || return '';
    } elsif ( $ctx->stash('sub_form_row') ) {
        $row = $ctx->stash('sub_form_row');
    } else {
        return $ctx->error(plugin->translate('No SubForm row context. Set index as row attribute of SubFormRow template tag or use in SubFormRows template tag.'));
    }

    return $ctx->error(plugin->translate('SubForm row is not a hash: [_1]', Dumper($row)))
        unless ref $row eq 'HASH';

    $row;
}

sub _require_context_cell {
    my ( $ctx, $args ) = @_;
    defined( my $row = _require_context_row(@_) ) || return;
    return '' if ref $row ne 'HASH';

    my $cell;
    my $col;
    if ( defined( $col = ( $args->{col} || $args->{column} ) ) ) {
        $cell = $row->{$col};
    } elsif ( $col = $ctx->stash('sub_form_column') ) {
        $cell = $row->{$col->{name}};
    } else {
        return $ctx->error(plugin->translate('Use mt:[_1] tag with col attribute or inside mt:SubFormColumns.', $ctx->stash('tag')));
    }

    defined( $cell ) ? $cell : '';
}

sub _basic_loop {
    my ( $array, $stash, $ctx, $args, $cond ) = @_;

    my $builder = $ctx->stash('builder');
    my $tokens = $ctx->stash('tokens');
    my $result = '';
    my $vars = $ctx->{__stash}{vars} ||= {};
    my $size = scalar @$array;
    for( my $i = 0; $i < $size; $i++ ) {
        local $ctx->{__stash}->{$stash} = $array->[$i];
        local $vars->{__first__} = ( $i == 0 )? 1: 0;
        local $vars->{__last__} = ( $i == $size-1 )? 1: 0;
        local $vars->{__odd__} = ( $i % 2 ) == 1;
        local $vars->{__even__} = ( $i % 2 ) == 0;
        local $vars->{__counter__} = $i;

        defined( my $partial = $builder->build($ctx, $tokens, $cond) ) || return;
        $result .= $partial;
    }

    $result;
}

sub hdlr_SubForm {
    my ( $ctx, $args, $cond ) = @_;

    my ( $schema, $data );
    defined( $schema = _context_schema(@_) ) || return;
    defined( $data = _context_data(@_) ) || return;

    local $ctx->{__stash}->{sub_form_schema} = $schema;
    local $ctx->{__stash}->{sub_form_data} = $data;

    my $builder = $ctx->stash('builder');
    my $tokens = $ctx->stash('tokens');
    defined( my $partial = $builder->build($ctx, $tokens, $cond) ) || return;

    $partial;
}

sub hdlr_SubFormColumns {
    my ( $ctx, $args, $cond ) = @_;

    defined( my $schema = _require_context_schema(@_) ) || return;

    local $ctx->{__stash}->{sub_form_schema} = $schema;
    _basic_loop($schema->{columns}, 'sub_form_column', @_);
}

sub hdlr_SubFormColumn {
    my ( $ctx, $args ) = @_;
    defined( my $column = _require_context_column(@_) ) || return;

    my $key = $args->{key} || $args->{attr}
        || return $ctx->error(plugin->translate('mt:[_1] template tag requires at least one of [_2] as attributes.', $ctx->stash('tag'), 'key, attr'));

    my $value = $column->{$key};
    $value = '' unless defined $value;

    $value;
}

sub hdlr_SubFormRows {
    my ( $ctx, $args, $cond ) = @_;
    defined( my $data = _require_context_data(@_) ) || return;

    local $ctx->{__stash}->{sub_form_data} = $data;
    _basic_loop($data, 'sub_form_row', @_);
}

sub hdlr_SubFormRow {
    my ( $ctx, $args, $cond ) = @_;
    defined( my $row = _require_context_row($ctx, $args) ) || return;

    local $ctx->{__stash}->{sub_form_row} = $row;
    my $builder = $ctx->stash('builder');
    my $tokens = $ctx->stash('tokens');
    defined( my $partial = $builder->build($ctx, $tokens, $cond) ) || return;

    $partial;
}

sub hdlr_SubFormCell {
    my ( $ctx, $args ) = @_;
    defined( my $cell = _require_context_cell($ctx, $args) ) || return;
    $cell;
}

# Inspired from ContextHandlers.pm in Commercial.pack
sub hdlr_SubFormCellAsset {
    my ( $ctx, $args, $cond ) = @_;
    defined( my $value = _require_context_cell($ctx, $args) ) || return;
    return '' unless $value;

    my $tokens  = $ctx->stash('tokens');
    my $builder = $ctx->stash('builder');
    my $res     = '';

    $args->{no_asset_cleanup} = 1;

    require MT::Asset;
    while ( $value
        =~ m!<form[^>]*?\smt:asset-id=["'](\d+)["'][^>]*?>(.+?)</form>!gis )
    {
        my $id = $1;

        my $asset = MT::Asset->load($id);
        next unless $asset;

        local $ctx->{__stash}{asset} = $asset;
        defined( my $out = $builder->build( $ctx, $tokens ) )
            or return $ctx->error( $builder->errstr );
        $res .= $out;
    }

    $res;
}

sub hdlr_SubFormHeader {
    my ( $ctx, $args, $cond ) = @_;
    $ctx->var('__first__');
}

sub hdlr_SubFormFooter {
    my ( $ctx, $args, $cond ) = @_;
    $ctx->var('__last__');
}

sub hdlr_IfSubFormCustomField {
    my ( $ctx, $args, $cond ) = @_;
    my $schema = _context_schema(@_);
    $schema ? 1 : 0;
}

sub hdlr_SubFormBuild {
    my ( $ctx, $args ) = @_;
    my ( $schema, $data );

    local $ctx->{__stash}{sub_form_data} = $data = _context_data(@_) || return '';
    local $ctx->{__stash}{sub_form_schema} = $schema = _context_schema(@_);

    if ( $args->{module} || $args->{widget} || $args->{name} || $args->{file} || $args->{identifier} ) {
        return $ctx->invoke_handler('include', $args );
    } elsif ( $schema && $schema->{mtTemplate} ) {
        my $builder = $ctx->stash('builder');
        my $tokens = $builder->compile($ctx, $schema->{mtTemplate});
        defined( my $res = $builder->build($ctx, $tokens) )
            || return $ctx->error($builder->errstr);
        return $res;
    }

    '';
}

1;