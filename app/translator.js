const i18n = require('i18n');
const{MenuItem} = require('electron')
const events = require('events');
var _emitter = new events.EventEmitter();  
var _client,_lang,_app,_this;
const _languages = [
			{name:"en",label:"English"},
			{name:"zh-CN",label:"简体中文"},
			{name:"zh-TW",label:"繁体中文"}
			];
function Translator(app){
    _app = app;
    _client = _app.getClient();
    _lang = _app.getLocale();
    _this = this;
    i18n.configure({
        locales:['en', 'zh-CN', 'zh-TW'],
        directory: __dirname + '/../locales'
    });
    this.setLanguage = function (lang){
        _lang = lang;
        i18n.setLocale(lang);
        _client.send("setLanguage",{lang:_lang,dict:i18n.getCatalog(_lang)})
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
                    _this.setLanguage(item.name);
                    _app.updateMenu();
                }
            })
            items.push(item);
        }
        return items;
    }
    this.map = function(str){
        return i18n.__(str);
    }
    this.on = function(event,listener){
        _emitter.on(event,listener);
    }
}
module.exports = Translator;