/**
 * Created by kun on 2/5/17.
 * 表情面板
 */
const fs = require("fs");
const path = require('path');

var _dir, _app, _this, _translator, _client;
var Emotions = function(app) {
    _this = this;
    _app = app;
    _dir = path.join(__root_path, "/src/assets/emotions");
    _translator = app.getTranslator();
    _client = app.getClient();

    this.path = function(filename) {
        return path.resolve(_dir, filename);
    }

    this.save = function (filename, data) {
        var file = _this.path(filename);
        fs.writeFile(file, data, function (err) {
            if (err) {
                _app.alert(_translator.map('You do not have sufficient rights to save properties'));
                return;
            }
            console.log(file + ' is saved!');
        });
    }

    this.del = function (filename) {
        var file = _this.path(filename);
        fs.unlink(file, function (err) {
            if (err) {
                _app.alert(_translator.map('It doesn\'t exist'));
                return;
            }
            console.log(file + ' is delete!');
        });
    }

    this.read = function (filename) {
        var file = _this.path(filename);
        fs.readFile(file, 'utf8', function (err, data) {
            if (err) {
                console.log(file + ' read fail!');
                return;
            }
            _client.send('responseEmotions', {code:'single', data: data});
        });
    }

    this.list = function () {
        fs.readdir(_dir,function(err,files){
            if(err) {
                console.log(err);
                return;
            }
            _client.send('responseEmotions', {code:'more', data: files});
        });
    }
}

module.exports = Emotions;