// makeblock.js

(function(ext) {
    var _device = null;
	var _util = null;
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
        Port9: 9,
        Port10: 10,
		M1:9,
		M2:10
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
	}
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
    function checkPortAndSlot(port, slot, sensor){
    	if((port == 4 || port == 6) && slot == 1){
			interruptThread(sensor + " not support Slot1 on Port" + port);
			return true;
		}
		return false;
    }
	var values = {};
	var indexs = [];
	var versionIndex = 0xFA;
    ext.resetAll = function(){
    	_device.send([0xff, 0x55, 2, 0, 4]);
    };
	ext.runArduino = function(){
		responseValue();
	};
	ext.getTouchSensor = function(port){
    	var deviceId = 51;
    	if(typeof port=="string"){
			port = ports[port];
		}
		getPackage(0,deviceId,port);
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
        runPackage(10,port,_util.short2array(speed));
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
		if(checkPortAndSlot(port, slot, "Servo")){
			return;
		}
        runPackage(11,port,slot,angle);
    };
	ext.runStepperMotor = function(port, speed, distance){
		if(typeof port=="string"){
			port = ports[port];
		}
		runPackage(40,port,_util.short2array(speed),_util.int2array(distance));
	};
	ext.runEncoderMotor = function(port, slot, speed, distance){
		if(typeof port=="string"){
			port = ports[port];
		}
		if(typeof slot=="string"){
			slot = slots[slot];
		}
		runPackage(12,0x8,slot,_util.short2array(speed),_util.float2array(distance));
	};
	ext.runSevseg = function(port,display){
		if(typeof port=="string"){
			port = ports[port];
		}
		runPackage(9,port,_util.float2array(display));
	};
	ext.runLed = function(port,ledIndex,red,green,blue){
		ext.runLedStrip(port, 2, ledIndex, red,green,blue);
	};
	ext.runLedStrip = function(port,slot,ledIndex,red,green,blue){
		if(typeof port=="string"){
			port = ports[port];
		}
		if(typeof slot=="string"){
			slot = slots[slot];
		}
		if(checkPortAndSlot(port, slot, "Led strip")){
			return;
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
	ext.showCharacters = function(port,x,y,message){
		if(typeof port=="string"){
			port = ports[port];
		}
		message = message.toString();
		runPackage(41,port,1,6,3,_util.short2array(x),_util.short2array(7-y),message.length,_util.string2array(message));
	}
	ext.showTime = function(port,hour,point,min){
		if(typeof port=="string"){
			port = ports[port];
		}
		runPackage(41,port,3,6,point==":"?1:0,_util.short2array(hour),_util.short2array(min));
	}
	ext.showDraw = function(port,x,y,bytes){
		if(typeof port=="string"){
			port = ports[port];
		}
		runPackageForFace(41,port,2,6,bytes.length,_util.short2array(x),_util.short2array(y),bytes.length);
      _device.send(bytes);
	};
	function runPackageForFace(){
		var bytes = [0xff, 0x55, 0, 0, 2];
		for(var i=0;i<arguments.length;i++){
			if(arguments[i].constructor == "[class Array]"){
				bytes = bytes.concat(arguments[i]);
			}else{
				bytes.push(arguments[i]);
			}
		}
		bytes[2] = bytes.length+13;
		_device.send(bytes);
	}
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
		if(checkPortAndSlot(port, slot, "Limit switch")){
			return;
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
		if(checkPortAndSlot(port, slot, "Temperature")){
			return;
		}
		getPackage(nextID,deviceId,port,slot);
    };
	ext.getGyro = function(nextID,ax) {
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
	
	function sendPackage(argList, type){
		var bytes = [0xff, 0x55, 0, 0, type];
		for(var i=0;i<argList.length;++i){
			var val = argList[i];
			if(val instanceof Array){
				bytes = bytes.concat(val);
			}else{
				bytes.push(val);
			}
		}
		bytes[2] = bytes.length - 3;
		_device.send(bytes);
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
    ext.processData = function(bytes) {
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
							value = _util.readFloat(_rxBuf,position);
							position+=4;
						}
							break;
						case 3:{
							value = _util.readInt(_rxBuf,position,2);
							position+=2;
						}
							break;
						case 4:{
							var l = _rxBuf[position];
							position++;
							value = _util.readString(_rxBuf,position,l);
						}
							break;
						case 5:{
							value = _util.readDouble(_rxBuf,position);
							position+=4;
						}
							break;
						case 6:
							value = _util.readInt(_rxBuf,position,4);
							position+=4;
							break;
					}
					if(type<=6){
						if (responsePreprocessor[extId] && responsePreprocessor[extId] != null) {
							value = responsePreprocessor[extId](value);
							responsePreprocessor[extId] = null;
						}
						_device.responseValue(extId,value);
					}else{
						_device.responseValue();
					}
					_rxBuf = [];
				}
			} 
		}
    }

    // Extension API interactions
    var potentialDevices = [];
    ext._deviceConnected = function(dev,util) {
        _device = dev;
		_util = util;
    }


    var watchdog = null;
    function deviceOpened(dev) {
        if (!dev) {
            // Opening the port failed.

            return;
        }
        // device.set_receive_handler('mbot',processData);
    };

    ext._deviceRemoved = function(dev) {
        if(_device != dev) return;
        _device = null;
    };

    ext._shutdown = function() {
        if(_device) _device.close();
        _device = null;
    };

    ext._getStatus = function() {
        if(!_device) return {status: 1, msg: 'Makeblock disconnected'};
        if(watchdog) return {status: 1, msg: 'Probing for Makeblock'};
        return {status: 2, msg: 'Makeblock connected'};
    }

    var descriptor = {};
	ScratchExtensions.register('UNO Shield', descriptor, ext, {type: 'serial'});
})({});
