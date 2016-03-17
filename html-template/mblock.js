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

function parseFloat(bytes){
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

function string2array(val){
	var encoder = new TextEncoder('utf-8');
    return encoder.encode(buf).buffer;
}

function array2string(bytes){
	var buffer = new ArrayBuffer(bytes.length);
	for(var i=0; i<bytes.length; ++i)
		buffer[i] = bytes[i];
	var dataView = new DataView(buffer);
    var decoder = new TextDecoder('utf-8');
    return decoder.decode(dataView);
}

var ScratchExtensions = {};
ScratchExtensions.buffer = new ArrayBuffer(8);
var globalExt = null;

var device = {};
device.send = function(bytes){
	console.log("send", bytes);
	var flash = swfobject.getObjectById("MBlock");
	flash.responseValue(100);
}
device.open = function(){
	console.log("device open");
}

function callJs(extName, method, args){
	console.log(extName, method, args);
	var callback = globalExt[method];
	if(args.length < callback.length){
		args.unshift(0);
	}
	callback.apply(globalExt, args);
}

ScratchExtensions.register = function(name,desc,ext,param){
	console.log("ext reg", name);
	globalExt = ext;
	ext._deviceConnected(device);
}
