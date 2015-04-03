// serial.js

(function(ext) {
    var device = null;
    var _rxBuf = [];

	var values = {};
	var indexs = [];
	var lines = [""];
	var nextID = 0;
	var startTimer = 0;
	var versionIndex = 0xFA;
	var isReceived = false;
	var lastLine = "";
    ext.resetAll = function(){};
	
	ext.writeLine = function(line) {
		line+="\r\n";
		device.send(string2array(line));
    };
    ext.writeCommand = function(key,value) {
        device.send(string2array(key+"="+value+"\r\n"));
    };
	ext.clearBuffer = function(){
		lines = [""];
	};
	ext.whenReceived = function(nextID){
		var temp = isReceived;
		isReceived = false;
		responseValue(nextID,temp);
	};
	ext.isAvailable = function(nextID) {
		responseValue(nextID,lines.length>0&&lines[0]!="");
    };
	ext.readLine = function(nextID){
		/*lines.shift();
		if(lines.length>0){
			if(lines[0]!=""){
				if(lines.length>1)
				return lines[1];
			}
		}*/
		responseValue(nextID,lastLine);
	}
	ext.readCommand = function(nextID,key){
		var v = lastLine;
		var idx = v.indexOf(key+"=");
		if(idx>-1){
			responseValue(nextID,v.substring(idx+key.length+1,v.length));
		}
		responseValue(nextID, "");
	};
	
    var inputArray = [];
	var _isParseStart = false;
	var _isParseStartIndex = 0;
    function processData(bytes) {
		var len = bytes.length;	
		isReceived = true;
		for(var index=0;index<bytes.length;index++){
			if(bytes[index]==0xD){
				lastLine = lines[0];
				lines[0] = "";
			}else{
				if(bytes[index]!=0xA){
					var c = String.fromCharCode(bytes[index]);
					lines[0]+=c;
				}
			}
		}
		if(lines.length>0){
			if(lines[0].length>254){
				lines[0] = "";
			}
		}
    }
	function readFloat(arr,position){
		var f= [arr[position],arr[position+1],arr[position+2],arr[position+3]];
		return parseFloat(f);
	}
	function readShort(arr,position){
		var s= [arr[position],arr[position+1]];
		return parseShort(s);
	}
	function readDouble(arr,position){
		return readFloat(arr,position);
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

    // Extension API interactions
    var potentialDevices = [];
    ext._deviceConnected = function(dev) {
        potentialDevices.push(dev);

        if (!device) {
            tryNextDevice();
        }
    }

    function tryNextDevice() {
        // If potentialDevices is empty, device will be undefined.
        // That will get us back here next time a device is connected.
        device = potentialDevices.shift();
        if (device) {
            device.open({ stopBits: 0, bitRate: 115200, ctsFlowControl: 0 }, deviceOpened);
        }
    }

    var watchdog = null;
    function deviceOpened(dev) {
        if (!dev) {
            // Opening the port failed.
            tryNextDevice();
            return;
        }
        device.set_receive_handler('serial',function(data) {
            processData(data);
        });
    };

    ext._deviceRemoved = function(dev) {
        if(device != dev) return;
        device = null;
    };

    ext._shutdown = function() {
        if(device) device.close();
        device = null;
    };

    ext._getStatus = function() {
        if(!device) return {status: 1, msg: 'Serial disconnected'};
        if(watchdog) return {status: 1, msg: 'Probing for Serial'};
        return {status: 2, msg: 'Serial connected'};
    }

    var descriptor = {};
	ScratchExtensions.register('Serial', descriptor, ext, {type: 'serial'});
})({});
