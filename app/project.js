/**
 * 项目文件管理：创建、保存、加载
 */
const {dialog, BrowserWindow} = require('electron')
const fs = require("fs");
const pathModule = require('path');
const events = require('events');
var _emitter = new events.EventEmitter();
var _saveAs = false;
var _currentProjectPath = "";
var _client, _app, _title;
var _saveAndNew = false;
var newProject = true;
var _translator;
function Project(app) {
    var self = this;
    _app = app;
    _client = _app.getClient();
    _translator = app.getTranslator();
    /**
     * 打开保存窗口，将项目文件写入到本地文件系统
     */
    this.saveProject = function (title, data) {

        // ret = dialog.showMessageBox(BrowserWindow.getFocusedWindow(),{
        //     type:'question',
        //     title:'我是标题',
        //     message:'我是内容',
        //     buttons:['确定','取消'],
        //     noLink:false
        // });
        // console.log("return "+ret);

        if (_saveAs || _currentProjectPath == "" || _currentProjectPath == ".") {
            var mainWindow = BrowserWindow.getFocusedWindow();
            if (title == " .sb2") {
                title = "project";
            }
            if (_currentProjectPath == "") {
                _currentProjectPath = "."
            }
            if (title.lastIndexOf('.sb2') != title.length - 4) {
                title += ".sb2";
            }
            dialog.showSaveDialog(mainWindow, {defaultPath: fs.realpathSync(_currentProjectPath + '/../') + "/" + title}, function (path) {
                if (path) {
                    if (path.lastIndexOf('.sb2') != path.length - 4) {
                        path += ".sb2";
                    }
                    _currentProjectPath = path;
                    var temp = path.replace(/\\/g, "/").split("/");
                    _title = temp[temp.length - 1].split(".sb2")[0];
                    fs.writeFileSync(path, new Buffer(data, 'base64'));
                    self.setProjectTitle();                    //设置另存后标题
                    if (_saveAndNew) {
                        self.doNewProject();
                    }
                    _client.send("setSaveStatus", {isSaved:true}); //通知前端UI保存成功
                }
            })
        } else {
            fs.writeFileSync(_currentProjectPath, new Buffer(data, 'base64'));
            if (_saveAndNew) {
                self.doNewProject();
            }
            _client.send("setSaveStatus", {isSaved:true}); //通知前端UI保存成功
        }
    }
    /**
     * 从本地文件系统加载项目文件，并上传到express服务器，生成url链接发送给flash加载
     */
    this.openProject = function (path) {
        _currentProjectPath = path
        var data = fs.readFileSync(path);
        var tmp = path.split(".");
        var tmpPath =path.replace(/\\/g,"/").split("/");
        var tmpTitle = tmpPath[tmpPath.length-1];
        var filename = "project."+tmp[tmp.length-1];
		var filePath = pathModule.resolve(__root_path, 'web', 'tmp', filename);
        fs.writeFileSync(filePath, data);
        if(newProject) {
            if(_client){
                _client.send("openProject",{url:__webviewRootURL+'/tmp/'+filename, title:tmpTitle});
            }
            newProject=false;
        } else {
            var ret = dialog.showMessageBox(BrowserWindow.getFocusedWindow(), {
                type: 'question',
                title: '',
                message: _translator.map('Replace contents of the current project?'),
                buttons: [_translator.map('OK'), _translator.map('Cancel')],
                noLink: true
            });
            if(_client &&ret==0){
                _client.send("openProject",{url:__webviewRootURL+'/tmp/'+filename, title:tmpTitle});
            }
        }
    }
    /**
     * 向flash发送创建新项目的请求，flash收到请求会清空当前舞台所有内容。
     */
    this.newProject = function () {

        var ret = dialog.showMessageBox(BrowserWindow.getFocusedWindow(), {
            type: 'question',
            title: '',
            message: _translator.map('Save project?'),
            buttons: [_translator.map('Save'), _translator.map("Don't save"), _translator.map('Cancel')],
            noLink: true
        });

        if (ret == 0) {
            if (_client) {
                _saveAndNew = true;
                _client.send("saveProject", {}); //这里是异步模式，保存后才能执行新建
            }
        }

        if (ret == 1) {
            self.doNewProject();
        }

    }
    this.doNewProject = function () {
        _currentProjectPath = "";
        if (_client) {
            _client.send("newProject", {title: "new-project"})
        }
        _saveAndNew = false;         //清除 保存后新建   标识
    }

    /**
     * 获得项目标题
     */
    this.getProjectTitle = function () {
        return _title;
    }
    /**
     * 向flash发送项目名称（名称由保存的文件名决定）
     */
    this.setProjectTitle = function () {
        if (_client) {
            _client.send("setProjectTitle", {title: _title});
        }
    }
    /**
     * 向flash发送保存请求，等待flash返回项目文件（base64）和项目名称
     */
    this.saveAs = function (b) {
        _saveAs = b;
        if (_client) {
            _client.send("saveProject", {})
        }
    }
    this.on = function (event, listener) {
        _emitter.on(event, listener);
    }
}
module.exports = Project;