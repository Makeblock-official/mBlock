const {MenuItem} = require("electron")
const SerialPort = require("serialport");
const events = require('events');
var _emitter = new events.EventEmitter();  
var _currentSerialPort=""
var _port;
var self,_client,_app,_items=[];
function Serial(app){
	_app = app;
	self = this;
	_client = _app.getClient();
	this.list = function(callback) {
		SerialPort.list(callback);
	}
	this.isConnected = function(name){
		if(name){
			return _currentSerialPort==name&&_port&&_port.isOpen();
		}else{
			return _currentSerialPort!=""&&_port&&_port.isOpen();
		}
	}
	this.close = function(){
		if(_port&&_port.isOpen()){
			_port.close();
		}
		_currentSerialPort = "";
	}
	this.send = function(data){
		if(_port&&_port.isOpen()){
			_port.write(new Buffer(data),function(){

			});
		}
	}
	this.connect = function(name,success,received,disconnect){
		if(_currentSerialPort!=name){
			_currentSerialPort = name;
		}else{
			this.close();
			_port = null;
			return;
		}
		_port = new SerialPort(_currentSerialPort,{ baudRate:115200 })
		_port.on('open',function(){
			if(success){
				success();
			}
		})
		_port.on('error',function(err){

		})
		_port.on('data',function(data){
			if(received){
				received(data);
			}
		})
		_port.on('close', function(){
			if(disconnect){
				disconnect();
			}
			currentSerialPort = "";
		})
		_port.on('disconnect', function(){
			if(disconnect){
				disconnect();
			}
			_currentSerialPort = "";
		})
	}
	this.getMenuItems = function(){
		return items;
	}
	this.update = function(){
		items = [];
		SerialPort.list(function(err,ports){
			for(var i=0;i<ports.length;i++){
				var item = new MenuItem({
					name:ports[i].comName,
					label:ports[i].comName,
					checked:self.isConnected(ports[i].comName),
					type:'checkbox',
					click:function(item,focusedWindow){
						self.connect(item.label,self.onOpen,self.onReceived,self.onDisconnect);
					}
				})
			}
			items.push(item);
			_emitter.emit("list",items);
		})
	}
	this.on = function(event,listener){
		_emitter.on(event,listener);
	}
	this.onOpen = function(){
		_app.updateMenu();
		if(_client){
			_client.send("connected",{connected:self.isConnected()})
		}
	}
	this.onDisconnect = function(){
		if(_client){
			_client.send("data",{method:"connected",connected:false})
		}
	}
	this.onReceived = function(data){
		if(_client){
			_client.send("data",{method:"command",buffer:data})
		}
	}
}
module.exports = Serial;