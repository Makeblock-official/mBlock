var SerialPort = require("serialport");
var currentSerialPort=""
var port;
exports.list = function(callback) {
	SerialPort.list(callback);
}
exports.isConnected = function(name){
	if(name){
		return currentSerialPort==name;
	}else{
		return currentSerialPort!="";
	}
}
exports.close = function(){
	if(port&&port.isOpen()){
		port.close();
	}
	currentSerialPort = "";
}
exports.send = function(data){
	if(port&&port.isOpen()){
		port.write(new Buffer(data),function(){
		});
	}
}
exports.connect = function(name,success,received,disconnect){
	if(currentSerialPort!=name){
		currentSerialPort = name;
	}else{
		this.close();
		port = null;
		return;
	}
	port = new SerialPort(currentSerialPort,{baudRate:115200})
	port.on('open',function(){
		if(success){
			success();
		}
	})
	port.on('error',function(err){

	})
	port.on('data',function(data){
		if(received){
			received(data);
		}
	})
	port.on('close', function(){
		if(disconnect){
			disconnect();
		}
		currentSerialPort = "";
	})
	port.on('disconnect', function(){
		if(disconnect){
			disconnect();
		}
		currentSerialPort = "";
	})

}