/**
 * 多国语言管理
 */
module.paths = __module_paths;
const i18n = require('i18n'); 
var _lang,_app;

function Translator(app){
    _app = app;

    var localePath;
    if(__asar_mode) {
        localePath = __dirname + '/../../../app.asar/i18n/locales';
    }
    else {
        localePath = __dirname + '/../../../i18n/locales';
    }

    i18n.configure({
        defaultLocale: 'en',
        directory: localePath
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