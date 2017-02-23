function loadScript(name, url, callback){
    removeScript(name);
    var script = document.createElement("script")
    script.id = name;
    script.type = "text/javascript";
    script.onload = function(){
        callback();
    };
    script.src = url;
    document.body.appendChild(script);
}
function removeScript(name){
    if(document.getElementById(name)){
        document.getElementById(name).remove();
    }
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
    return self.castArray2DataView(bytes).getInt16(0, true);
}

function parseInt32(bytes){
    if(bytes.length < 4)
        return 0;
    return self.castArray2DataView(bytes).getInt32(0, true);
}

function parseFloat32(bytes){
    if(bytes.length < 4)
        return 0;
    return self.castArray2DataView(bytes).getFloat32(0, true);
}

function parseDouble(bytes){
    return self.parseFloat32(bytes);
}

function short2array(val){
    var dataView = new DataView(new ArrayBuffer(2));
    dataView.setInt16(0, val, true);
    return self.castDataView2Array(dataView);
}

function int2array(val){
    var dataView = new DataView(new ArrayBuffer(4));
    dataView.setInt32(0, val, true);
    return self.castDataView2Array(dataView);
}

function float2array(val){
    var dataView = new DataView(new ArrayBuffer(4));
    dataView.setFloat32(0, val, true);
    return self.castDataView2Array(dataView);
}
function readFloat(arr,position){
    var f= [arr[position],arr[position+1],arr[position+2],arr[position+3]];
    return self.parseFloat32(f);
}
function readInt(arr,position,count){
    var result = 0;
    for(var i=0; i<count; ++i){
        result |= arr[position+i] << (i << 3);
    }
    return result;
}
function readDouble(arr,position){
    return self.readFloat(arr,position);
}
function readString(arr,position,len){
    var value = "";
    for(var ii=0;ii<len;ii++){
        value += String.fromCharCode(_rxBuf[ii+position]);
    }
    return value;
}
function appendBuffer( buffer1, buffer2 ) {
    return buffer1.concat( buffer2 );
}
const encoder = new TextEncoder('utf-8');
const decoder = new TextDecoder('utf-8');

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

function interruptThread(msg) {
    flashCore.interruptThread(msg);
}