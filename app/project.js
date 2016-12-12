const {dialog} = require('electron')
const fs = require("fs");
const events = require('events');
var _emitter = new events.EventEmitter();  
var _saveAs=false;
var _currentProjectPath = "";
var _client,_app;
function Project(app) {
    _app = app;
    _client = _app.getClient();
    this.saveProject = function(title,data){
        if(_saveAs||_currentProjectPath==""){
            dialog.showSaveDialog({title:title},function(path){
                if(path){
                    _currentProjectPath = path;
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
    this.saveAs = function(b){
        _saveAs = b;
        _client.send("saveProject",{})
    }
    this.on = function(event,listener){
        _emitter.on(event,listener);
    }
}
module.exports = Project;