const {MenuItem} = require("electron")
const USBHID = require("node-hid");
const events = require('events');
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
			var arr = [buffer.length];
			for(var i=0;i<buffer.length;i++){
				arr.push(buffer[i]);
			}
            _port.write(arr);
		}
	}

	//连接hid设备
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
			app.alert("没有找到可用设备");
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
		setTimeout(function () {
			_port = new USBHID.HID(0x0416,0xffff);
			_port.on('error',function(err){
				console.log(err);
			})
			_port.on('data',function(data){
				self.onReceived(data);
			})
			self.onOpen();

		}, 1000);
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
	}

	//设备已断开
	this.onDisconnect = function(){
		if(_client){
			_client.send("connected",{connected:false})
		}
		_isConnected = false;
	}

	//ipc转发接收的数据包
	this.onReceived = function(data){
		if(_client){
			if(data[0]>0){
				_client.send("package",{data:data})
			}
		}
	}
}
module.exports = HID;