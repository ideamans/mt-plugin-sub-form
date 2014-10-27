package MT::SubForm::CMS::Asset;

use strict;
use warnings;
use MT::SubForm::Util;

# Inspired from CustomField::App::CMS::asset_insert_param
sub asset_insert_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $edit_field = $app->param('edit_field');

    return 1 unless $edit_field =~ /subformfield/;
    # $edit_field =~ s/subformfield/customfield/;
    $param->{'edit_field_id'} = $edit_field;

    my $block = $tmpl->getElementById('insert_script');
    return 1 unless $block;

    my $ctx = $tmpl->context;
    if ( my $asset = $ctx->stash('asset') ) {
        $param->{edit_field_value} = $asset->enclose($param->{upload_html});
        $block->innerHTML(
            qq{top.jQuery.mtSubForm.setAsset('<mt:var name="edit_field_id" escape="js">', '<mt:var name="edit_field_value" escape="js">'); }
        );
    }

    return 1;
}

1;