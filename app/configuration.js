/**
 * Created by kun on 2/13/17.
 * 保存用户配置
 */
const fs = require("fs");
const path = require('path');

var _this, _dir, _file;
var Configuration = function () {
    _this = this;
    _dir = path.join(__root_path, "/../mblock-setting");
    _file = path.resolve(_dir, 'settings.json');

    this.read = function () {
        if (!fs.existsSync(_file)) {
            return {};
        }
        var res = JSON.parse(fs.readFileSync(_file));
        if (!res) return {};
        return res;
    }

    this.get = function (name) {
        var result = _this.read();
        return result[name];
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

    this.set = function (name, value) {
        var result = _this.read();
        result[name] = value;
        if (!_this.mkdirsSync(_dir)) {
            return;
        }
        fs.writeFile(_file, JSON.stringify(result), function (err) {
            if (err)    return;
            console.log(_file + ' is saved!');
        });
    }
}
module.exports = Configuration;