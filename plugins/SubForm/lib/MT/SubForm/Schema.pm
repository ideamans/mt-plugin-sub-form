package MT::SubForm::Schema;

use strict;
use base qw( MT::Object );

use MT::Util qw(encode_html);
use MT::Util::YAML;
use MT::SubForm::Util;

__PACKAGE__->install_properties(
    {   column_defs => {
            'id'          => 'integer not null auto_increment',
            'blog_id'     => 'integer',
            'name'        => 'string(255) not null',
            'description' => 'text',
            'schema_head' => 'text',
            'schema_html' => 'text',
            'template' => 'text',
        },
        indexes => {
            blog_id  => 1,
            name     => 1,
        },
        primary_key => 'id',
        audit       => 1,
        datasource  => 'sub_form_schema',
        child_of    => [ 'MT::Blog', 'MT::Website' ],
    }
);

sub class_label {
    return plugin->translate("SubForm Schema");
}

sub class_label_plural {
    return plugin->translate("SubForm Schemas");
}

sub validate { 1 }

sub _build_template {
    my $self = shift;
    my ( $template ) = @_;

    require MT::Builder;
    require MT::Template::Context;
    my $ctx = MT::Template::Context->new;
    my $builder = MT::Builder->new;

    my $tokens = $builder->compile($ctx, $template)
        || return $self->error($builder->errstr || 'Feild to compile.');
    defined ( my $result = $builder->build($ctx, $tokens) )
        || return $self->error($builder->errstr || 'Failed to build.');

    $result;
}

sub build_schema_head {
    my $self = shift;
    $self->_build_template($self->schema_head);
}

sub build_schema_html {
    my $self = shift;
    $self->_build_template($self->schema_html);
}

sub list_props {
    return {
        id => {
            base  => '__virtual.id',
            order => 100,
        },
        name => {
            auto      => 1,
            label     => 'Name',
            order     => 200,
            display   => 'force',
            html_link => sub {
                my ( $prop, $obj, $app ) = @_;
                return $app->uri(
                    mode => 'view',
                    args => { _type => 'sub_form_schema', blog_id => $obj->blog_id, id => $obj->id },
                );
            },
        },
        blog_name => {
            label     => 'Website/Blog Name',
            base      => '__virtual.blog_name',
            order     => 400,
            display   => 'default',
            view      => ['system'],
            bulk_html => sub {
                my $prop     = shift;
                my ($objs)   = @_;
                my %blog_ids = map { $_->blog_id => 1 } @$objs;
                my @blogs    = MT->model('blog')->load(
                    { id => [ keys %blog_ids ], },
                    {   fetchonly => {
                            id        => 1,
                            name      => 1,
                            parent_id => 1,
                        }
                    }
                );
                my %blog_map = map { $_->id        => $_ } @blogs;
                my %site_ids = map { $_->parent_id => 1 }
                    grep { $_->parent_id && !$blog_map{ $_->parent_id } }
                    @blogs;
                my @sites
                    = MT->model('website')
                    ->load( { id => [ keys %site_ids ], },
                    { fetchonly => { id => 1, name => 1, }, } )
                    if keys %site_ids;
                my %urls = map {
                    $_->id => MT->app->uri(
                        mode => 'list',
                        args => {
                            _type   => 'sub_form_schema',
                            blog_id => $_->id,
                        }
                    );
                } @blogs;
                my %blog_site_map = map { $_->id => $_ } ( @blogs, @sites );
                my @out;

                for my $obj (@$objs) {
                    if ( !$obj->blog_id ) {
                        push @out, MT->translate('(system)');
                        next;
                    }
                    my $blog = $blog_site_map{ $obj->blog_id };
                    unless ($blog) {
                        push @out, MT->translate('*Website/Blog deleted*');
                        next;
                    }

                    my $name = undef;
                    if ( ( my $site = $blog_site_map{ $blog->parent_id } )
                        && $prop->site_name )
                    {
                        $name = join( '/', $site->name, $blog->name );
                    }
                    else {
                        $name = $blog->name;
                    }

                    push @out,
                          '<a href="'
                        . $urls{ $blog->id } . '">'
                        . encode_html($name) . '</a>';
                }

                return @out;
            },
        },
        created_on => {
            base    => '__virtual.created_on',
            display => 'default',
            order   => 500,
        },
        modified_on => {
            base  => '__virtual.modified_on',
            order => 600,
        },
        description => {
            auto    => 1,
            display => 'default',
            label   => 'Description',
        },
    };
}

1;