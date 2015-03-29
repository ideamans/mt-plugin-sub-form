package MT::SubForm::Tags;

use strict;
use warnings;
use utf8;

use Data::Dumper;
use MT::Util;
use MT::SubForm::Util;

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
    } else {
        return '';
    }

    if ( ref $data eq '' ) {
        # Parse as JSON
        return '' if $data eq '';
        $data = eval { MT::Util::from_json($data) }
            || return $ctx->error(plugin->translate('SubForm data is not JSON format.'));
    }

    return $ctx->error(plugin->translate('SubForm data is not a hash.'))
        if ref $data ne 'HASH';

    foreach my $key ( keys %$data ) {
        my $hash = $data->{$key};
        return $ctx->error(plugin->translate('SubForm data is not a hash of an array.'))
             if ref $hash ne 'ARRAY';
    }

    $data;
}

sub _context_schema {
    my ( $ctx, $args, $cond ) = @_;
    my $blog = $ctx->stash('blog');
    my $schema;

    if ( my $basename = $args->{basename} ) {
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

    $schema;
}

sub _require_context_data {
    my ( $ctx, $args, $cond ) = @_;
    defined( my $data = _context_data(@_) ) || return;
    return $ctx->error(plugin->translate('No SubForm data context. Set SubForm customfield tag as tag attribute.'))
        unless $data;

    $data;
}

sub _require_context_values {
    my ( $ctx, $args ) = @_;
    defined( my $data = _require_context_data(@_) ) || return;
    return '' if ref $data ne 'HASH';

    my $name;
    my $values;
    if ( defined( $name = $args->{name} ) ) {
        $name = $args->{prefix} . $name if defined($args->{prefix});
        $name .= $args->{suffix} if defined($args->{suffix});
        $values = $data->{$name};
    } elsif ( $ctx->stash('sub_form_values') ) {
        $values = $ctx->stash('sub_form_values');
    } else {
        return $ctx->error(plugin->translate('Use mt:[_1] tag with name attribute.', $ctx->stash('tag')));
    }

    defined( $values ) ? $values : '';
}

sub _require_context_hash {
    my ( $ctx, $args ) = @_;
    defined( my $values = _require_context_values(@_) ) || return;
    return '' if ref $values ne 'ARRAY';

    my $hash;
    if ( $ctx->stash('sub_form_hash') ) {
        $hash = $ctx->stash('sub_form_hash');
    } else {
        $hash = $values->[0];
    }

    defined( $hash ) ? $hash : '';
}

sub _require_context_value {
    my ( $ctx, $args ) = @_;
    defined( my $hash = _require_context_hash(@_) ) || return;
    return '' if ref $hash ne 'HASH';

    my $value;
    my $key = $args->{key} || 'value';

    $hash->{$key} || '';
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

    my ( $data );
    defined( $data = _require_context_data(@_) ) || return;
    local $ctx->{__stash}->{sub_form_data} = $data;

    my %vars;
    if ( defined $args->{vars} ) {
        my $prefix = $args->{vars};
        if ( $prefix ne '0' ) {
            $prefix = 'subform' if $prefix eq '1';
            $prefix .= '_' if $prefix ne '';

            my $glue = $args->{vars_glue};
            $glue = ',' unless defined $glue;

            foreach my $key ( %$data ) {
                my $values = $data->{$key} || next;
                my $var = $prefix . $key;
                foreach my $attr ( qw(value label) ) {
                    my $val = join($glue, map { ref $_ eq 'HASH' ? ( defined $_->{$attr} ? $_->{$attr} : '' ) : '' } @$values );
                    $vars{$var . '_' . $attr} = $val if defined $val;
                }

                $vars{$var} = $vars{$var . '_value'} if defined $vars{$var . '_value'};
                $vars{$var . '_loop'} = $values;
            }
        }
    }
    local @{ $ctx->{__stash}->{vars} }{ keys %vars } = values %vars;

    my $builder = $ctx->stash('builder');
    my $tokens = $ctx->stash('tokens');
    defined( my $partial = $builder->build($ctx, $tokens, $cond) ) || return;

    $partial;
}

sub hdlr_SubFormValues {
    my ( $ctx, $args, $cond ) = @_;
    defined( my $values = _require_context_values(@_) ) || return;
    local $ctx->{__stash}{sub_form_values} = $values;

    _basic_loop( $values, 'sub_form_hash', @_ );
}

sub hdlr_SubFormValue {
    my ( $ctx, $args ) = @_;
    if ( defined( my $glue = $args->{glue} ) ) {
        defined( my $values = _require_context_values(@_) ) || return;
        return '' if ref $values ne 'ARRAY';

        my $key = $args->{key} || 'value';
        return join($glue, map { $_->{$key} || '' } @$values );
    } else {
        defined( my $value = _require_context_value(@_) ) || return;
        return $value;
    }
}

sub hdlr_IfSubFormHas {
    my ( $ctx, $args, $cond ) = @_;
    defined( my $data = _require_context_data(@_) ) || return;
    return 0 unless $data;
    defined( my $values = _require_context_values(@_) ) || return;
    return 0 unless $values;

    my $key = $args->{key} || 'value';
    my $eq = $args->{eq};
    my $match;

    if ( defined($eq) ) {
        $match = grep { defined($_->{$key}) && $_->{$key} eq $eq } @$values;
    } else {
        $match = grep { defined($_->{$key}) } @$values;
    }

    $match ? 1 : 0;
}

# Inspired from ContextHandlers.pm in Commercial.pack
sub hdlr_SubFormAsset {
    my ( $ctx, $args, $cond ) = @_;
    defined( my $value = _require_context_value(@_) ) || return;
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

sub hdlr_SubFormBuild {
    my ( $ctx, $args ) = @_;
    my ( $schema );

    defined( my $data = _context_data(@_) ) || return;
    return '' unless $data;
    local $ctx->{__stash}{sub_form_data} = $data;

    defined( $schema = _context_schema(@_) ) || return;
    local $ctx->{__stash}{sub_form_schema} = $schema;

    if ( $args->{module} || $args->{widget} || $args->{name} || $args->{file} || $args->{identifier} ) {
        return $ctx->invoke_handler('include', $args );
    } elsif ( $schema ) {
        my $builder = $ctx->stash('builder');
        my $tokens = $builder->compile($ctx, $schema->template);
        defined( my $res = $builder->build($ctx, $tokens) )
            || return $ctx->error($builder->errstr);

        return $res;
    }

    '';
}

1;