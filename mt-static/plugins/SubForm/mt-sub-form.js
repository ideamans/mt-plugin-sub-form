(function($) {
    $.mtSubFormOld = {
        safeSetupForm: function(args) {
            try {
                $.mtSubForm.setupForm(args);
            } catch ( ex ) {
                if ( console ) {
                    console.log(ex);
                } else {
                    alert(ex.message || ex);
                }
            }
        },
        setupForm: function(args) {
            var $form = args.form,
                $input = args.input,
                options = args.options,
                forces = $.extend(args.forces, $.mtSubForm.forceOptions);

            // Default options
            var defaults = $.extend({
                i18n: $.mtSubForm.i18n
            }, $.mtSubForm.defaultOptions);

            var opts = $.extend(defaults, options);

            // Serialize on submit event
            $form.closest('form').submit(function() {
                var value = { values: [] };
                var json = JSON.stringify(value);

                try {
                    var str = JSON.parse(json);
                    if ( typeof str == 'string' ) { json = str; }
                } catch (ex) {}

                if ( $input )
                    $input.val(json);

                return true;
            });

            // Hide textarea
            if ( $input )
                $input.addClass('hidden');
        },
        defaultOptions: {},
        forceOptions: {},
        translate: function(phrase) {
            return $.mtSubForm.i18n[phrase] || phrase;
        },
        selectAssetUrlBase: '',
        i18n: {}
    };

    $.mtSubForm = {
        stringify : function (obj) {
            var t = typeof (obj);
            if (t != "object" || obj === null) {
                // simple data type
                if (t == "string") obj = '"' + obj + '"';
                return String(obj);
            } else {
                // recurse array or object
                var n, v, json = [], arr = (obj && obj.constructor == Array);
                for (n in obj) {
                    v = obj[n];
                    t = typeof(v);
                    if (obj.hasOwnProperty(n)) {
                        if (t == "string") v = '"' + v.replace(/"/g, '\\"').replace(/\n/g, 'n') + '"'; else if (t == "object" && v !== null) v = $.mtSubForm.stringify(v);
                        json.push((arr ? "" : '"' + n + '":') + String(v));
                    }
                }
                return (arr ? "[" : "{") + String(json) + (arr ? "]" : "}");
            }
        },
        bootupCustomFieldPreview: function(me, type) {
            $.mtSubForm.bootupPreview(me, {
                getter: function() {
                    var data = {
                        schema_html: $('#options').val(),
                        schema_head: '',
                    };
                    return data;
                }
            });
        },
        bootupSchemaPreview: function(me) {
            $.mtSubForm.bootupPreview(me, {
                getter: function() {
                    var data = {
                        schema_html: $('#schema_html').val(),
                        schema_head: $('#schema_head').val(),
                    };
                    return data;
                }
            });
        },
        bootupPreview: function(me, options) {
            var $button = $(me);
            if ( $button.data('sub_form_preview_bootup') )
                return false;

            var $wrapper = $button.closest('.preview-wrapper');
            var defaults = {
                wrapper: $wrapper,
                previewUrl: $button.attr('data-preview-uri'),
                head: $wrapper.find('.preview-head'),
                form: $wrapper.find('.preview-form'),
                formWrapper: $wrapper.find('.preview-form-wrapper'),
                indicator: $wrapper.find('.preview-indicator'),
                error: $wrapper.find('.preview-error'),
                button: $button,
                getter: function() { return {} }
            };

            var opts = $.extend(defaults, options);
            $.mtSubForm.previewer(opts);

            $button.data('sub_form_preview_bootup', true);
        },
        previewer: function(opts) {
            var $form = opts.form,
                $head = opts.head,
                $formWrapper = opts.formWrapper,
                $indicator = opts.indicator,
                $error = opts.error,
                $button = opts.button;

            var updatePreview = function() {
                $form.children().remove();
                $head.children().remove();
                $formWrapper.hide();
                $error.hide();

                // Not Ajax
                // $indicator.fadeIn('fast');

                var data = opts.getter();
                $head.html(data.schema_head);
                $form.html(data.schema_html);
                $formWrapper.fadeIn('fast');
            };

            $button.click(updatePreview);
            updatePreview();
        },
        setAsset: function(sub_form_id, html) {
            var $preview = $('div.sub-form-preview[sub-form-id="' + sub_form_id + '"]'),
                $enclosure = $(html),
                $input = $('input[sub-form-id="' + sub_form_id + '"]'),
                $remover = $('a.sub-form-remover[sub-form-id="' + sub_form_id + '"]');

            // Value
            $input.val(html);
            if ( ! $enclosure.hasClass('mt-enclosure') ) return;

            // Build image preview
            if ( $enclosure.hasClass('mt-enclosure-image') ) {
                var $anchor = $enclosure.find('a'),
                    $img = $('<img />').css({'max-width': '160px', 'max-height': '160px'});
                $img.attr('src', $anchor.attr('href'));
                $anchor.html('').append($img);
            }

            // Preview and show remover
            $preview.html($enclosure.html());
            $remover.removeClass('hidden');
        },
        runCallbacks: function(callback, caller, context) {
            $.each($.mtSubForm[callback], function(key, cb) {
                cb.call(caller, context);
            });
        },
        setUpControlCallbacks: {
            mtAsset: function(context) {
                if ( context.tagName == 'input' && context.type == 'hidden' ) {
                    var $control = $(context.control);
                    var asset = $control.attr('mt-asset');

                    if ( asset ) {
                        var sub_form_id = 'subformfield_' + Math.random();

                        // filter=class&amp;filter_val=<mt:var name="asset_type">&amp;require_type=<mt:var name="asset_type">&amp;
                        var url = $.mtSubForm.selectAssetUrlBase;
                        url += '&amp;edit_field=' + sub_form_id;
                        if ( !asset || asset == '*' ) {
                            url += '&amp;filter=class&amp;filter_val=' + params.assetType + '&amp;require_type=' + params.assetType;
                        }

                        $control
                            .attr('sub-form-id', sub_form_id);
                        var $preview = $('<div />')
                            .addClass('sub-form-preview')
                            .attr('sub-form-id', sub_form_id);
                        var $buttons = $('<div />')
                            .addClass('actions-bar');
                        var $select = $('<a />')
                            .attr('href', url)
                            .addClass('mt-open-dialog sub-form-select')
                            .text($.mtSubForm.translate('Select'))
                            .appendTo($buttons);
                        var $cancel = $('<a />')
                            .attr('href', '#')
                            .attr('sub-form-id', sub_form_id)
                            .addClass('hidden sub-form-remover')
                            .text($.mtSubForm.translate('Remove'))
                            .click(function() {
                                $(this).addClass('hidden');
                                $control.val('');
                                $preview.children().remove();
                            })
                            .appendTo($buttons);

                        $control.after($buttons).after($preview);
                    }
                }
            }
        },
        setControlValueCallbacks: {
            mtAsset: function(context) {
                if ( context.tagName == 'input' && context.type == 'hidden' ) {
                    var $control = $(context.control);
                    var asset = $control.attr('mt-asset');

                    if ( asset ) {
                        var sub_form_id = $control.attr('sub-form-id');
                        $.mtSubForm.setAsset(sub_form_id, $control.val());
                    }
                }
            }
        },
        getControlValueCallbacks: {
            mtAsset: function(context) {

            }
        },
        defaultOptions: {},
        forceOptions: {},
        translate: function(phrase) {
            return $.mtSubForm.i18n[phrase] || phrase;
        },
        i18n: {},
        selectAssetUrlBase: ''
    };

    $.widget('mt.subForm', {
        defaults: {
            valuesSelector: '.sub-form-values',
            formSelector: '.sub-form',
        },
        _init: function(options) {
            var opts = $.extend(this.defaults, $.mtSubForm.defaultOptions, options, $.mtSubForm.forceOptions),
                subform = this,
                $subform = $(this.element);

            subform.jqValues = $subform.find(opts.valuesSelector);
            subform.jqForm = $subform.find(opts.formSelector);

            subform.setUp();

            var values = subform.parseValues(subform.jqValues.val());
            subform.setValues(values);

            $subform.find('.get-values').click(function() {
                subform.formToJson();
                return false;
            });

            $subform.find('.set-values').click(function() {
                subform.jsonToForm();
                return false;
            });

            $subform.closest('form').submit(function() {
                subform.formToJson();
                subform.tearDown();
                return true;
            });
        },
        formToJson: function() {
            var subform = this;

            var values = subform.getValues();
            var json = subform.stringifyValues(values);

            subform.jqValues.val(json);
        },
        jsonToForm: function() {
            var subform = this;
            var values = subform.parseValues(subform.jqValues.val());

            subform.setValues(values);
        },
        parseValues: function(json) {
            var values = {};
            try {
                values = JSON.parse(json);
            } catch(ex) {}

            if ( typeof values == 'string' ) {
                values = JSON.parse(values);
            }

            if ( !values || !values instanceof Object ) { values = {}; }
            return values;
        },
        stringifyValues: function(values) {
            var json = $.mtSubForm.stringify(values);
            try {
                var str = JSON.parse(json);
                if ( typeof str == 'string' ) { json = str; }
            } catch (ex) {}
            return json;
        },
        setUp: function() {
            var subform = this;
            subform.jqForm.find('input,textarea,select').each(function() {
                var control = this,
                    $control = $(this);
                var tagName = control.tagName.toLowerCase(),
                    type = ( $control.attr('type') || '').toLowerCase(),
                    name = $control.attr('name') || '';

                // Change to anonymous name
                $control.attr('sub-form-name', name);
                $control.attr('name', 'sub-form-' + name + Math.random());

                $.mtSubForm.runCallbacks('setUpControlCallbacks', subform, {
                    control: control,
                    tagName: tagName,
                    type: type,
                    name: name
                });
            });
        },
        tearDown: function() {
            this.jqForm.children().remove();
        },
        setValues: function(values) {
            var subform = this;
            subform.jqForm.find('input,textarea,select').each(function() {
                var control = this,
                    $control = $(this);
                var tagName = control.tagName.toLowerCase(),
                    type = ( $control.attr('type') || '').toLowerCase(),
                    name = $control.attr('sub-form-name') || '';
                var tupples = values[name];
                if ( !tupples || !tupples instanceof Array || tupples.length < 1 ) return;

                if ( tagName === 'textarea' ) {
                    // textarea
                    $control.val(tupples[0].value);
                } else if ( tagName === 'select' ) {
                    // select: single or multiple
                    var selected = {};
                    $.each(tupples, function(i, tupple) {
                        selected[tupple.value] = true;
                    });
                    $control.find('option').each(function() {
                        var value = $(this).attr('value');
                        if ( selected[value] ) {
                            $(this).attr('selected', 'selected');
                        } else {
                            $(this).removeAttr('selected');
                        }
                    });
                } else {
                    // input
                    var type = $control.attr('type'),
                        value = $control.attr('value');
                    if ( type === 'radio' || type == 'checkbox' ) {
                        // type=radio or type=checkbox
                        var match = $.grep(tupples, function(tupple) { return tupple.value == value; });
                        if ( match.length > 0 ) {
                            $control.attr('checked', 'checked');
                        } else {
                            $control.removeAttr('checked');
                        }
                    } else {
                        // type=text(includes email,tel,etc.) or type=hidden
                        $control.val(tupples[0].value);
                    }
                }

                $.mtSubForm.runCallbacks('setControlValueCallbacks', subform, {
                    control: control,
                    tagName: tagName,
                    type: type,
                    name: name,
                    tupples: tupples,
                    values: values
                });
            });
        },
        getValues: function() {
            var values = {},
                subform = this;

            subform.jqForm.find('input,textarea,select').each(function() {
                var control = this,
                    $control = $(this);
                var tagName = control.tagName.toLowerCase(),
                    type = ( $control.attr('type') || '').toLowerCase(),
                    name = $control.attr('sub-form-name') || '';
                var tupples = values[name] || ( values[name] = [] );

                if ( tagName === 'textarea' ) {
                    // textarea
                    tupples[0] = { value: $control.val() };
                } else if ( tagName === 'select' ) {
                    // select: single or multiple
                    $control.find('option:selected').each(function() {
                        var $option = $(this);
                        tupples.push( { value: $option.attr('value'), label: $option.text() });
                    });
                } else {
                    // input
                    if ( type === 'radio' || type === 'checkbox' ) {
                        // type=radio or type=checkbox
                        if ( $control.attr('checked') ) {
                            var tupple = { value: $control.attr('value') };
                            var $label = $control.closest('label');
                            if ( $label.length > 0 ) {
                                tupple.label = $label.text().replace(/^\s+|\s+$/, '');
                            } else {
                                var id = $control.attr('id');
                                $label = $('label[for="' + id + '"]');
                                if ( $label.length > 0 ) {
                                    tupple.label = $label.text().replace(/^\s+|\s+$/, '');
                                }
                            }

                            tupples.push( tupple );
                        }
                    } else {
                        // type=text(includes email,tel,etc.) or type=hidden
                        tupples[0] = { value: $control.val() };
                    }
                }

                $.mtSubForm.runCallbacks('getControlValueCallbacks', subform, {
                    control: control,
                    tagName: tagName,
                    type: type,
                    name: name,
                    tupples: tupples,
                    values: values
                });
            });

            return values;
        }
    });

})(jQuery);
