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
    this.newProject = function(){
        _currentProjectPath = "";
        if(_client){
            _client.send("newProject",{title:"new-project"})
        }
    }
    this.setProjectTitle = function(){
        if(_client){
            _client.send("setProjectTitle",{title:_title})
        }
    }
    this.saveAs = function(b){
        _saveAs = b;
        _client.send("saveProject",{})
    }
    this.on = function(event,listener){
        _emitter.on(event,listener);
    }
}
module.exports = Project;