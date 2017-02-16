/**
 * Scratch JS
 */
module.paths = __module_paths;

const {ipcRenderer} = require('electron');
const FlashUtils = require('utils');
const _utils = new FlashUtils();
var _app;
function Extension(app){
    _app = app;
    this.device = {};
    this.globalExt = {};
    // this.onReceived=null
    this.connected = false;

    var self = this;
    this.callJs = function(extName, method, args){
        if(!self.globalExt[extName]){
            return;
        }console.log('call js');
		console.log(extName);  // extName     : mBot
		console.log(method);   // 类似：method : runMotor
		console.log(args);     // 类似：args   : M1,0
        var handler = self.globalExt[extName][method];

        if(args.length < handler.length){
            args.unshift(0);
        }

        handler.apply(self.globalExt[extName], args);
    }
    this.register = function(name,desc,ext,param){
        self.globalExt[name] = ext;
        self.globalExt[name]._deviceConnected(self.device,_utils);
    }
    this.unregister = function(name){
        self.globalExt[name]._deviceRemoved(self.device);
        self.globalExt[name] = null;
    }
    this.onReceived = function(data){
        for(var i in self.globalExt){
            if(self.globalExt[i].processData){
                self.globalExt[i].processData(data);
            }
        }
    }
    this.device.send = function(data){
        ipcRenderer.send("package",{data:data});
    }
    this.device.open = function(option,success){
        if(success){
            success(this);
        }
    }
    this.device.responseValue = function(index, value){
        _app.responseValue(index, value);
    }
    this.device.set_receive_handler = function(name,callback){
        // self.onReceived = function(data){
        //     console.log("received:"+data)
        //     callback(data);
        // }
    }
    this.resetAll = function(){

    }
    window.ScratchExtensions = this;
}
module.exports = Extension;
