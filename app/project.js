/**
 * 项目文件管理：创建、保存、加载
 */
const {dialog,BrowserWindow} = require('electron')
const fs = require("fs");
const events = require('events');
var _emitter = new events.EventEmitter();  
var _saveAs=false;
var _currentProjectPath = "";
var _client,_app,_title;
function Project(app) {
    var self = this;
    _app = app;
    _client = _app.getClient();
    /**
     * 打开保存窗口，将项目文件写入到本地文件系统
     */
    this.saveProject = function(title,data){
        if(_saveAs||_currentProjectPath==""){
		    var mainWindow = BrowserWindow.getFocusedWindow();
            if(title==" .sb2"){
                title = "project";
            }
            if(_currentProjectPath==""){
                _currentProjectPath = "."
            }
            dialog.showSaveDialog(mainWindow,{defaultPath:fs.realpathSync(_currentProjectPath+'/../')+"/"+title+".sb2"},function(path){
                if(path){
                    _currentProjectPath = path;
                    var temp = path.split("/");
                    _title = temp[temp.length-1].split(".sb2")[0];
                    fs.writeFileSync(path, new Buffer(data, 'base64'));
                }
            })
        }else{
            fs.writeFileSync(_currentProjectPath, new Buffer(data, 'base64'));
        }
    }
    /**
     * 从本地文件系统加载项目文件，并上传到express服务器，生成url链接发送给flash加载
     */
    this.openProject = function(path){
        _currentProjectPath = path
        var data = fs.readFileSync(path);
        var tmp = path.split(".");
        var filename = "/tmp/project."+tmp[tmp.length-1];
        fs.writeFileSync("./web"+filename, data);
        if(_client){
            _client.send("openProject",{url:filename})
        }
    }
    /**
     * 向flash发送创建新项目的请求，flash收到请求会清空当前舞台所有内容。
     */
    this.newProject = function(){
        _currentProjectPath = "";
        if(_client){
            _client.send("newProject",{title:"new-project"})
        }
    }
    /**
     * 向flash发送项目名称（名称由保存的文件名决定）
     */
    this.setProjectTitle = function(){
        if(_client){
            _client.send("setProjectTitle",{title:_title})
        }
    }
    /**
     * 向flash发送保存请求，等待flash返回项目文件（base64）和项目名称
     */
    this.saveAs = function(b){
        _saveAs = b;
        if(_client){
            _client.send("saveProject",{})
        }
    }
    this.on = function(event,listener){
        _emitter.on(event,listener);
    }
}
module.exports = Project;