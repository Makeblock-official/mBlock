/**
 * 多国语言管理
 */
const i18n = require('i18n');
const{MenuItem} = require('electron')
const events = require('events');
var _emitter = new events.EventEmitter();  
var _client,_lang,_app;
const _languages = [
			{name:"en",label:"English"},
			{name:"zh_CN",label:"简体中文"},
			{name:"zh_TW",label:"正體中文"},
			{name:"it_IT",label:"Italiano"},
			{name:"fr_FR",label:"Français"},
			{name:"es_ES",label:"Español"},
			{name:"ko",label:"한국어"},
			{name:"da",label:"Dansk"},
            {name:"ru_RU",label:"Русский"},
            {name:"ja_HIRA",label:"にほんご"},
            {name:"ja",label:"日本語"},
            {name:"nl_NL",label:"Nederlands"},
            {name:"de_DE",label:"Deutsch"},
            {name:"hebrew",label:"Hebrew"},
            {name:"et_EE",label:"Eesti"},
            {name:"latin5",label:"Türkçe"},
            {name:"cz_CZ",label:"Čeština"},
            {name:"IA5",label:"Svenska"},
            {name:"pt_BR",label:"Português"},
            {name:"pl_PL",label:"Polski"},
            {name:"hr_HRV",label:"Hrvatski"}															
			];
function Translator(app){
    _app = app;
    _client = _app.getClient();
    _lang = _app.getLocale().split("-").join("_");
    var self = this;
    var locales = ['en'];
    for(var i in _languages){
        locales.push(_languages[i].name);
    }
    i18n.configure({
        locales:locales,
        directory: __dirname + '/../i18n/locales'
    });
    this.setLanguage = function (lang){
        _lang = lang;
        i18n.setLocale(lang);
        var dict = i18n.getCatalog(_lang);
        _client.send("setLanguage",{lang:_lang,dict:JSON.stringify(dict)})
    }
    this.getLanguage = function (){
        return _lang;
    }
    this.setClient = function(c){
        _client = c;
    }
    this.getMenuItems = function(){
        var items = [];
        for(var i=_languages.length-1;i>=0;i--){
            var item = new MenuItem({
                name:_languages[i].name,
                label:_languages[i].label,
                checked:_languages[i].name==_lang,
                type:'checkbox',
                click:function(item,focusedWindow){
                    self.setLanguage(item.name);
                    _app.getMenu().update();
                }
            })
            items.push(item);
        }
        return items;
    }
    this.setLanguage("zh_CN");
    this.map = function(str){
        return i18n.__(str);
    }
    this.on = function(event,listener){
        _emitter.on(event,listener);
    }
}
module.exports = Translator;