/**
 * 字体大小设置
 */

const{MenuItem} = require('electron') ;
const Configuration = require('./configuration.js');

var _client,_size,_app,_configuration;
const _fontSize = [
			{label:"8"},
			{label:"10"},
			{label:"11"},
			{label:"12"},
			{label:"14"},
			{label:"16"},
			{label:"18"},
			{label:"20"},
            {label:"24"}
			];
function FontSize(app){
    _app = app;
    _client = _app.getClient();
    _configuration = new Configuration();
    var _translator = _app.getTranslator();
    var self = this;
    this.setFontSize = function (size){
        _size = size;
        _client.send("setFontSize",{size:_size});
    }
    this.getFontSize = function (){
        return _size;
    }
    this.getMenuItem = function(){
        var m =  new MenuItem({
            name:'set font size',
            label: _translator.map('set font size'),
            submenu:[]
        });
        for(var i=_fontSize.length-1;i>=0;i--){
            var item = new MenuItem({
                label:_fontSize[i].label,
                checked:_fontSize[i].label ==_size,
                type:'checkbox',
                click:function(item,focusedWindow){
                    self.setFontSize(item.label);
                    _configuration.set('setFontSize', item.label);
                    _app.getMenu().update();
                }
            })
            m.submenu.insert(0,item);
        }
        return m;
    }

    this.setDefaultSize = function () {
        var setSize = _configuration.get('setFontSize');
        if (!setSize) {
            this.setFontSize("12");
        } else {
            this.setFontSize(setSize);
        }
    }

    this.setDefaultSize();
    // this.setFontSize("12");

}
module.exports = FontSize;