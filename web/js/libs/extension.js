var device = {};
var globalExt = {},onReceived=null,connected = false;
var _app;
function Extension(app){
    _app = app;
    this.callJs = function(extName, method, args){
        if(!globalExt[extName]){
            return;
        }
        var handler = globalExt[extName][method];

        if(args.length < handler.length){
            args.unshift(0);
        }
        handler.apply(globalExt[extName], args);
    }
    this.register = function(name,desc,ext,param){
        globalExt[name] = ext;
        globalExt[name]._deviceConnected(device);
    }
    this.unregister = function(name){
        globalExt[name]._deviceRemoved(device);
        globalExt[name] = null;
    }
    device.send = function(data){
        ipcRenderer.send("command",{buffer:data});
    }
    device.open = function(option,success){
        if(success){
            success(this);
        }
    }
    device.set_receive_handler = function(name,callback){
        onReceived = function(data){
            console.log("received:"+data)
            callback(data);
        }
    }
    this.resetAll = function(){

    }
    window.ScratchExtensions = this;
}
module.exports = Extension;
