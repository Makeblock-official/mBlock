const {ipcRenderer} = require('electron');
var _flash;
function Application(flash){
    _flash = flash;
    var self = this;
    self.connected = false;
    ipcRenderer.on('openProject', (sender,obj) => {  
        _flash.openProject(obj.url);
    });  
    ipcRenderer.on('newProject', (sender,obj) => {  
        _flash.newProject(obj.title);
    });   
    ipcRenderer.on('saveProject', (sender,obj) => {  
        _flash.saveProject();
    });    
    ipcRenderer.on('setLanguage', (sender,obj) => {  
        _flash.setLanguage(obj.lang,obj.dict);
    });  
    ipcRenderer.on('changeStageMode',(sender,obj) =>{
        _flash.changeStageMode(obj.name);
    })
    ipcRenderer.on('command', (sender,obj) => {  
        if(self.onReceived){
            self.onReceived(obj.buffer);
        }
    });  
    ipcRenderer.on('connected', (sender,obj) => {  
        self.connected = obj.connected;
    });  
    ipcRenderer.on('changeToBoard', (sender,obj) => {  
        self.changeToBoard(obj.board);
    }); 

    this.readyForFlash = function(){
        console.log("readyForFlash");
        // window.responseValue = _flash.responseValue;
        ipcRenderer.send("flashReady");
    }
    this.callFlash = function(method, args){
        return _flash[method].apply(flash, args);
    }
    
    this.callFromFlash = function(method,params){
        console.log(method+":"+params);
        ipcRenderer.send(method,params);
    }
    this.responseValue = function(index, value){
        if(arguments.length > 0){
            _flash.responseValue(index, value);
        }else{
            _flash.responseValue();
        }
    }
    this.setProjectRobotName = function(){

    }
    this.readyToRun = function(){
        return true;
    }
    this.boardConnected = function(){
        return self.connected;
    }
    this.sendMsg = function(msg){
        console.log("sendMsg:"+msg)
    }
    this.changeToBoard=function(name){
        name = name.toLowerCase();
        if(name.indexOf("auriga")>-1){
            window.loadScript("Auriga","flash-core/ext/libraries/Auriga/js/Auriga.js",function(){
                _flash.setRobotName("mbot ranger");
            });
        }else if(name.indexOf("mbot")>-1){
            window.loadScript("mBot","flash-core/ext/libraries/mbot/js/mbot.js",function(){
                _flash.setRobotName("mbot");
            });
        }
    }
}
module.exports = Application;