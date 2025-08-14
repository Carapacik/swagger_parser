import 'package:swagger_parser/src/parser/model/normalized_identifier.dart';
import 'package:test/test.dart';

void main() {
  final wordsToText = [
    // Basic cases
    (
      words: ['hello', 'world'],
      camelCase: 'helloWorld',
      kebabCase: 'hello-world',
      pascalCase: 'HelloWorld',
      screamingSnakeCase: 'HELLO_WORLD',
      screamingKebabCase: 'HELLO-WORLD',
      snakeCase: 'hello_world',
      trainCase: 'Hello-World'
    ),
    (
      words: ['first', 'name'],
      camelCase: 'firstName',
      kebabCase: 'first-name',
      pascalCase: 'FirstName',
      screamingSnakeCase: 'FIRST_NAME',
      screamingKebabCase: 'FIRST-NAME',
      snakeCase: 'first_name',
      trainCase: 'First-Name'
    ),
    (
      words: ['user', 'id'],
      camelCase: 'userId',
      kebabCase: 'user-id',
      pascalCase: 'UserId',
      screamingSnakeCase: 'USER_ID',
      screamingKebabCase: 'USER-ID',
      snakeCase: 'user_id',
      trainCase: 'User-Id'
    ),

    // Single words
    (
      words: ['hello'],
      camelCase: 'hello',
      kebabCase: 'hello',
      pascalCase: 'Hello',
      screamingSnakeCase: 'HELLO',
      screamingKebabCase: 'HELLO',
      snakeCase: 'hello',
      trainCase: 'Hello'
    ),
    (
      words: ['a'],
      camelCase: 'a',
      kebabCase: 'a',
      pascalCase: 'A',
      screamingSnakeCase: 'A',
      screamingKebabCase: 'A',
      snakeCase: 'a',
      trainCase: 'A'
    ),
    (
      words: ['i'],
      camelCase: 'i',
      kebabCase: 'i',
      pascalCase: 'I',
      screamingSnakeCase: 'I',
      screamingKebabCase: 'I',
      snakeCase: 'i',
      trainCase: 'I'
    ),

    // Empty and edge cases
    (
      words: <String>[],
      camelCase: '',
      kebabCase: '',
      pascalCase: '',
      screamingSnakeCase: '',
      screamingKebabCase: '',
      snakeCase: '',
      trainCase: ''
    ),
    (
      words: [''],
      camelCase: '',
      kebabCase: '',
      pascalCase: '',
      screamingSnakeCase: '',
      screamingKebabCase: '',
      snakeCase: '',
      trainCase: ''
    ),
    (
      words: ['', ''],
      camelCase: '',
      kebabCase: '',
      pascalCase: '',
      screamingSnakeCase: '',
      screamingKebabCase: '',
      snakeCase: '',
      trainCase: ''
    ),
    (
      words: ['', 'world'],
      camelCase: 'world',
      kebabCase: 'world',
      pascalCase: 'World',
      screamingSnakeCase: 'WORLD',
      screamingKebabCase: 'WORLD',
      snakeCase: 'world',
      trainCase: 'World'
    ),
    (
      words: ['hello', ''],
      camelCase: 'hello',
      kebabCase: 'hello',
      pascalCase: 'Hello',
      screamingSnakeCase: 'HELLO',
      screamingKebabCase: 'HELLO',
      snakeCase: 'hello',
      trainCase: 'Hello'
    ),

    // Numbers
    (
      words: ['user', '123'],
      camelCase: 'user123',
      kebabCase: 'user-123',
      pascalCase: 'User123',
      screamingSnakeCase: 'USER_123',
      screamingKebabCase: 'USER-123',
      snakeCase: 'user_123',
      trainCase: 'User-123'
    ),
    (
      words: ['123', 'user'],
      camelCase: '123User',
      kebabCase: '123-user',
      pascalCase: '123User',
      screamingSnakeCase: '123_USER',
      screamingKebabCase: '123-USER',
      snakeCase: '123_user',
      trainCase: '123-User'
    ),
    (
      words: ['123'],
      camelCase: '123',
      kebabCase: '123',
      pascalCase: '123',
      screamingSnakeCase: '123',
      screamingKebabCase: '123',
      snakeCase: '123',
      trainCase: '123'
    ),
    (
      words: ['user123'],
      camelCase: 'user123',
      kebabCase: 'user123',
      pascalCase: 'User123',
      screamingSnakeCase: 'USER123',
      screamingKebabCase: 'USER123',
      snakeCase: 'user123',
      trainCase: 'User123'
    ),
    (
      words: ['123user'],
      camelCase: '123user',
      kebabCase: '123user',
      pascalCase: '123user',
      screamingSnakeCase: '123USER',
      screamingKebabCase: '123USER',
      snakeCase: '123user',
      trainCase: '123user'
    ),
    (
      words: ['user', '123', 'id'],
      camelCase: 'user123Id',
      kebabCase: 'user-123-id',
      pascalCase: 'User123Id',
      screamingSnakeCase: 'USER_123_ID',
      screamingKebabCase: 'USER-123-ID',
      snakeCase: 'user_123_id',
      trainCase: 'User-123-Id'
    ),

    // Mixed numbers and letters
    (
      words: ['web2', 'development'],
      camelCase: 'web2Development',
      kebabCase: 'web2-development',
      pascalCase: 'Web2Development',
      screamingSnakeCase: 'WEB2_DEVELOPMENT',
      screamingKebabCase: 'WEB2-DEVELOPMENT',
      snakeCase: 'web2_development',
      trainCase: 'Web2-Development'
    ),
    (
      words: ['h2o', 'formula'],
      camelCase: 'h2oFormula',
      kebabCase: 'h2o-formula',
      pascalCase: 'H2oFormula',
      screamingSnakeCase: 'H2O_FORMULA',
      screamingKebabCase: 'H2O-FORMULA',
      snakeCase: 'h2o_formula',
      trainCase: 'H2o-Formula'
    ),
    (
      words: ['mp3', 'player'],
      camelCase: 'mp3Player',
      kebabCase: 'mp3-player',
      pascalCase: 'Mp3Player',
      screamingSnakeCase: 'MP3_PLAYER',
      screamingKebabCase: 'MP3-PLAYER',
      snakeCase: 'mp3_player',
      trainCase: 'Mp3-Player'
    ),
    (
      words: ['base64', 'encode'],
      camelCase: 'base64Encode',
      kebabCase: 'base64-encode',
      pascalCase: 'Base64Encode',
      screamingSnakeCase: 'BASE64_ENCODE',
      screamingKebabCase: 'BASE64-ENCODE',
      snakeCase: 'base64_encode',
      trainCase: 'Base64-Encode'
    ),
    (
      words: ['utf8', 'string'],
      camelCase: 'utf8String',
      kebabCase: 'utf8-string',
      pascalCase: 'Utf8String',
      screamingSnakeCase: 'UTF8_STRING',
      screamingKebabCase: 'UTF8-STRING',
      snakeCase: 'utf8_string',
      trainCase: 'Utf8-String'
    ),

    // Acronyms and abbreviations
    (
      words: ['xml', 'http', 'request'],
      camelCase: 'xmlHttpRequest',
      kebabCase: 'xml-http-request',
      pascalCase: 'XmlHttpRequest',
      screamingSnakeCase: 'XML_HTTP_REQUEST',
      screamingKebabCase: 'XML-HTTP-REQUEST',
      snakeCase: 'xml_http_request',
      trainCase: 'Xml-Http-Request'
    ),
    (
      words: ['api', 'key'],
      camelCase: 'apiKey',
      kebabCase: 'api-key',
      pascalCase: 'ApiKey',
      screamingSnakeCase: 'API_KEY',
      screamingKebabCase: 'API-KEY',
      snakeCase: 'api_key',
      trainCase: 'Api-Key'
    ),
    (
      words: ['url', 'parser'],
      camelCase: 'urlParser',
      kebabCase: 'url-parser',
      pascalCase: 'UrlParser',
      screamingSnakeCase: 'URL_PARSER',
      screamingKebabCase: 'URL-PARSER',
      snakeCase: 'url_parser',
      trainCase: 'Url-Parser'
    ),
    (
      words: ['html', 'css', 'js'],
      camelCase: 'htmlCssJs',
      kebabCase: 'html-css-js',
      pascalCase: 'HtmlCssJs',
      screamingSnakeCase: 'HTML_CSS_JS',
      screamingKebabCase: 'HTML-CSS-JS',
      snakeCase: 'html_css_js',
      trainCase: 'Html-Css-Js'
    ),
    (
      words: ['pdf', 'document'],
      camelCase: 'pdfDocument',
      kebabCase: 'pdf-document',
      pascalCase: 'PdfDocument',
      screamingSnakeCase: 'PDF_DOCUMENT',
      screamingKebabCase: 'PDF-DOCUMENT',
      snakeCase: 'pdf_document',
      trainCase: 'Pdf-Document'
    ),
    (
      words: ['json', 'api'],
      camelCase: 'jsonApi',
      kebabCase: 'json-api',
      pascalCase: 'JsonApi',
      screamingSnakeCase: 'JSON_API',
      screamingKebabCase: 'JSON-API',
      snakeCase: 'json_api',
      trainCase: 'Json-Api'
    ),
    (
      words: ['sql', 'db'],
      camelCase: 'sqlDb',
      kebabCase: 'sql-db',
      pascalCase: 'SqlDb',
      screamingSnakeCase: 'SQL_DB',
      screamingKebabCase: 'SQL-DB',
      snakeCase: 'sql_db',
      trainCase: 'Sql-Db'
    ),

    // All caps words
    (
      words: ['USA'],
      camelCase: 'usa',
      kebabCase: 'usa',
      pascalCase: 'Usa',
      screamingSnakeCase: 'USA',
      screamingKebabCase: 'USA',
      snakeCase: 'usa',
      trainCase: 'Usa'
    ),
    (
      words: ['NASA', 'API'],
      camelCase: 'nasaApi',
      kebabCase: 'nasa-api',
      pascalCase: 'NasaApi',
      screamingSnakeCase: 'NASA_API',
      screamingKebabCase: 'NASA-API',
      snakeCase: 'nasa_api',
      trainCase: 'Nasa-Api'
    ),
    (
      words: ['HTTP', 'POST'],
      camelCase: 'httpPost',
      kebabCase: 'http-post',
      pascalCase: 'HttpPost',
      screamingSnakeCase: 'HTTP_POST',
      screamingKebabCase: 'HTTP-POST',
      snakeCase: 'http_post',
      trainCase: 'Http-Post'
    ),
    (
      words: ['XML', 'HTTP', 'REQUEST'],
      camelCase: 'xmlHttpRequest',
      kebabCase: 'xml-http-request',
      pascalCase: 'XmlHttpRequest',
      screamingSnakeCase: 'XML_HTTP_REQUEST',
      screamingKebabCase: 'XML-HTTP-REQUEST',
      snakeCase: 'xml_http_request',
      trainCase: 'Xml-Http-Request'
    ),

    // Mixed case acronyms
    (
      words: ['XMLParser'],
      camelCase: 'xmlparser',
      kebabCase: 'xmlparser',
      pascalCase: 'Xmlparser',
      screamingSnakeCase: 'XMLPARSER',
      screamingKebabCase: 'XMLPARSER',
      snakeCase: 'xmlparser',
      trainCase: 'Xmlparser'
    ),
    (
      words: ['HTMLElement'],
      camelCase: 'htmlelement',
      kebabCase: 'htmlelement',
      pascalCase: 'Htmlelement',
      screamingSnakeCase: 'HTMLELEMENT',
      screamingKebabCase: 'HTMLELEMENT',
      snakeCase: 'htmlelement',
      trainCase: 'Htmlelement'
    ),
    (
      words: ['HTTPSConnection'],
      camelCase: 'httpsconnection',
      kebabCase: 'httpsconnection',
      pascalCase: 'Httpsconnection',
      screamingSnakeCase: 'HTTPSCONNECTION',
      screamingKebabCase: 'HTTPSCONNECTION',
      snakeCase: 'httpsconnection',
      trainCase: 'Httpsconnection'
    ),
    (
      words: ['APIKey'],
      camelCase: 'apikey',
      kebabCase: 'apikey',
      pascalCase: 'Apikey',
      screamingSnakeCase: 'APIKEY',
      screamingKebabCase: 'APIKEY',
      snakeCase: 'apikey',
      trainCase: 'Apikey'
    ),
    (
      words: ['URLShortener'],
      camelCase: 'urlshortener',
      kebabCase: 'urlshortener',
      pascalCase: 'Urlshortener',
      screamingSnakeCase: 'URLSHORTENER',
      screamingKebabCase: 'URLSHORTENER',
      snakeCase: 'urlshortener',
      trainCase: 'Urlshortener'
    ),

    // Consecutive capitals
    (
      words: ['ALLCAPS'],
      camelCase: 'allcaps',
      kebabCase: 'allcaps',
      pascalCase: 'Allcaps',
      screamingSnakeCase: 'ALLCAPS',
      screamingKebabCase: 'ALLCAPS',
      snakeCase: 'allcaps',
      trainCase: 'Allcaps'
    ),
    (
      words: ['ALLCAPSWord'],
      camelCase: 'allcapsword',
      kebabCase: 'allcapsword',
      pascalCase: 'Allcapsword',
      screamingSnakeCase: 'ALLCAPSWORD',
      screamingKebabCase: 'ALLCAPSWORD',
      snakeCase: 'allcapsword',
      trainCase: 'Allcapsword'
    ),
    (
      words: ['wordALLCAPS'],
      camelCase: 'wordallcaps',
      kebabCase: 'wordallcaps',
      pascalCase: 'Wordallcaps',
      screamingSnakeCase: 'WORDALLCAPS',
      screamingKebabCase: 'WORDALLCAPS',
      snakeCase: 'wordallcaps',
      trainCase: 'Wordallcaps'
    ),
    (
      words: ['middleALLCAPSword'],
      camelCase: 'middleallcapsword',
      kebabCase: 'middleallcapsword',
      pascalCase: 'Middleallcapsword',
      screamingSnakeCase: 'MIDDLEALLCAPSWORD',
      screamingKebabCase: 'MIDDLEALLCAPSWORD',
      snakeCase: 'middleallcapsword',
      trainCase: 'Middleallcapsword'
    ),
  ];

  final textToWord = [
    // Basic cases
    (
      words: ['hello', 'world'],
      camelCase: 'helloWorld',
      kebabCase: 'hello-world',
      pascalCase: 'HelloWorld',
      screamingSnakeCase: 'HELLO_WORLD',
      screamingKebabCase: 'HELLO-WORLD',
      snakeCase: 'hello_world',
      trainCase: 'Hello-World'
    ),
    (
      words: ['first', 'name'],
      camelCase: 'firstName',
      kebabCase: 'first-name',
      pascalCase: 'FirstName',
      screamingSnakeCase: 'FIRST_NAME',
      screamingKebabCase: 'FIRST-NAME',
      snakeCase: 'first_name',
      trainCase: 'First-Name'
    ),
    (
      words: ['user', 'id'],
      camelCase: 'userId',
      kebabCase: 'user-id',
      pascalCase: 'UserId',
      screamingSnakeCase: 'USER_ID',
      screamingKebabCase: 'USER-ID',
      snakeCase: 'user_id',
      trainCase: 'User-Id'
    ),

    // Single words
    (
      words: ['hello'],
      camelCase: 'hello',
      kebabCase: 'hello',
      pascalCase: 'Hello',
      screamingSnakeCase: 'HELLO',
      screamingKebabCase: 'HELLO',
      snakeCase: 'hello',
      trainCase: 'Hello'
    ),
    (
      words: ['a'],
      camelCase: 'a',
      kebabCase: 'a',
      pascalCase: 'A',
      screamingSnakeCase: 'A',
      screamingKebabCase: 'A',
      snakeCase: 'a',
      trainCase: 'A'
    ),
    (
      words: ['i'],
      camelCase: 'i',
      kebabCase: 'i',
      pascalCase: 'I',
      screamingSnakeCase: 'I',
      screamingKebabCase: 'I',
      snakeCase: 'i',
      trainCase: 'I'
    ),

    // Empty case
    (
      words: <String>[],
      camelCase: '',
      kebabCase: '',
      pascalCase: '',
      screamingSnakeCase: '',
      screamingKebabCase: '',
      snakeCase: '',
      trainCase: ''
    ),

    // Numbers
    (
      words: ['123', 'user'],
      camelCase: '123User',
      kebabCase: '123-user',
      pascalCase: '123User',
      screamingSnakeCase: '123_USER',
      screamingKebabCase: '123-USER',
      snakeCase: '123_user',
      trainCase: '123-User'
    ),
    (
      words: ['123'],
      camelCase: '123',
      kebabCase: '123',
      pascalCase: '123',
      screamingSnakeCase: '123',
      screamingKebabCase: '123',
      snakeCase: '123',
      trainCase: '123'
    ),
    (
      words: ['user123'],
      camelCase: 'user123',
      kebabCase: 'user123',
      pascalCase: 'User123',
      screamingSnakeCase: 'USER123',
      screamingKebabCase: 'USER123',
      snakeCase: 'user123',
      trainCase: 'User123'
    ),
    (
      words: ['user123', 'id'],
      camelCase: 'user123Id',
      kebabCase: 'user-123-id',
      pascalCase: 'User123Id',
      screamingSnakeCase: 'USER123_ID',
      screamingKebabCase: 'USER123-ID',
      snakeCase: 'user123_id',
      trainCase: 'User123-Id'
    ),

    // Mixed numbers and letters
    (
      words: ['web2', 'development'],
      camelCase: 'web2Development',
      kebabCase: 'web2-development',
      pascalCase: 'Web2Development',
      screamingSnakeCase: 'WEB2_DEVELOPMENT',
      screamingKebabCase: 'WEB2-DEVELOPMENT',
      snakeCase: 'web2_development',
      trainCase: 'Web2-Development'
    ),
    (
      words: ['h2o', 'formula'],
      camelCase: 'h2oFormula',
      kebabCase: 'h2o-formula',
      pascalCase: 'H2oFormula',
      screamingSnakeCase: 'H2O_FORMULA',
      screamingKebabCase: 'H2O-FORMULA',
      snakeCase: 'h2o_formula',
      trainCase: 'H2o-Formula'
    ),
    (
      words: ['mp3', 'player'],
      camelCase: 'mp3Player',
      kebabCase: 'mp3-player',
      pascalCase: 'Mp3Player',
      screamingSnakeCase: 'MP3_PLAYER',
      screamingKebabCase: 'MP3-PLAYER',
      snakeCase: 'mp3_player',
      trainCase: 'Mp3-Player'
    ),
    (
      words: ['base64', 'encode'],
      camelCase: 'base64Encode',
      kebabCase: 'base64-encode',
      pascalCase: 'Base64Encode',
      screamingSnakeCase: 'BASE64_ENCODE',
      screamingKebabCase: 'BASE64-ENCODE',
      snakeCase: 'base64_encode',
      trainCase: 'Base64-Encode'
    ),
    (
      words: ['utf8', 'string'],
      camelCase: 'utf8String',
      kebabCase: 'utf8-string',
      pascalCase: 'Utf8String',
      screamingSnakeCase: 'UTF8_STRING',
      screamingKebabCase: 'UTF8-STRING',
      snakeCase: 'utf8_string',
      trainCase: 'Utf8-String'
    ),

    // Acronyms and abbreviations
    (
      words: ['xml', 'http', 'request'],
      camelCase: 'xmlHttpRequest',
      kebabCase: 'xml-http-request',
      pascalCase: 'XmlHttpRequest',
      screamingSnakeCase: 'XML_HTTP_REQUEST',
      screamingKebabCase: 'XML-HTTP-REQUEST',
      snakeCase: 'xml_http_request',
      trainCase: 'Xml-Http-Request'
    ),
    (
      words: ['api', 'key'],
      camelCase: 'apiKey',
      kebabCase: 'api-key',
      pascalCase: 'ApiKey',
      screamingSnakeCase: 'API_KEY',
      screamingKebabCase: 'API-KEY',
      snakeCase: 'api_key',
      trainCase: 'Api-Key'
    ),
    (
      words: ['url', 'parser'],
      camelCase: 'urlParser',
      kebabCase: 'url-parser',
      pascalCase: 'UrlParser',
      screamingSnakeCase: 'URL_PARSER',
      screamingKebabCase: 'URL-PARSER',
      snakeCase: 'url_parser',
      trainCase: 'Url-Parser'
    ),
    (
      words: ['html', 'css', 'js'],
      camelCase: 'htmlCssJs',
      kebabCase: 'html-css-js',
      pascalCase: 'HtmlCssJs',
      screamingSnakeCase: 'HTML_CSS_JS',
      screamingKebabCase: 'HTML-CSS-JS',
      snakeCase: 'html_css_js',
      trainCase: 'Html-Css-Js'
    ),
    (
      words: ['pdf', 'document'],
      camelCase: 'pdfDocument',
      kebabCase: 'pdf-document',
      pascalCase: 'PdfDocument',
      screamingSnakeCase: 'PDF_DOCUMENT',
      screamingKebabCase: 'PDF-DOCUMENT',
      snakeCase: 'pdf_document',
      trainCase: 'Pdf-Document'
    ),
    (
      words: ['json', 'api'],
      camelCase: 'jsonApi',
      kebabCase: 'json-api',
      pascalCase: 'JsonApi',
      screamingSnakeCase: 'JSON_API',
      screamingKebabCase: 'JSON-API',
      snakeCase: 'json_api',
      trainCase: 'Json-Api'
    ),
    (
      words: ['sql', 'db'],
      camelCase: 'sqlDb',
      kebabCase: 'sql-db',
      pascalCase: 'SqlDb',
      screamingSnakeCase: 'SQL_DB',
      screamingKebabCase: 'SQL-DB',
      snakeCase: 'sql_db',
      trainCase: 'Sql-Db'
    ),
  ];

  final edgeCases = [
    (
      text: 'Items - 2a3 - Version 4b5',
      expectedWords: ['items', '2a3', 'version', '4b5'],
    ),
    (text: 'Items -- Draft', expectedWords: ['items', 'draft']),
    (
      text: 'Tag Name With 123 Numbers',
      expectedWords: ['tag', 'name', 'with', '123', 'numbers']
    ),
    (
      text: 'Controller_someMethod',
      expectedWords: ['controller', 'some', 'method']
    ),
    // Hash/pound symbol
    (
      text: 'item#123',
      expectedWords: ['item', '123'],
    ),
    (
      text: 'C#_Programming',
      expectedWords: ['c', 'programming'],
    ),
    // Dots
    (
      text: 'com.example.api',
      expectedWords: ['com', 'example', 'api'],
    ),
    (
      text: 'v2.0.1',
      expectedWords: ['v2', '0', '1'],
    ),
    // Forward slash
    (
      text: 'users/profile',
      expectedWords: ['users', 'profile'],
    ),
    (
      text: 'api/v1/users',
      expectedWords: ['api', 'v1', 'users'],
    ),
    // At symbol
    (
      text: 'user@domain',
      expectedWords: ['user', 'domain'],
    ),
    (
      text: '@deprecated_method',
      expectedWords: ['deprecated', 'method'],
    ),
    // Curly braces
    (
      text: '{userId}',
      expectedWords: ['user', 'id'],
    ),
    (
      text: 'template{param}',
      expectedWords: ['template', 'param'],
    ),
    // Parentheses
    (
      text: 'method()',
      expectedWords: ['method'],
    ),
    (
      text: 'calc(value)',
      expectedWords: ['calc', 'value'],
    ),
    // Square brackets
    (
      text: 'array[index]',
      expectedWords: ['array', 'index'],
    ),
    (
      text: 'items[0]',
      expectedWords: ['items', '0'],
    ),
    // Angle brackets
    (
      text: 'List<String>',
      expectedWords: ['list', 'string'],
    ),
    (
      text: '<T>generic',
      expectedWords: ['t', 'generic'],
    ),
    // Colon
    (
      text: 'namespace:method',
      expectedWords: ['namespace', 'method'],
    ),
    (
      text: 'http://example.com',
      expectedWords: ['http', 'example', 'com'],
    ),
    // Semicolon
    (
      text: 'part1;part2',
      expectedWords: ['part1', 'part2'],
    ),
    // Backtick
    (
      text: '`literal`',
      expectedWords: ['literal'],
    ),
    (
      text: 'template`string`',
      expectedWords: ['template', 'string'],
    ),
    // Tilde
    (
      text: '~deprecated',
      expectedWords: ['deprecated'],
    ),
    (
      text: 'version~1.0',
      expectedWords: ['version', '1', '0'],
    ),
    // Exclamation
    (
      text: '!important',
      expectedWords: ['important'],
    ),
    (
      text: 'not!equal',
      expectedWords: ['not', 'equal'],
    ),
    // Dollar sign
    (
      text: r'$variable',
      expectedWords: ['variable'],
    ),
    (
      text: r'price$USD',
      expectedWords: ['price', 'usd'],
    ),
    // Percent
    (
      text: '100%complete',
      expectedWords: ['100', 'complete'],
    ),
    (
      text: 'progress%',
      expectedWords: ['progress'],
    ),
    // Caret
    (
      text: '^version',
      expectedWords: ['version'],
    ),
    (
      text: 'base^exponent',
      expectedWords: ['base', 'exponent'],
    ),
    // Ampersand
    (
      text: 'fish&chips',
      expectedWords: ['fish', 'chips'],
    ),
    (
      text: '&reference',
      expectedWords: ['reference'],
    ),
    // Asterisk
    (
      text: '*pointer',
      expectedWords: ['pointer'],
    ),
    (
      text: 'wild*card',
      expectedWords: ['wild', 'card'],
    ),
    // Plus
    (
      text: 'C++',
      expectedWords: ['c'],
    ),
    (
      text: 'item+added',
      expectedWords: ['item', 'added'],
    ),
    // Equals
    (
      text: 'key=value',
      expectedWords: ['key', 'value'],
    ),
    (
      text: 'param==value',
      expectedWords: ['param', 'value'],
    ),
    // Pipe
    (
      text: 'option1|option2',
      expectedWords: ['option1', 'option2'],
    ),
    (
      text: 'pipe|separated|values',
      expectedWords: ['pipe', 'separated', 'values'],
    ),
    // Mixed symbols
    (
      text: 'user@company.com/profile',
      expectedWords: ['user', 'company', 'com', 'profile'],
    ),
    (
      text: 'api/v2.0/{userId}/profile',
      expectedWords: ['api', 'v2', '0', 'user', 'id', 'profile'],
    ),
    (
      text: r'$http_request->execute()',
      expectedWords: ['http', 'request', 'execute'],
    ),
    (
      text: '[GET]/api/users/{id}',
      expectedWords: ['get', 'api', 'users', 'id'],
    ),
    (
      text: '<UserProfile>_component',
      expectedWords: ['user', 'profile', 'component'],
    ),
    // Real-world API examples
    (
      text: 'X-RateLimit-Remaining',
      expectedWords: ['x', 'rate', 'limit', 'remaining'],
    ),
    (
      text: 'Content-Type: application/json',
      expectedWords: ['content', 'type', 'application', 'json'],
    ),
    (
      text: 'Bearer {token}',
      expectedWords: ['bearer', 'token'],
    ),
    (
      text: 'api.example.com/v1',
      expectedWords: ['api', 'example', 'com', 'v1'],
    ),
    // Empty after symbol stripping
    (
      text: '+++',
      expectedWords: <String>[],
    ),
    (
      text: '---',
      expectedWords: <String>[],
    ),
    (
      text: '***',
      expectedWords: <String>[],
    ),

    // Non-ASCII characters
    (
      text: '5иллегалчарактер',
      expectedWords: ['5иллегалчарактер'],
    ),
    (
      text: 'café_data',
      expectedWords: ['café', 'data'],
    ),
    (
      text: 'naïve_user',
      expectedWords: ['naïve', 'user'],
    ),
    (
      text: 'helloКир',
      expectedWords: ['helloкир'],
    ),
    (
      text: 'データベース_test',
      expectedWords: ['データベース', 'test'],
    ),
    (
      text: 'αβγ_values',
      expectedWords: ['αβγ', 'values'],
    ),
    (
      text: '测试_method',
      expectedWords: ['测试', 'method'],
    ),
    (
      text: 'émoji_😀_test',
      expectedWords: ['émoji', '😀', 'test'],
    ),
    (
      text: 'ñoño_field',
      expectedWords: ['ñoño', 'field'],
    ),
    (
      text: 'résumé',
      expectedWords: ['résumé'],
    ),
    (
      text: 'straße_name',
      expectedWords: ['straße', 'name'],
    ),
    (
      text: 'москва123',
      expectedWords: ['москва123'],
    ),
    (
      text: 'π_value',
      expectedWords: ['π', 'value'],
    ),
    (
      text: 'caféAPI',
      expectedWords: ['café', 'api'],
    ),
  ];

  group('NormalizedIdentifier', () {
    for (final testCase in wordsToText) {
      test(testCase.words.join(' '), () {
        final identifier = NormalizedIdentifier.fromWords(testCase.words);
        expect(identifier.camelCase, testCase.camelCase, reason: 'camelCase');
        expect(identifier.kebabCase, testCase.kebabCase, reason: 'kebabCase');
        expect(identifier.pascalCase, testCase.pascalCase,
            reason: 'pascalCase');
        expect(identifier.screamingSnakeCase, testCase.screamingSnakeCase,
            reason: 'screamingSnakeCase');
        expect(identifier.screamingKebabCase, testCase.screamingKebabCase,
            reason: 'screamingKebabCase');
        expect(identifier.snakeCase, testCase.snakeCase, reason: 'snakeCase');
        expect(identifier.trainCase, testCase.trainCase, reason: 'trainCase');
      });
    }

    group('parse', () {});
    for (final testCase in textToWord) {
      test(testCase.words.join(' '), () {
        final camelCase = NormalizedIdentifier.parse(testCase.camelCase);
        expect(camelCase.isPrivate, false);
        expect(camelCase.words, testCase.words);

        final pascalCase = NormalizedIdentifier.parse(testCase.pascalCase);
        expect(pascalCase.isPrivate, false);
        expect(pascalCase.words, testCase.words);

        final snakeCase = NormalizedIdentifier.parse(testCase.snakeCase);
        expect(snakeCase.isPrivate, false);
        expect(snakeCase.words, testCase.words);

        final screamingSnakeCase =
            NormalizedIdentifier.parse(testCase.screamingSnakeCase);
        expect(screamingSnakeCase.isPrivate, false);
        expect(screamingSnakeCase.words, testCase.words);

        final screamingKebabCase =
            NormalizedIdentifier.parse(testCase.screamingKebabCase);
        expect(screamingKebabCase.isPrivate, false);
        expect(screamingKebabCase.words, testCase.words);

        final trainCase = NormalizedIdentifier.parse(testCase.trainCase);
        expect(trainCase.isPrivate, false);
        expect(trainCase.words, testCase.words);

        final privateCamelCase =
            NormalizedIdentifier.parse('_${testCase.camelCase}');
        expect(privateCamelCase.isPrivate, true);
        expect(privateCamelCase.words, testCase.words);

        final privatePascalCase =
            NormalizedIdentifier.parse('_${testCase.pascalCase}');
        expect(privatePascalCase.isPrivate, true);
        expect(privatePascalCase.words, testCase.words);
      });
    }

    for (final edgeCase in edgeCases) {
      test(edgeCase.text, () {
        final identifier = NormalizedIdentifier.parse(edgeCase.text);
        expect(identifier.words, edgeCase.expectedWords);
      });
    }
  });
}
