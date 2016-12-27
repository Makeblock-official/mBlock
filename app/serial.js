/**
 * USB串口通讯
 */
const {MenuItem} = require("electron")
const SerialPort = require("serialport");
const events = require('events');
const sudoer = require('./sudoCommands.js');
var _emitter = new events.EventEmitter();  
var _currentSerialPort=""
var _port;
var _client,_app,_items=[];
function Serial(app){
	_app = app;
	var self = this;
	_client = _app.getClient();
	this.list = function(callback) {
		SerialPort.list(callback);
	}
	this.currentSerialPort = function() { return _currentSerialPort; }
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
		console.log(data)
		if(_port&&_port.isOpen()){
			_port.write(new Buffer(data),function(){

			});
		}
	}
	this.connect = function(name){ // linux : /dev/ttyUSB0
		if(_currentSerialPort!=name){
			_currentSerialPort = name;
		}else{
			this.close();
			_port = null;
			return;
		}
		_port = new SerialPort(_currentSerialPort,{ baudRate:115200 })
		_port.on('open',function(){ // 串口连接，进行连接
			self.onOpen();
		})
		_port.on('error',function(err){ // cannot open XXX
            sudoer.enableSerialInLinux(errorCallbackHander);
		})
		_port.on('data',function(data){
			self.onReceived(data);
		})
		_port.on('close', function(){
			self.onDisconnect()
			currentSerialPort = "";
		})
		_port.on('disconnect', function(){
			self.onDisconnect()
			_currentSerialPort = "";
		})
		var errorCallbackHander = function (error, stderr, stdout) {
            if (error == null) { // 正常流程：密码输对的情况
                console.log(name);
				self.connect(name);
				console.log('yi 连接');
			}
		};
	}
	this.getMenuItems = function(){
		return _items;
	}
	this.update = function(){
		_items = [];
		SerialPort.list(function(err,ports){
			for(var i=0;i<ports.length;i++){
				var item = new MenuItem({
					name:ports[i].comName,
					label:ports[i].comName,
					checked:self.isConnected(ports[i].comName),
					type:'checkbox',
					click:function(item,focusedWindow){
						self.connect(item.label);
					}
				})
				_items.push(item);
			}
			_app.getMenu().update();
		})
	}
	this.on = function(event,listener){
		_emitter.on(event,listener);
	}
	this.onOpen = function(){console.log('ou海');
        _app.getMenu().update();
		if(_client){
			_client.send("connected",{connected:self.isConnected()})
		}
	}
	this.onDisconnect = function(){
        _app.getMenu().update();
		if(_client){
			_client.send("connected",{connected:false})
		}
	}
	this.onReceived = function(data){
		if(_client){
			_client.send("package",{data:data})
		}
	}
}
module.exports = Serial;