/**
 * Created by kun on 2/5/17.
 * 表情面板
 */
const fs = require("fs");
const path = require('path');

var _dir_preset, _app, _this, _translator, _client, _dir_custom;
var Emotions = function(app) {
    _this = this;
    _app = app;
    _dir_preset = path.join(__root_path, "/web/flash-core/assets/emotions");
    _dir_custom = path.join(__root_path, "/../mblock-emotions");
    _translator = app.getTranslator();
    _client = app.getClient();

    this.pathdir = function(label) {
        return ('preset' === label) ? _dir_preset : _dir_custom;
    }

    this.pathfile = function (filename, label) {
        var dir = _this.pathdir(label);
        return path.resolve(dir, filename);
    }

    this.mkdirsSync = function(dirpath) {
        if (!fs.existsSync(dirpath)) {
            var pathtmp;
            dirpath.split(path.sep).forEach(function(dirname) {
                if (pathtmp) {
                    pathtmp = path.join(pathtmp, dirname);
                } else {
                    pathtmp = dirname;
                }
                if ('' === pathtmp) {
                    pathtmp = '/';
                    return;
                }

                if (!fs.existsSync(pathtmp)) {
                    if (!fs.mkdirSync(pathtmp)) {
                        return false;
                    }
                }
            });
        }
        return true;
    }

    this.save = function (filename, data) {
        var file = _this.pathfile(filename);
        if (!_this.mkdirsSync(_this.pathdir())) {
            _app.alert(_translator.map('Directory could not be created'));
            return;
        }
        fs.writeFile(file, data, function (err) {
            if (err) {
                _app.alert(_translator.map('You do not have sufficient rights to save properties'));
                return;
            }
            console.log(file + ' is saved!');
        });
    }

    this.del = function (filename) {
        var file = _this.pathfile(filename);
        fs.unlink(file, function (err) {
            if (err) {
                _app.alert(_translator.map("It doesn't exist"));
                return;
            }
            console.log(file + ' is delete!');
        });
    }

    /**
     * 获取表情面板中表情文件的内容
     * @param filename
     * @param label 区别预设和自定义
     */
    this.read = function (filename, label) {
        var file = _this.pathfile(filename, label);
        fs.readFile(file, 'utf8', function (err, data) {
            if (err) {
                console.log(file + ' read fail!');
                return;
            }
            _client.send('responseEmotions', {code:'single', data: data, fileName: filename});
        });
    }

    /**
     * 获取表情面板文件夹中的表情文件
     * @param label 区别预设和自定义
     */
    this.list = function (label) {
        var dir = _this.pathdir(label);
        fs.readdir(dir,function(err,files){
            if(err) {
                console.log(err);
                return;
            }
            _client.send('responseEmotions', {code:'more', data: files});
        });
    }
}

module.exports = Emotions;