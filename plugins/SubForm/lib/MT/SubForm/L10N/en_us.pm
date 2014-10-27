package MT::SubForm::L10N::en_us;

use strict;
use utf8;

use base 'MT::SubForm::L10N';
use vars qw( %Lexicon );
%Lexicon = ();

$Lexicon{_default_options_html} = <<'HTML';
<div>
    <label>Title</label>
    <input type="text" name="title" value="DEFAULT" />
</div>
<div>
    <label>Description</label>
    <textarea name="desc"></textarea>
</div>
HTML

$Lexicon{_default_options_head} = <<'HEAD';
<script type="text/javascript">
(function($) {
    // Do something
})(jQuery);
</script>
<style type="text/css">
    // Style something
</style>
HEAD

$Lexicon{_default_schema_template} = <<'EOT';
<mt:SubForm>
</mt:SubForm>
EOT

1;
