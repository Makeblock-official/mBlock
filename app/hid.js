const {MenuItem} = require("electron")
const USBHID = require("node-hid");
const events = require('events');
const sudoer = require('./sudoCommands.js');
/**
 * 2.4G无线串口通讯： HID设备连接、数据收发
 */
var _emitter = new events.EventEmitter();  
var _currentHidPath=""
var _port;
var _client,_app,_items=[];
var _isConnected = false;
function HID(app){
	var self = this;
	_app = app;
	_client = _app.getClient();

	//返回hid设备列表
	this.list = function(callback) {
		callback(USBHID.devices());
	}
	
	//hid设备是否已连接
	this.isConnected = function(){
		return _isConnected;
	}

	//断开hid设备连接
	this.close = function(){
		if(_port){
			_port.close();
            _port = null;
			self.onDisconnect();
		}
	}

	//发送数据
	this.send = function(data){
		if(_port){
			var buffer = new Buffer(data)
			var arr = [0,buffer.length];
			for(var i=0;i<buffer.length;i++){
				arr.push(buffer[i]);
			}
            _port.write(arr);
		}
	}

	//连接hid设备
	var enabledHIDPermission = false;
	this.connect = function(){
        var devices = USBHID.devices();
        var isDeviceFound = false;
        for(var i in devices){
            var device = devices[i];
            if(device.vendorId==0x0416&&device.productId==0xffff){
                isDeviceFound = true;
                break;
            }
        }
        if(!isDeviceFound){
			app.alert("Cannot find 2.4G dongle");
            return;
        }
		$isConnect = false;
		if(!_port){
            $isConnect = true;
		}
		// 先断开之前的蓝牙连接，重新进行连接
		_app.allDisconnect();
		
		if (!$isConnect) {
			return;
		}
		console.log('现在进行2.4G连接。。。');
		var tryOpenHID = function() {
			try {
				_port = new USBHID.HID(0x0416,0xffff);
			}
			catch (error) {
				// this is because I do not have enough permission to do this.
				app.alert('Cannot connect to the 2.4G device. Please check your USB connection or use another USB port.')
				if(!enabledHIDPermission && process.platform == 'linux') {
					enabledHIDPermission = true;
					sudoer.enableHIDInLinux(function(error, stdout, stderr) {
						if( error === null ) {
							tryOpenHID();
						}
					});
				}
			}
			if(!_port) return;
			_port.on('error',function(err){
				console.log(err);
			})
			_port.on('data',function(data){
				self.onReceived(data);
			})
			self.onOpen();
		}
		setTimeout(tryOpenHID, 1500);
	}

	this.on = function(event,listener){
		_emitter.on(event,listener);
	}

	//设备已连接
	this.onOpen = function(){
		if(_client){
			_client.send("connected",{connected:true})
		}
		_isConnected = true;
		_app.getMenu().update();
	}

	//设备已断开
	this.onDisconnect = function(){
		if(_client){
			_client.send("connected",{connected:false})
		}
		_isConnected = false;
		_app.getMenu().update();
	}

	//ipc转发接收的数据包
	this.onReceived = function(data){
		if(_client){
			if(data[0]>0){
				var arr=[];
				for(var i=0;i<data[0];i++){
					arr.push(data[i+1]);
				}
				_client.send("package",{data:arr})
			}
		}
	}
}
module.exports = HID;