// serial.js

(function(ext) {
    var device = null;
    var _rxBuf = [];
	var _reqs = {};
	var values = {};
	var indexs = [];
	var lines = [""];
	var nextID = 0;
	var startTimer = 0;
	var versionIndex = 0xFA;
	var isReceived = false;
	var lastLine = "";
	var lastIrCode = {};
	var isIrRequesting = {};
	
    var ALL_DEV = 0xff;
	var ASSIGN_DEV_ID = 0x10;
	var SYSTEM_RESET = 0x11;
	var DIS_RGB_LED_PWM = 0x21;
	var DIS_RGB_LED_WS2812 = 0x22;
	var MOTOR_DC = 0x2a;
	var MOTOR_STEP = 0x2b;
	var MOTOR_ENCODER = 0x2c;
	var TEMPERATURE_18B20 = 0x40;
	var LIMITSWITCH = 0x42;
	var INFRARED_RECEIVER = 0x44;
	var MIC_SENSOR = 0x45;
	var LIGHT_SENSOR = 0x46;
	
	ext.resetAll = function(){
		isIrRequesting = {};
		sendPackage(ALL_DEV,SYSTEM_RESET);
		sendPackage(ALL_DEV,ASSIGN_DEV_ID,0x0);
	};
	
	ext.assignDevicesID = function(nextID){
		sendPackage(ALL_DEV,ASSIGN_DEV_ID,0x0);
	};
	ext.getDevicesID = function(nextID){
		var output = "";
		for(var i in _deviceList){
			output+=i+":"+_deviceList[i]+",";
		}
		responseValue(nextID,output);
	}
	ext.whenIrReceived = function(which){
		var devID = arguments[0];
		if(isIrRequesting[devID]!=true){
			isIrRequesting[devID] = true;
			sendPackage(devID,INFRARED_RECEIVER,0x2);
		}
		return lastIrCode[devID] == which;
	}
	ext.setMotorDC = function(nextID,devID,slot,speed){
		sendPackage(devID,MOTOR_DC,slot,speed);
	}
	ext.setRGBLed = function(nextID,devID,Index,R,G,B){
		sendPackage(devID,DIS_RGB_LED_PWM,Index,R,G,B);
	}
	ext.getSound = function(nextID,devID){
		_reqs[devID] = nextID;
		sendPackage(devID,MIC_SENSOR,0x0);
	}
	ext.getLight = function(nextID,devID){
		_reqs[devID] = nextID;
		sendPackage(devID,LIGHT_SENSOR,0x0);
	}
	ext.getSwitch = function(nextID,devID){
		_reqs[devID] = nextID;
		sendPackage(devID,LIMITSWITCH,0x0);
	}
	function sendPackage(){
		var deviceID = arguments[0];
		var action = arguments[1];
		var bytes = [];
		bytes.push(0xf0);
		bytes.push(deviceID);
		bytes.push(action);
		switch(action){
			case MOTOR_DC:{
				bytes.push(arguments[2]);
				bytes = bytes.concat(parseShortToBits(arguments[3]));
			}
			break;
			case DIS_RGB_LED_WS2812:{
				bytes.push(arguments[2]);
				bytes.push(arguments[3]);
				bytes.push(arguments[4]);
				bytes.push(arguments[5]);
			}
			break;
			case ASSIGN_DEV_ID:
			case TEMPERATURE_18B20:
			case MIC_SENSOR:
			case LIGHT_SENSOR:
			case LIMITSWITCH:
			default:{
				bytes.push(arguments[2]);
			}
			break;
		}
		bytes.push(0xf7);
		device.send(bytes);
	}
	var _deviceList = {};
	function parsePackage(){
		var deviceID = inputArray[0];
		var action = inputArray[1];
		switch(action){
			case ASSIGN_DEV_ID:{
				_deviceList[deviceID] = inputArray[2];
			}
			break;
			case TEMPERATURE_18B20:{
				responseValue(_reqs[deviceID],parseBitsToFloat(inputArray,3));
			}
			break;
			case MIC_SENSOR:{
				responseValue(_reqs[deviceID],parseBitsToShort(inputArray,3));
			}
			break;
			case LIGHT_SENSOR:{
				responseValue(_reqs[deviceID],parseBitsToShort(inputArray,3));
			}
			break;
			case LIMITSWITCH:{
				responseValue(_reqs[deviceID],inputArray[2]==0?"false":"true");
			}
			break;
			case INFRARED_RECEIVER:{
				lastIrCode[deviceID] = inputArray[2];
			}
			break;
		}
		_reqs[deviceID] = 0;
	}
    var inputArray = [];
	var _isParseStart = false;
	var _isParseStartIndex = 0;
    function processData(bytes) {
		var len = bytes.length;	
		isReceived = true;
		for(var index=0;index<bytes.length;index++){
			if(bytes[index]==0xf0){
				_isParseStart = true;
				inputArray = [];
			}else if(bytes[index]==0xf7){
				if(_isParseStart==true){
					_isParseStart = false;
					parsePackage();
				}
			}else{
				if(_isParseStart){
					inputArray.push(bytes[index]);
				}
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
	function parseBitsToFloat(argv,position){
		var tmp = [];
		tmp[0] = argv[position] & 0x7f;
		tmp[0]|= argv[position+1] << 7;
		tmp[1] = (argv[position+1] >> 1) & 0x7f;
		tmp[1]+= (argv[position+2] << 6);
		tmp[2] = (argv[position+2] >> 2) & 0x7f;
		tmp[2]+= (argv[position+3] << 5);
		tmp[3] = (argv[position+3] >> 3) & 0x7f;
		tmp[3]+= (argv[position+4] << 4);
		return readFloat(tmp,0);
	}
	function parseBitsToShort(argv,position){
		var tmp = [];
		tmp[0] = argv[position] & 0x7f;
		tmp[0]|= argv[position+1] << 7;
		tmp[1] = (argv[position+1] >> 1) & 0x7f;
		tmp[1] |= (argv[position+2] << 6);
		return readShort(tmp,0);
	}
	function parseFloatToBits(arg){
		var tmp = float2array(arg);
		var bits = [];
		bits[0] = tmp[0] & 0x7f;
		bits[1] = ((tmp[1] << 1) | (tmp[0] >> 7)) & 0x7f;
		bits[2] = ((tmp[2] << 2) | (tmp[1] >> 6)) & 0x7f;
		bits[3] = ((tmp[3] << 3) | (tmp[2] >> 5)) & 0x7f;
		bits[4] = (tmp[3] >> 4) & 0x7f;
		return bits;
	}
	function parseShortToBits(arg){
		var tmp = short2array(arg);
		var bits = [];
		bits[0] = tmp[0] & 0x7f;
		bits[1] = ((tmp[1] << 1) | (tmp[0] >> 7)) & 0x7f;
		bits[2] = (tmp[1] >> 6) & 0x7f;
		return bits;
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
        device.set_receive_handler('neurons',function(data) {
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
        if(!device) return {status: 1, msg: 'Neurons disconnected'};
        if(watchdog) return {status: 1, msg: 'Probing for Neurons'};
        return {status: 2, msg: 'Neurons connected'};
    }

    var descriptor = {};
	ScratchExtensions.register('Neurons', descriptor, ext, {type: 'serial'});
})({});
