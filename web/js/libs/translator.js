/**
 * 多国语言管理
 */
const i18n = require('i18n');
var _lang,_app;

function Translator(app){
    _app = app;

    i18n.configure({
        defaultLocale: 'en',
        directory: __dirname + '/../../../i18n/locales'
    });

    this.setLanguage = function (lang){
        _lang = lang;
        i18n.setLocale(lang);
    };

    this.map = function(str){
        return i18n.__(str);
    }

}
module.exports = Translator;