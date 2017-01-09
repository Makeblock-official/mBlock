// makeblock.js

(function(ext) {
    var device = null;
    var _rxBuf = [];

    // Sensor states:
    var ports = {
        Port1: 1,
        Port2: 2,
        Port3: 3,
        Port4: 4,
        Port5: 5,
        Port6: 6,
        Port7: 7,
        Port8: 8,
		Port1A:1,
		Port1B:9,
		Port2A:2,
		Port2B:10,
		Port3A:3,
		Port3B:11,
		Port4A:4,
		Port4B:12
    };
    var servoSlot = {
    	"A6" :60,
    	"A7" :61,
    	"A8" :62,
    	"A9" :63,
    	"A10":64,
    	"A11":65,
    	"A12":66,
    	"A13":67,
    	"A14":68,
    	"A15":69
    };
    var button_keys = {
		"key1":1,
		"key2":2,
		"key3":3,
		"key4":4
	};
	var slots = {
		Slot1:1,
		Slot2:2
	};
	var switchStatus = {
		On:1,
		Off:0
	};
	var shutterStatus = {
		Press:1,
		Release:0,
		'Focus On':3,
		'Focus Off':2
	};
	var axis = {
		'X-Axis':1,
		'Y-Axis':2,
		'Z-Axis':3
	};
	var encoderValTypes = {
		"speed":2,
		"position":1
	};
    var inputs = {
        slider: 0,
        light: 0,
        sound: 0,
        button: 0,
        'resistance-A': 0,
        'resistance-B': 0,
        'resistance-C': 0,
        'resistance-D': 0
    };
    var augigaMode = {
    	"bluetooth mode":0,
		"ultrasonic mode":1,
		"balance mode":2,
		"IR mode":3,
		"line follower mode":4
    };
	var values = {"run forward":1,
		"run backward":2,
		"turn left":3,
		"turn right":4};
    ext.resetAll = function(){
    	device.send([0xff, 0x55, 2, 0, 4]);
    };
    ext.runArduino = function(){
		responseValue();
	};
	ext.switchMode = function(mode){
		if(typeof mode == "string"){
			mode = augigaMode[mode];
		}
		runPackage(0x3c, 0x11, mode);
	};
	ext.runBot = function(direction,speed) {
		var leftSpeed = 0;
		var rightSpeed = 0;
		if(direction=="run forward"){
			leftSpeed = -speed;
			rightSpeed = speed;
		}else if(direction=="run backward"){
			leftSpeed = speed;
			rightSpeed = -speed;
		}else if(direction=="turn left"){
			leftSpeed = -speed;
			rightSpeed = -speed;
		}else if(direction=="turn right"){
			leftSpeed = speed;
			rightSpeed = speed;
		}
        runPackage(5,short2array(leftSpeed),short2array(rightSpeed));
    };
    ext.runDegreesBot = function(direction,distance,speed){
    	direction = values[direction];
        runPackage(62,05,direction,int2array(distance),short2array(Math.abs(speed)));
    };
	ext.getTouchSensor = function(port){
    	var deviceId = 51;
    	if(typeof port=="string"){
			port = ports[port];
		}
		getPackage(0,deviceId,port);
    };
    ext.getEncoderValue = function(port,valType){
    	var deviceId = 0x3d;
		if(typeof port=="string"){
			port = ports[port];
		}
		if(typeof valType == "string"){
			valType = encoderValTypes[valType];
		}
    	getPackage(0,deviceId,0,port,valType);
    };
    ext.getButton = function(port, key){
    	var deviceId = 22;
    	if(typeof port=="string"){
			port = ports[port];
		}
		if(typeof key == "string"){
			key = button_keys[key];
		}
		getPackage(0,deviceId,port, key);
    };
	ext.runMotor = function(port,speed) {
		if(typeof port=="string"){
			port = ports[port];
		}
        runPackage(10,port,short2array(speed));
    };
    ext.runServoByPin = function(pin,angle){
    	if(typeof pin=="string"){
			pin = servoSlot[pin];
		}
    	runPackage(33,pin,angle);
    };
    ext.runServo = function(port,slot,angle) {
		if(typeof port=="string"){
			port = ports[port];
		}
		if(typeof slot=="string"){
			slot = slots[slot];
		}
		if(angle > 180){
			angle = 180;
		}
        runPackage(11,port,slot,angle);
    };
	ext.runStepperMotor = function(port, speed, distance){
		if(typeof port=="string"){
			port = ports[port];
		}
		runPackage(40,port,short2array(speed),int2array(distance));
	};
	ext.runEncoderMotor = function(port, speed){
		if(typeof port=="string"){
			port = ports[port];
		}
		runPackage(62,02,port,short2array(speed));
	};
	ext.runEncoderMotorPWM = function(port,speed){
		if(typeof port=="string")
		{
			port = ports[port];
		}
		runPackage(61,0,port,short2array(-speed));
	};
	ext.runEncoderMotorRotate = function(port,distance,speed){
		if(typeof port=="string"){
			port = ports[port];
		}
		runPackage(62, 01,port, int2array(distance),short2array(Math.abs(speed)));
		
	};
	ext.runSevseg = function(port,display){
		if(typeof port=="string"){
			port = ports[port];
		}
		runPackage(9,port,float2array(display));
	};
	ext.runLed = function(port,ledIndex,red,green,blue){
		ext.runLedStrip(port, 2, ledIndex, red,green,blue);
	};
	ext.runLedOnBoard = function(ledIndex,red,green,blue){
		ext.runLedStrip(0, 2, ledIndex, red,green,blue);
	};
	ext.runLedStrip = function(port,slot,ledIndex,red,green,blue){
		if(typeof port=="string"){
			port = ports[port];
		}
		if(typeof slot=="string"){
			slot = slots[slot];
		}
		runPackage(8,port,slot,ledIndex=="all"?0:ledIndex,red,green,blue);
	};
	ext.runLightsensor = function(port,status){
		if(typeof port=="string"){
			port = ports[port];
		}
		runPackage(3,port,switchStatus[status]);
	};
	ext.runShutter = function(port,status){
		if(typeof port=="string"){
			port = ports[port];
		}
		runPackage(20,port,shutterStatus[status]);
	};
	 ext.runFan = function(port, direction) {
		var portToPin = {
			Port5: [16, 17],
			Port6: [62, 63],
			Port7: [64, 65],
			Port8: [67, 66]
		};
		var directionToValue = {
			"clockwise": [1,0], 
			"counter-clockwise": [0,1], 
			"stop": [0,0]
		};
		if(typeof port=="string"){
			pins = portToPin[port];
			if(pins) {
				runPackage(0x1e, pins[0], directionToValue[direction][0]);
				runPackage(0x1e, pins[1], directionToValue[direction][1]);
			}
		}
	};
	ext.showNumber = function(port,message){
		if(typeof port=="string"){
			port = ports[port];
		}
		runPackage(41,port,4,float2array(message));
	};
	ext.showCharacters = function(port,x,y,message){
		if(typeof port=="string"){
			port = ports[port];
		}
		var index = Math.max(0, Math.floor(x / -6));
		message = message.toString().substr(index, 4);
		if(index > 0){
			x += index * 6;
		}
		if(x >  16) x = 16;
		if(y >  8) y = 8;
		if(y < -8) y = -8;
		runPackage(41,port,1,x,y+7,message.length,string2array(message));
	}
	ext.showTime = function(port,hour,point,min){
		if(typeof port=="string"){
			port = ports[port];
		}
		runPackage(41,port,3,point==":"?1:0,hour,min);
	}
	ext.showDraw = function(port,x,y,bytes){
		if(typeof port=="string"){
			port = ports[port];
		}
		if(x >  16) x = 16;
		if(x < -16) x = -16;
		if(y >  8) y = 8;
		if(y < -8) y = -8;
		runPackage(41,port,2,x,y,bytes);
	}
	var startTimer = 0;
	ext.getTimer = function(nextID){
		if(startTimer==0){
			startTimer = (new Date().getTime())/1000.0;
		}
		responseValue(nextID,(new Date().getTime())/1000.0-startTimer);
	};
	ext.resetTimer = function(){
		startTimer = (new Date().getTime())/1000.0;
		responseValue();
	};
	var distPrev=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
	var dist=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
	var dist_output =[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
	ext.getUltrasonic = function(nextID,port){
		var deviceId = 1;
		if(typeof port=="string"){
			port = ports[port];
		}
		getPackage(nextID,deviceId,port);
	};
	ext.getPotentiometer = function(nextID,port) {
		var deviceId = 4;
		if(typeof port=="string"){
			port = ports[port];
		}
		getPackage(nextID,deviceId,port);
    };
	ext.getLinefollower = function(nextID,port) {
		var deviceId = 17;
		if(typeof port=="string"){
			port = ports[port];
		}
		getPackage(nextID,deviceId,port);
    };
	ext.getLightsensor = function(nextID,port) {
		var deviceId = 3;
		if(typeof port=="string"){
			port = ports[port];
		}
		getPackage(nextID,deviceId,port);
    };
	ext.getJoystick = function(nextID,port,ax) {
		var deviceId = 5;
		if(typeof port=="string"){
			port = ports[port];
		}
		if(typeof ax=="string"){
			ax = axis[ax];
		}
		getPackage(nextID,deviceId,port,ax);
    };
	ext.getSoundsensor = function(nextID,port) {
		var deviceId = 7;
		if(typeof port=="string"){
			port = ports[port];
		}
		getPackage(nextID,deviceId,port);
    };
	ext.getInfrared = function(nextID,port) {
		var deviceId = 16;
		if(typeof port=="string"){
			port = ports[port];
		}
		getPackage(nextID,deviceId,port);
    };
	ext.getLimitswitch = function(nextID,port,slot) {
		var deviceId = 21;
		if(typeof port=="string"){
			port = ports[port];
		}
		if(typeof slot=="string"){
			slot = slots[slot];
		}
		getPackage(nextID,deviceId,port,slot);
    };
	ext.getPirmotion = function(nextID,port) {
		var deviceId = 15;
		if(typeof port=="string"){
			port = ports[port];
		}
		getPackage(nextID,deviceId,port);
    };
	ext.getTemperature = function(nextID,port,slot) {
		var deviceId = 2;
		if(typeof port=="string"){
			port = ports[port];
		}
		if(typeof slot=="string"){
			slot = slots[slot];
		}
		getPackage(nextID,deviceId,port,slot);
    };
    ext.getGyroExternal = function(nextID,ax) {
    	var deviceId = 6;
		if(typeof ax=="string"){
			ax = axis[ax];
		}
		getPackage(nextID,deviceId,0,ax);
    };
    ext.getHumiture = function(nextID,port,valueType){
    	var deviceId = 23;
		if(typeof port=="string"){
			port = ports[port];
		}
		if(typeof valueType=="string"){
			valueType = ("humidity" == valueType) ? 0 : 1;
		}
		getPackage(nextID,deviceId,port,valueType);
    };
    ext.getFlame = function(nextID,port){
   		var deviceId = 24;
		if(typeof port=="string"){
			port = ports[port];
		}
		getPackage(nextID,deviceId,port);
    };
    ext.getGas = function(nextID,port){
    	var deviceId = 25;
		if(typeof port=="string"){
			port = ports[port];
		}
		getPackage(nextID,deviceId,port);
    };
    ext.gatCompass = function(nextID,port){
    	var deviceId = 26;
		if(typeof port=="string"){
			port = ports[port];
		}
		getPackage(nextID,deviceId,port);
    };
     ext.getEncoderSpeedValue = function(nextID,port){
    	var deviceId = 61;
    	if(typeof port=="string"){
    		port = ports[port];
    	}
    	getPackage(nextID,deviceId,00,port,02);
    };
    ext.getEncoderPosValue = function(nextID,port){
    	var deviceId = 61;
    	if(typeof port=="string"){
    		port = ports[port];
    	}
    	getPackage(nextID,deviceId,00,port,01);
    };
	function sendPackage(argList, type){
		var bytes = [0xff, 0x55, 0, 0, type];
		for(var i=0;i<argList.length;++i){
			var val = argList[i];
			if(val.constructor == "[class Array]"){
				bytes = bytes.concat(val);
			}else{
				bytes.push(val);
			}
		}
		bytes[2] = bytes.length - 3;
		device.send(bytes);
	}
	
	function runPackage(){
		sendPackage(arguments, 2);
	}
	function getPackage(){
		var nextID = arguments[0];
		Array.prototype.shift.call(arguments);
		sendPackage(arguments, 1);
	}
    
    var inputArray = [];
	var _isParseStart = false;
	var _isParseStartIndex = 0;
    function processData(bytes) {
		var len = bytes.length;
		if(_rxBuf.length>30){
			_rxBuf = [];
		}
		for(var index=0;index<bytes.length;index++){
			var c = bytes[index];
			_rxBuf.push(c);
			if(_rxBuf.length>=2){
				if(_rxBuf[_rxBuf.length-1]==0x55 && _rxBuf[_rxBuf.length-2]==0xff){
					_isParseStart = true;
					_isParseStartIndex = _rxBuf.length-2;
				}
				if(_rxBuf[_rxBuf.length-1]==0xa && _rxBuf[_rxBuf.length-2]==0xd&&_isParseStart){
					_isParseStart = false;
					
					var position = _isParseStartIndex+2;
					var extId = _rxBuf[position];
					position++;
					var type = _rxBuf[position];
					position++;
					//1 byte 2 float 3 short 4 len+string 5 double
					var value;
					switch(type){
						case 1:{
							value = _rxBuf[position];
							position++;
						}
							break;
						case 2:{
							value = readFloat(_rxBuf,position);
							position+=4;
						}
							break;
						case 3:{
							value = readInt(_rxBuf,position,2);
							position+=2;
						}
							break;
						case 4:{
							var l = _rxBuf[position];
							position++;
							value = readString(_rxBuf,position,l);
						}
							break;
						case 5:{
							value = readDouble(_rxBuf,position);
							position+=4;
						}
							break;
						case 6:
							value = readInt(_rxBuf,position,4);
							position+=4;
							break;
					}
					if(type<=6){
						responseValue(extId,value);
					}else{
						responseValue();
					}
					_rxBuf = [];
				}
			} 
		}
    }
	function readFloat(arr,position){
		var f= [arr[position],arr[position+1],arr[position+2],arr[position+3]];
		return parseFloat(f);
	}
	function readInt(arr,position,count){
		var result = 0;
		for(var i=0; i<count; ++i){
			result |= arr[position+i] << (i << 3);
		}
		return result;
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
        device.set_receive_handler('makeblock',processData);
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
        if(!device) return {status: 1, msg: 'Makeblock disconnected'};
        if(watchdog) return {status: 1, msg: 'Probing for Makeblock'};
        return {status: 2, msg: 'Makeblock connected'};
    }

    var descriptor = {};
	ScratchExtensions.register('Makeblock', descriptor, ext, {type: 'serial'});
})({});
