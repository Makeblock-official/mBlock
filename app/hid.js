const {MenuItem} = require("electron")
const USBHID = require("node-hid");
const events = require('events');
var _emitter = new events.EventEmitter();  
var _currentHidPath=""
var _port;
var self,_client,_app,_items=[];
function HID(app){
	_app = app;
	self = this;
	_client = _app.getClient();
	this.list = function(callback) {
		callback(USBHID.devices());
	}
	this.isConnected = function(){
		return _port!=null;
	}
	this.close = function(){
		if(_port){
			_port.close();
            _port = null;
		}
	}
	this.send = function(data){
		if(_port){
            _port.write(new Buffer(data).toArray());
		}
	}
	this.connect = function(success,received,disconnect){
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
            return;
        }
		if(!_port){

		}else{
			this.close();
			_port = null;
			return;
		}
		_port = new USBHID(0xffff,0x0416)
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
module.exports = HID;