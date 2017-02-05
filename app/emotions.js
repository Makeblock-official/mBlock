/**
 * Created by kun on 2/5/17.
 * 表情面板
 */
const fs = require("fs");
const path = require('path');

var dir = path.join(__root_path, "/src/assets/emotions");
var _app, _this;
var Emotions = function(app) {
    _this = this;
    _app = app;

    this.path = function(filename) {
        return path.resolve(dir, filename);
    }

    this.save = function (filename, data) {
        var file = _this.path(filename);
        fs.writeFile(file, data, function (err) {
            if (err) {
                _app.alert()
                return false;
            }
            console.log(file + ' is saved!');
        });
    }

    this.del = function (filename) {
        var file = _this.path(filename);
        fs.unlink(file, function (err) {
            if (err) {
                return false;
            }
            console.log(file + ' is delete!');
        });
    }

    this.read = function (filename) {
        var file = _this.path(filename);
        fs.readFile(file, 'utf8', function (err, data) {
            if (err) {
                console.log(file + ' read fail!');
                return null;
            }
            return data;
        });
    }

    this.list = function () {
        fs.readdir(dir,function(err,files){
            if(err) {
                console.log(err);
                return [];
            }
            return files;
        });
    }
}

module.exports = Emotions;