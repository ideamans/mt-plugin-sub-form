package MT::SubForm::L10N::ja;

use strict;
use utf8;
use base 'MT::SubForm::L10N::en_us';
use vars qw( %Lexicon );

%Lexicon = (

## config.yaml
    'Adds subform type customfield by casual HTML code.' => 'HTMLコードによる気軽なサブフォームタイプのカスタムフィールドを追加します。',
    'SubForm configured by HTML' => 'SubForm フォームフィールド(HTML設定)',
    'SubForm selected from schemas' => 'SubForm フォームフィールド(スキーマ選択)',

## lib/MT/SubForm/Schema.pm
    'SubForm Schema' => 'SubFormスキーマ',
    'SubForm Schemas' => 'SubFormスキーマ',
    '[_1] is not in a JSON format.' => '[_1]はJSON形式ではありません。',
    'Schema YAML or JSON is malformed.' => 'スキーマがYAMLまたはJSONの形式として正しくありません。',

## lib/MT/SubForm/CMS/Schema.pm
    'Name is required.' => '名前は必須項目です。',

## lib/MT/AssetGrid/CustomFields.pm
    'JSON is not parsable because [_1]: [_2]' => '解析できないJSONデータです(理由: [_1]): [_2]',
    'JSON data must be an array of hash: [_1]' => 'JSONデータはハッシュの配列である必要があります: [_1]',

## lib/MT/SubForm/Tag.pm
    'SubForm Customfield which basename is "[_1]" is not found.' => '"[_1]"というベースネームのカスタムフィールドは存在しません。',
    'SubForm Customfield which tag is "[_1]" is not found.' => '"[_1]"というタグ名のカスタムフィールドは存在しません。',
    'SubForm data is not JSON format.' => 'SubFormデータがJSON形式ではありません。',
    'SubForm data is not a hash.' => 'SubFormデータがハッシュではありません。',
    'SubForm data is not a hash of an array.' => 'SubFormデータが配列のハッシュではありません。',
    'Use mt:[_1] tag with name attribute.'
        => 'mt:[_1]テンプレートタグには、name属性を指定してください。',
    'No SubForm schema context. Set SubForm customfield basename as basename attribute of SubFormColumns or SubForm template tag.'
        => 'SubFormスキーマがコンテキストにありません。mt:SubFormColumnsまたは上位のmt:SubFormテンプレートタグにbasename属性としてSubFormカスタムフィールドのベースネームを指定してください。',
    'No SubForm data context. Set SubForm customfield tag as tag attribute.'
        => 'SubFormデータがコンテキストにありません。tag属性としてSutFormカスタムフィールドのタグ名を指定してください。',
    '[_1] template tag requires [_2] attribute.' => '[_1]テンプレートタグには[_2]属性が必要です。',
    'No SubForm row context. Set index as row attribute of SubFormRow template tag or use in SubFormRows template tag.'
        => 'SubForm行データがコンテキストにありません。mt:SubFormRowにrow属性として行インデックスを指定するか、SubFormRowsテンプレートタグの内部で使用してください。',
    'No SubForm column context. Use in SubFormColumns template tag.' => 'SubForm列情報がコンテキストにありません。mt:SubFormColumnsテンプレートタグの内部で使用してください。',
    'mt:[_1] template tag requires at least one of [_2] as attributes.' => 'mt:[_1]テンプレートタグは、[_2]のいずれかの属性が必要です。',
    'No column definition named "[_1]".' => '"[_1]"というnameの列定義は存在しません。',
    'No column indexed [_1].' => 'インデックス[_1]の列定義は存在しません。',

## tmpl/customfield/field.tmpl
    'Show JSON' => 'JSONデータを表示',
    'Hide JSON' => 'JSONデータを隠す',
    'SubForm to JSON' => 'SubFormからJSONへ',
    'JSON to SubForm' => 'JSONからSubFormへ',
    'JSON Data' => 'JSONデータ',
    'To update values of SubForm, paste JSON and press SubForm to JSON.' => 'JSONデータを貼り付けて、「SubFormからJSON」ボタンを押すと、SubFormの値を一括で更新できます。',

## tmpl/sub_form_with_json
    'Append' => '追加',
    'Remove Last' => '最後を削除',
    'Insert Above' => '上に挿入',
    'Remove' => '削除',
    'Move Up' => '上に移動',
    'Move Down' => '下に移動',
    'Move Row With Drag & Drop' => 'ドラッグ＆ドロップで行を移動',
    'No Row' => '行がありません',

## tmpl/cms/edit_sub_form_schema.tmpl
    'Edit SubForm Schema' => 'SubFormスキーマの編集',
    'Create SubForm Schema' => 'SubFormスキーマの作成',
    'Schema HTML Head' => 'スキーマHTMLヘッダ',
    'Schema HTML' => 'スキーマHTML',
    'Save changes to this schema (s)' => 'このスキーマを保存する',
    'Preview this scheama (p)' => 'このスキーマをプレビューする',
    'This is not required. Template to build SubForm data with mt:SubFormBuild tag.' => '任意項目です。mt:SubFormBuildテンプレートタグでこのSubFormに入力されたデータを再構築するテンプレートです。',

## tmpl/cms/list_sub_form_schema.tmpl
    'The schema has been deleted from the database.' => 'スキーマが削除されました。',
    'SubForm schema is preset table definition. You can create schema that can be shared by multiple custom fields.'
        => 'SubFormスキーマは、テーブル定義のプリセットです。複数のカスタムフィールドで共有することができます。',
);

1;

