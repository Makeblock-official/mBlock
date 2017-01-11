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

function setProjectRobotName(name){
	console.log("set project name", name);
}

function readyToRun(){
	return true;
}

var ScratchExtensions = {};
var globalExt = null;
var dataCallback;

var device = {};
device.send = function(bytes){
	socket.send(new Uint8Array(bytes).buffer);
};
device.open = function(info, callback){
	console.log("device open");
	callback(device);
};
device.set_receive_handler = function(name, callback){
	console.log("set_receive_handler", name);
	dataCallback = callback;
};

function callJs(extName, method, args){console.log('-----------this --------------');
	console.log(extName, method, args);
	var handler = globalExt[method];
	if(args.length < handler.length){
		args.unshift(0);
	}
	handler.apply(globalExt, args);
}

ScratchExtensions.register = function(name,desc,ext,param){
	console.log("ext reg", name);
	globalExt = ext;
	ext._deviceConnected(device);
}

var socket = new WebSocket('ws://127.0.0.1:8081/chat');
socket.onopen = function(){
	console.log("web socket open!");
};
socket.onclose = function(event){
	console.log('web socket closed');
};
socket.onmessage = function(evt){
	var fileReader = new FileReader();
	fileReader.onload = function(){
		var bytes = castDataView2Array(new DataView(fileReader.result));
		dataCallback(bytes);
	};
	fileReader.readAsArrayBuffer(evt.data);
};
