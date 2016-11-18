const {ipcRenderer} = require('electron')
var flashCore = document.getElementById("mblock");
var ScratchExtensions = {};
var globalExt = {},onReceived=null,connected = false;
var device = {};
ipcRenderer.on('webview', (sender,obj) => {    
    if(obj.method=="openProject"){
        flashCore.openProject(obj.url);
    }else if(obj.method=="newProject"){
        console.log("newProject")
        flashCore.newProject(obj.title);
    }else if(obj.method=="saveProject"){
        console.log("saveProject")
        flashCore.saveProject();
    }else if(obj.method=="command"){
        console.log("command");
        //obj.buffer
        if(onReceived){
            onReceived(obj.buffer);
        }
    }else if(obj.method=="connected"){
        connected = obj.connected;
    }else if(obj.method=="changeToBoard"){
        changeToBoard(obj.board);
    }
})
function callJs(extName, method, args){
	var handler = globalExt[extName][method];
	if(args.length < handler.length){
		args.unshift(0);
	}
	handler.apply(globalExt[extName], args);
}
ScratchExtensions.register = function(name,desc,ext,param){
	globalExt[name] = ext;
    globalExt[name]._deviceConnected(device);
}
ScratchExtensions.unregister = function(name){
    globalExt[name]._deviceRemoved(device);
    globalExt[name] = null;
}
window.ScratchExtensions = ScratchExtensions;

function setProjectRobotName(){

}
function readyToRun(){
    return true;
}
function boardConnected(){
    return connected;
}
function sendMsg(msg){
    console.log(msg)
}
function readyForFlash(){
    window.responseValue = flashCore.responseValue;
    ipcRenderer.sendToHost("flashReady");
}
function changeToBoard(name){
    name = name.toLowerCase();
    if(name.indexOf("auriga")>-1){
        loadScript("Auriga","flash-core/ext/libraries/Auriga/js/Auriga.js",function(){
            flashCore.setRobotName("mbot ranger");
        });
    }else if(name.indexOf("mbot")>-1){
        loadScript("mBot","flash-core/ext/libraries/mbot/js/mbot.js",function(){
            flashCore.setRobotName("mbot");
        });
    }
}
function setFullscreen(status){
    ipcRenderer.sendToHost("fullscreen",status);
}
function saveProject(data){
    var date = new Date();
    ipcRenderer.sendToHost("save",{title:date.getFullYear()+"-"+date.getMonth()+"-"+date.getDate()+".sb2",data:data});
}
function openSuccess(){
    console.log("openSuccess")
}
device.send = function(data){
    console.log(data);
    ipcRenderer.sendToHost("command",{buffer:data});
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

function isArray(target){
	return Object.prototype.toString.call(target) == "[object Array]";
}

function castDataView2Array(dataView){
	var n = dataView.byteLength;
	var result = new Array(n);
	for(var i=0; i<n; ++i)
		result[i] = dataView.getUint8(i);
	return result;
}

function castArray2DataView(bytes){
	var n = bytes.length;
	var dataView = new DataView(new ArrayBuffer(n));
	for(var i=0; i<n; ++i)
		dataView.setUint8(i, bytes[i]);
	return dataView;
}

function parseShort(bytes){
	if(bytes.length < 2)
		return 0;
	return castArray2DataView(bytes).getInt16(0, true);
}

function parseInt32(bytes){
	if(bytes.length < 4)
		return 0;
	return castArray2DataView(bytes).getInt32(0, true);
}

function parseFloat32(bytes){
	if(bytes.length < 4)
		return 0;
	return castArray2DataView(bytes).getFloat32(0, true);
}

function parseDouble(bytes){
	return parseFloat(bytes);
}

function short2array(val){
	var dataView = new DataView(new ArrayBuffer(2));
	dataView.setInt16(0, val, true);
	return castDataView2Array(dataView);
}

function int2array(val){
	var dataView = new DataView(new ArrayBuffer(4));
	dataView.setInt32(0, val, true);
	return castDataView2Array(dataView);
}

function float2array(val){
	var dataView = new DataView(new ArrayBuffer(4));
	dataView.setFloat32(0, val, true);
	return castDataView2Array(dataView);
}

var encoder = new TextEncoder('utf-8');
var decoder = new TextDecoder('utf-8');

function string2array(val){
	var buffer = encoder.encode(val);//uint8 array
	var n = buffer.length;
	var result = new Array(n);
	for(var i=0; i<n; ++i)
		result[i] = buffer[i];
    return result;
}

function array2string(bytes){
	var dataView = castArray2DataView(bytes);
    return decoder.decode(dataView);
}

function callFlash(method, args){
	var flash = swfobject.getObjectById("MBlock");
	return flash[method].apply(flash, args);
}

function responseValue(index, value){
	var flash = swfobject.getObjectById("MBlock");
	if(arguments.length > 0){
		flash.responseValue(index, value);
	}else{
		flash.responseValue();
	}
}