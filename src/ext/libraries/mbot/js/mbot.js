// mBot.js

(function(ext) {
	var idDict = [];
	var genNextID = function(realId, args){
		var nextID = (args[0] << 4) | args[1];
		idDict[nextID] = realId;
		return nextID;
	}
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
		M1:9,
		M2:10,
		'led on board':7,
		'light sensor on board':6
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
		Press:0,
		Release:1,
		'Focus On':2,
		'Focus Off':3,
	};
	var tones ={"B0":31,"C1":33,"D1":37,"E1":41,"F1":44,"G1":49,"A1":55,"B1":62,
			"C2":65,"D2":73,"E2":82,"F2":87,"G2":98,"A2":110,"B2":123,
			"C3":131,"D3":147,"E3":165,"F3":175,"G3":196,"A3":220,"B3":247,
			"C4":262,"D4":294,"E4":330,"F4":349,"G4":392,"A4":440,"B4":494,
			"C5":523,"D5":587,"E5":659,"F5":698,"G5":784,"A5":880,"B5":988,
			"C6":1047,"D6":1175,"E6":1319,"F6":1397,"G6":1568,"A6":1760,"B6":1976,
			"C7":2093,"D7":2349,"E7":2637,"F7":2794,"G7":3136,"A7":3520,"B7":3951,
	"C8":4186,"D8":4699};
	var beats = {"Half":500,"Quater":250,"Eighth":125,"Whole":1000,"Double":2000,"Zero":0};
	var ircodes = {	"A":69,
		"B":70,
		"C":71,
		"D":68,
		"E":67,
		"F":13,
		"↑":64,
		"↓":25,
		"←":7,
		"→":9,
		"Setting":21,
		"R0":22,
		"R1":12,
		"R2":24,
		"R3":94,
		"R4":8,
		"R5":28,
		"R6":90,
		"R7":66,
		"R8":82,
		"R9":74};
	var __irCodes = [];
	for(var key in ircodes){
		__irCodes.push(ircodes[key]);
	}
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
	var values = {};
	var indexs = [];
	var startTimer = 0;
	var versionIndex = 0xFA;
    ext.resetAll = function(){
    	device.send([0xff, 0x55, 2, 0, 4]);
    };
	ext.runArduino = function(){};
	
	var SEND_DELAY = 0;
	function RESET_DICT(dict, key){
		dict[key] = false;
	}
	var runBotDict = {};
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
			leftSpeed = speed;
			rightSpeed = speed;
		}else if(direction=="turn right"){
			leftSpeed = -speed;
			rightSpeed = -speed;
		}
		var key = (leftSpeed << 16) | rightSpeed;
		if(runBotDict[key])return;
		runBotDict[key] = true;
		setTimeout(RESET_DICT, SEND_DELAY, runBotDict, key);
        runPackage(5,short2array(leftSpeed),short2array(rightSpeed));
    };
    var runMotorDict = {};
	ext.runMotor = function(port,speed) {
		if(typeof port=="string"){
			port = ports[port];
		}
		if(port == 9){
			speed = -speed;
		}
		var key = (port << 16) | speed;
		if(runMotorDict[key])return;
		runMotorDict[key] = true;
		setTimeout(RESET_DICT, SEND_DELAY, runMotorDict, key);
        runPackage(10,port,short2array(speed));
    };
    var runServoDict = {};
    ext.runServo = function(port,slot,angle) {
		if(typeof port=="string"){
			port = ports[port];
		}
		if(typeof slot=="string"){
			slot = slots[slot];
		}
		var key = (angle << 16) | (port << 8) | slot;
		if(runServoDict[key])return;
		runServoDict[key] = true;
		setTimeout(RESET_DICT, SEND_DELAY, runServoDict, key);
        runPackage(11,port,slot,angle);
    };
    var runBuzzerDict = {};
	ext.runBuzzer = function(tone, beat){
		if(typeof tone == "string"){
			tone = tones[tone];
		}
		if(typeof beat == "string"){
			beat = beats[beat];
		}
		var key = tone;
		if(runBuzzerDict[key])return;
		runBuzzerDict[key] = true;
		setTimeout(RESET_DICT, SEND_DELAY, runBuzzerDict, key);
		runPackage(34,short2array(tone), short2array(beat));
	};
	var stopBuzzerDict = [];
	ext.stopBuzzer = function(){
		var key = 0;
		if(stopBuzzerDict[key])return;
		stopBuzzerDict[key] = true;
		setTimeout(RESET_DICT, SEND_DELAY, stopBuzzerDict, key);
		runPackage(34,short2array(0));
	};
	var runSevsegDict = [];
	ext.runSevseg = function(port,display){
		if(typeof port=="string"){
			port = ports[port];
		}
		var key = port;
		if(runSevsegDict[key])return;
		runSevsegDict[key] = true;
		setTimeout(RESET_DICT, SEND_DELAY, runSevsegDict, key);
		runPackage(9,port,float2array(display));
	};
	var runLedDict = {};
	ext.runLed = function(port,ledIndex,red,green,blue){
		ext.runLedStrip(port, 1, ledIndex, red,green,blue);
	};
	ext.runLedStrip = function(port,slot,ledIndex,red,green,blue){
		if(typeof port=="string"){
			port = ports[port];
		}
		if("all" == ledIndex){
			ledIndex = 0;
		}
		var key = (ledIndex << 24) | (red << 16) | (green << 8) | blue;
		if(runLedDict[key])return;
		runLedDict[key] = true;
		setTimeout(RESET_DICT, SEND_DELAY, runLedDict, key);
		runPackage(8,port,ledIndex,red,green,blue);
	};
	var runLightSensorDict = {};
	ext.runLightSensor = function(port,status){
		if(typeof port=="string"){
			port = ports[port];
		}
		if(typeof status=="string"){
			status = switchStatus[status];
		}
		var key = (port << 8) | status;
		if(runLightSensorDict[key])return;
		runLightSensorDict[key] = true;
		setTimeout(RESET_DICT, SEND_DELAY, runLightSensorDict, key);
		runPackage(3,port,status);
	};
	ext.runShutter = function(port,status){
		runPackage(20,shutterStatus[status]);
	};
	var runIRDict = {};
	ext.runIR = function(message){
		var key = message;
		if(runIRDict[key])return;
		runIRDict[key] = true;
		setTimeout(RESET_DICT, SEND_DELAY, runIRDict, key);
		runPackage(13,string2array(message));
	};
	ext.showCharacters = function(port,x,y,message){
		if(typeof port=="string"){
			port = ports[port];
		}
		message = message.toString();
		runPackage(41,port,1,6,3,short2array(x),short2array(7-y),message.length,string2array(message));
	}
	ext.showTime = function(port,hour,point,min){
		if(typeof port=="string"){
			port = ports[port];
		}
		runPackage(41,port,3,6,point==":"?1:0,short2array(hour),short2array(min));
	}
	ext.showDraw = function(port,x,y,bytes){
		if(typeof port=="string"){
			port = ports[port];
		}
		runPackageForFace(41,port,2,6,bytes.length,short2array(x),short2array(y),bytes.length);
    setTimeout(function(){
      device.send(bytes);
    },40);
	}
	ext.resetTimer = function(){
		startTimer = (new Date().getTime())/1000.0;
	};
	/*
	ext.getLightOnBoard = function(nextID){
		var deviceId = 31;
		getPackage(nextID,deviceId,6);
	}
	*/
	var buttonPressed = false;
	var buttonReleased = false;
	var buttonPressedPrev = false;
	var buttonReleasedPrev = false;
  var lastTime = 0;
	ext.whenButtonPressed = function(status){
		var deviceId = 31;
		var nextID = 100;
		if(typeof status == "string"){
			if(status=="pressed"){
				status = 0;
			}else if(status=="released"){
				status = 1;
			}
		}
    if(new Date().getTime()-lastTime>150){
      lastTime = new Date().getTime();
      getPackage(genNextID(nextID, [10,status]),deviceId,7);
    }
		if(status==0){
			values[nextID] = function(v,extId){
				buttonPressed = v<500;
				buttonReleasedPrev = buttonReleased;
				buttonReleased = !buttonPressed;
			}
      var temp = buttonPressed;
      if(buttonPressedPrev==buttonPressed){
       // temp = false;
      }
      buttonPressedPrev = buttonPressed;
			return temp;
		}else{
			values[nextID] = function(v,extId){
				buttonReleased = v>500;
        buttonPressedPrev = buttonPressed;
				buttonPressed = !buttonReleased;
			}
      var temp = buttonReleased;
      if(buttonReleasedPrev==buttonReleased){
       // temp = false;
      }
      buttonReleasedPrev = buttonReleased;
			return temp;
		}
	}
	ext.getButtonOnBoard = function(nextID,status){
		var deviceId = 31;
		if(typeof status == "string"){
			if(status=="pressed"){
				status = 0;
			}else if(status=="released"){
				status = 1;
			}
		}
		if(status==0){
			values[nextID] = function(v,extId){
				return v<500;
			}
		}else{
			values[nextID] = function(v,extId){
				return v>500;
			}
		}
		nextID = genNextID(nextID, [10,status]);
		getPackage(nextID,deviceId,7);
	}
	var distPrev=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
	var dist=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
	var dist_output =[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
	ext.getUltrasonic = function(nextID,port){
		var deviceId = 1;
		values[nextID] = function(v,extId){
			
			if(v<1){
				v = 0;
			}
		/*	distPrev[extId] = dist[extId];
			dist[extId] = v;
			if(Math.abs(dist[extId]-distPrev[extId])<400&&dist[extId]<400){
				dist_output[extId]-=(dist_output[extId]-dist[extId])*0.4;
			}else{
				dist[extId] = distPrev[extId];
			}*/
			return v;//dist_output[extId];
		}
		if(typeof port=="string"){
			port = ports[port];
		}
		nextID = genNextID(nextID, [port]);
		getPackage(nextID,deviceId,port);
	};
	ext.getPotentiometer = function(nextID,port) {
		var deviceId = 4;
		if(typeof port=="string"){
			port = ports[port];
		}
		nextID = genNextID(nextID, [port]);
		getPackage(nextID,deviceId,port);
    };
    ext.getHumiture = function(nextID,port,valueType){
    	var deviceId = 23;
		if(typeof port=="string"){
			port = ports[port];
		}
		if(typeof valueType=="string"){
			valueType = ("humidity" == valueType) ? 0 : 1;
		}
		nextID = genNextID(nextID, [port,valueType]);
		getPackage(nextID,deviceId,port,valueType);
    };
    ext.getFlame = function(nextID,port){
   		var deviceId = 24;
		if(typeof port=="string"){
			port = ports[port];
		}
		nextID = genNextID(nextID, [port]);
		getPackage(nextID,deviceId,port);
    };
    ext.getGas = function(nextID,port){
    	var deviceId = 25;
		if(typeof port=="string"){
			port = ports[port];
		}
		nextID = genNextID(nextID, [port]);
		getPackage(nextID,deviceId,port);
    };
    ext.gatCompass = function(nextID,port){
    	var deviceId = 26;
		if(typeof port=="string"){
			port = ports[port];
		}
		nextID = genNextID(nextID, [port]);
		getPackage(nextID,deviceId,port);
    };
	ext.getLinefollower = function(nextID,port) {
		var deviceId = 17;
		if(typeof port=="string"){
			port = ports[port];
		}
		nextID = genNextID(nextID, [port]);
		getPackage(nextID,deviceId,port);
    };
	ext.getLightSensor = function(nextID,port) {
		var deviceId = 3;
		if(typeof port=="string"){
			port = ports[port];
		}
		nextID = genNextID(nextID, [port]);
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
		nextID = genNextID(nextID, [port,ax]);
		getPackage(nextID,deviceId,port,ax);
    };
	ext.getSoundSensor = function(nextID,port) {
		var deviceId = 7;
		if(typeof port=="string"){
			port = ports[port];
		}
		nextID = genNextID(nextID, [port]);
		getPackage(nextID,deviceId,port);
    };
	ext.getInfrared = function(nextID,port) {
		var deviceId = 16;
		if(typeof port=="string"){
			port = ports[port];
		}
		nextID = genNextID(nextID, [port]);
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
		nextID = genNextID(nextID, [port,slot]);
		getPackage(nextID,deviceId,port,slot);
    };
	ext.getPirmotion = function(nextID,port) {
		var deviceId = 15;
		if(typeof port=="string"){
			port = ports[port];
		}
		nextID = genNextID(nextID, [port]);
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
		nextID = genNextID(nextID, [port,slot]);
		getPackage(nextID,deviceId,port,slot);
    };
	ext.getGyro = function(nextID,ax) {
		var deviceId = 6;
		if(typeof port=="string"){
			port = ports[port];
		}
		if(typeof slot=="string"){
			slot = slots[slot];
		}
		nextID = genNextID(nextID, [port,slot]);
		getPackage(nextID,deviceId,port,slot);
    };
	ext.getIrRemote = function(nextID,code){
		var deviceId = 14;
		if(typeof code=="string"){
			code = ircodes[code];
		}
		var port = 11;
		var slot = __irCodes.indexOf(code);
		var halfSize = __irCodes.length >> 1;
		if(slot >= halfSize){
			++port;
			slot -= halfSize;
		}
		nextID = genNextID(nextID, [port,slot]);
		getPackage(nextID,deviceId,0,code);
	}
	ext.getIR = function(nextID){
		var deviceId = 13;
		nextID = genNextID(nextID, [9]);
		getPackage(nextID,deviceId);
	}
	ext.getTimer = function(nextID){
		if(startTimer==0){
			startTimer = (new Date().getTime())/1000.0;
		}
		responseValue(nextID,(new Date().getTime())/1000.0-startTimer);
	}
	function runPackage(){
		var bytes = [0xff, 0x55, 0, 0, 2];
		for(var i=0;i<arguments.length;i++){
			if(arguments[i].constructor == "[class Array]"){
				bytes = bytes.concat(arguments[i]);
			}else{
				bytes.push(arguments[i]);
			}
		}
		bytes[2] = bytes.length-3;
		device.send(bytes);
	}
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
		device.send(bytes);
	}
	var getPackDict = [];
	function getPackage(){
		var nextID = arguments[0];
		if(getPackDict[nextID])return;
		getPackDict[nextID] = true;
		setTimeout(RESET_DICT, SEND_DELAY, getPackDict, nextID);
		
		var bytes = [0xff, 0x55];
		bytes.push(arguments.length+1);
		bytes.push(nextID);
		bytes.push(1);
		for(var i=1;i<arguments.length;i++){
			bytes.push(arguments[i]);
		}
		device.send(bytes);
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
							if(value<-255||value>1023){
								value = 0;
							}
						}
							break;
						case 3:{
							value = readShort(_rxBuf,position);
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
					}
					if(type<=5){
						extId = idDict[extId];
						if(values[extId]!=undefined){
							responseValue(extId,values[extId](value,extId));
						}else{
							responseValue(extId,value);
						}
						values[extId] = null;
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
        device.set_receive_handler('mbot',processData);
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
        if(!device) return {status: 1, msg: 'mBot disconnected'};
        if(watchdog) return {status: 1, msg: 'Probing for mBot'};
        return {status: 2, msg: 'mBot connected'};
    }

    var descriptor = {};
	ScratchExtensions.register('mBot', descriptor, ext, {type: 'serial'});
})({});
