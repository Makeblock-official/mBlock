/**
 * 蓝牙串口通讯
 */
const {MenuItem} = require("electron")
const SPP = require('bluetooth-serial-port');
const events = require('events');
var _emitter = new events.EventEmitter();  
var _btSerial,_app,_client,_items=[];
var _devices = {};
var _currentBluetooth = ""
function Bluetooth(app){
    var self = this;
    _app = app;
	_client = _app.getClient();
    _btSerial = new SPP.BluetoothSerialPort();

	this.isConnected = function(name){
		if(name){
			return _currentBluetooth==name&&_btSerial&&_btSerial.isOpen();
		}else{
			return _currentBluetooth!=""&&_btSerial&&_btSerial.isOpen();
		}
	}
    this.connect = function(name){
        _currentBluetooth = name;
        var device = _devices[name];
        _btSerial.connect(device.address, device.channel, function() {
            self.onOpen();
 
        }, function () {
            console.log('cannot connect');
        });
    }
    this.close = function(){
        // close the connection when you're ready 
        _btSerial.close();
    }
    this.send = function(data){
        _btSerial.write(new Buffer(data), function(err, bytesWritten) {
            if (err) console.log(err);
        });
    }
    this.discover = function(){
        _items = [];
        _devices = {};
        _btSerial.inquire();
    }
	this.getMenuItems = function(){
		return _items;
	}
	this.on = function(event,listener){
		_emitter.on(event,listener);
	}
	this.onOpen = function(){
        _app.getMenu().update();
		if(_client){
			_client.send("connected",{connected:true})
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
    _btSerial.on('found', function(address, name) {
        _btSerial.findSerialPortChannel(address, function(channel) {
            name = name+"("+address+")";
            var item = new MenuItem({
                name:address,
                label:name,
                checked:self.isConnected(address),
                type:'checkbox',
                click:function(item,focusedWindow){
                    self.connect(item.name);
                }
            })
            _items.push(item);
            _devices[address] = {label:name,address:address,channel:channel};
            _app.getLocalStorage().setCookie("devices",_devices);
			_app.getMenu().update();
        }, function() {
            console.log('found nothing');
        });
    });
     _btSerial.on('finished',function(){
         console.log("discover finished");
     })
    _btSerial.on('data', function(data) {
        self.onReceived(data);
    });
    _btSerial.on('closed', function() {
        self.onDisconnect();
    });
    _btSerial.on('error',function(err){
        console.log(err);
    })
    this.clear = function(){
        _app.getLocalStorage().setCookie("devices",{});
        _items = [];
        _app.getMenu().update();
    }
    //获取上次蓝牙设备缓存清单
    _app.getLocalStorage().getCookie("devices",function(data){
        if(data){
        _devices = data;
        _items = [];
        for(var i in _devices){
            var device = _devices[i];
            var item = new MenuItem({
                name:device.address,
                label:device.label,
                checked:self.isConnected(device.address),
                type:'checkbox',
                click:function(item,focusedWindow){
                    self.connect(item.name);
                }
            })
            _items.push(item);
        }
        _app.getMenu().update();
        }
    });
}
module.exports = Bluetooth;