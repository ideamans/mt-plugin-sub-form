(function($) {
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
                        if (t == "string") v = '"' + v.replace(/"/g, '\\"').replace(/\n/g, '\\n').replace(/\t/g, '\\t') + '"'; else if (t == "object" && v !== null) v = $.mtSubForm.stringify(v);
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
                // head: $wrapper.find('.preview-head'),
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
                $formWrapper = opts.formWrapper,
                $indicator = opts.indicator,
                $error = opts.error,
                $button = opts.button;

            var updatePreview = function() {
                $form.children().remove();
                $formWrapper.hide();
                $error.hide();
                $indicator.fadeIn('fast');

                var data = opts.getter();

                $.post(opts.previewUrl, data)
                    .done(function(data) {
                        if ( data.error ) {
                            $error.show().find('p.msg-text').text(data.error);
                        } else if ( data.result && data.result ) {
                            try {
                              $form.html(data.result.built_schema_html);
                              $formWrapper.fadeIn('fast');
                              $form.subForm();
                            } catch (ex) {
                              if ( console ) console.log(ex);
                              $error.show().find('p.msg-text').text(ex.message);
                            }
                        }
                    })
                    .fail(function(status, line, jqXHR) {
                        $error.show().find('p.msg-text').text(status + " " + line);
                    })
                    .always(function() {
                        $indicator.hide();
                    });
            };

            $button.click(updatePreview);
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
                    $img = $('<img />').css({'max-width': '100%'});
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
                        var $spacer = $('<span> </span>')
                            .appendTo($buttons);
                        var $cancel = $('<a />')
                            .attr('href', 'javascript:void(0)')
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
        validationEngineOptions: {
            promptPosition: 'centerRight'
        },
        i18n: {},
        selectAssetUrlBase: ''
    };

    $.widget('mt.subForm', {
        defaults: {
            valuesWrapperSelector: '.sub-form-values-wrapper',
            valuesSelector: '.sub-form-values',
            formSelector: '.sub-form'
        },
        _init: function(options) {
            var opts = $.extend(this.defaults, $.mtSubForm.defaultOptions, options, $.mtSubForm.forceOptions),
                subform = this,
                $subform = $(this.element);

            subform.jqContainer = $subform;
            subform.jqValuesWrapper = $subform.find(opts.valuesWrapperSelector);
            subform.jqValues = $subform.find(opts.valuesSelector);
            subform.jqForm = $subform.find(opts.formSelector);

            subform.jqControll = $subform.find('.sub-form-controll');
            subform.jqShowJson = $subform.find('.sub-form-show-json');
            subform.jqHideJson = $subform.find('.sub-form-hide-json');
            subform.jqGetJson = $subform.find('.sub-form-get-json');
            subform.jqSetJson = $subform.find('.sub-form-set-json');
            subform.jqParentForm = $subform.closest('form');

            subform.setUp();

            var values = subform.parseValues(subform.jqValues.val());
            subform.setValues(values);

            subform.jqShowJson.click(function() {
                subform.setStatus('json')
                return false;
            });

            subform.jqHideJson.click(function() {
                subform.setStatus('live')
                return false;
            });

            subform.jqGetJson.click(function() {
                subform.formToJson();
                return false;
            });

            subform.jqSetJson.click(function() {
                subform.jsonToForm();
                return false;
            });

            subform.jqParentForm.submit(function() {
                subform.formToJson();
                subform.tearDown();
                return true;
            });
        },
        setStatus: function(status) {
            if ( status == 'json' ) {
                this.jqContainer.removeClass('sub-form-mode-live').addClass('sub-form-mode-json');
            } else { // stauts == 'live'
                this.jqContainer.addClass('sub-form-mode-live').removeClass('sub-form-mode-json');
            }
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
            // this.jqForm.children().remove();
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
