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
	var _translator = app.getTranslator();
	_client = _app.getClient();
	this.list = function(callback) {
		SerialPort.list(callback);
	}
	this.currentSerialPort = function() { return _currentSerialPort; }
	this.isConnected = function(name){
		//return _port&&_port.isOpen();
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
		//console.log(data)
		if(_port&&_port.isOpen()){
			_port.write(new Buffer(data),function(){

			});
		}
	}
	this.connect = function(name){ // linux : /dev/ttyUSB0
	    _currentSerialPort = name;
		
		_port = new SerialPort(_currentSerialPort,{ baudRate:115200 })
		_port.on('open',function(){ // 串口连接，进行连接
			self.onOpen();
		})
		_port.on('error',function(err){
            if (err.message.indexOf('cannot open') > -1) { // cannot open XXX : 无权限
				sudoer.enableSerialInLinux(errorCallbackHander);
			} else if (err.message.indexOf('Cannot lock port') > -1) { // Cannot lock port : 端口被锁
				console.log('port is locked:');
			}
			console.log(err);
		})
		_port.on('data',function(data){
			self.onReceived(data);
		})
		_port.on('close', function() { // 主动点击取消连接
			self.onDisconnect()
			_currentSerialPort = "";
		})
		_port.on('disconnect', function(){ // 拔出
			self.onDisconnect()
			_currentSerialPort = "";
		})
		var errorCallbackHander = function (error, stderr, stdout) {
            if (error == null) { // 正常流程：密码输对的情况
				_app.alert(_translator.map("Please restart your computer to enable serial ports."));
				//_port.open(); // 死循环，因为没有重启电脑的情况下，还是需要输入密码
			}
		    self.update(); // 更新菜单
		};
	}
	this.getMenuItems = function(){
		return _items;
	}
	this.update = function(){ // 更新菜单
		_items = [];
		SerialPort.list(function(err,ports){
			for(var i=0;i<ports.length;i++){
				if (ports[i].comName.indexOf('/dev/ttyS') > -1) {
					continue;
				}
				var item = new MenuItem({
					name:ports[i].comName,
					label:ports[i].comName,
					checked:self.isConnected(ports[i].comName),
					type:'checkbox',
					click:function(item,focusedWindow){
						var isConnect = false;
					    if(_currentSerialPort != item.name){ // 需要连接串口
                            isConnect = true;
						}
						_app.allDisconnect(); // 断开之前的所有连接
						if (isConnect) {
							setTimeout(function () {self.connect(item.name);}, 1500);
						}
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
	this.onOpen = function(){
        self.update();
		if(_client){
			_client.send("connected",{connected:self.isConnected()})
		}
	}
	this.onDisconnect = function(){ // 主动断开连接或直接拔掉串口线
        self.update();
		if(_client){
			try {
				_client.send("connected",{connected:false});
			} catch (e) {
				// when the program is shutting down, front-end web page
				// no longer exists; in this case, ignore the 
				// "Object has been destroyed" Exception.
			}
		}
	}
	this.onReceived = function(data){
		if(_client){
			_client.send("package",{data:data})
		}
	}
}
module.exports = Serial;
