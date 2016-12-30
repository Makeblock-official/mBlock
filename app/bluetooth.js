/**
 * 蓝牙串口通讯
 */
const {MenuItem} = require("electron")
const SPP = require('bluetooth-serial-port');
const events = require('events');
var _emitter = new events.EventEmitter();  
var _btSerial,_app,_client,_items=[];
var _devices = {}; // 缓存中[Cookie]的蓝牙设备
var _currentBluetooth = ""
var bluetoothDevicesFoundNumber = 0;	// 已找到多少个蓝牙设备
var bluetoothDevicesChannelProcessedNumber = 0;			// bluetoothDevicesChannelProcessed 已获取多少个蓝牙设备的频道
//var _isQuit = false; // 是否前台退出
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
    this.connect = function(name){ // 连接蓝牙
        _currentBluetooth = name;
        var device = _devices[name];
        _btSerial.connect(device.address, device.channel, function() {
            self.onOpen();
 
        }, function () {
            console.log('cannot connect');
        });
    }
    this.close = function () { // 此方法作废
		_btSerial.close();
    };
    this.send = function(data){
        _btSerial.write(new Buffer(data), function(err, bytesWritten) {
            if (err) console.log(err);
        });
    }
    this.discover = function(item){ // 发现蓝牙
        _items = [];
        _devices = {};
		// 禁掉"发现"按钮
		item.enabled = false;
		//_btSerial.inquireSync();
		_btSerial.inquire(); // 异步
		//console.log(_btSerial.inq);
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
	this.onDisconnect = function(){ // 断开连接 close the connection when you're ready
        _currentBluetooth = '';
        _app.getMenu().update();
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
	
    _btSerial.on('found', function(address, name) { // 已找到蓝牙设备
	    // name : 蓝牙名称； address ： 蓝牙物理地址
		console.log('已找到蓝牙:'+name+"("+address+")");
		bluetoothDevicesFoundNumber++;
		
        _btSerial.findSerialPortChannel(address, function(channel) { // 找到多少个蓝牙，就是循环多少次
            name = name+"("+address+")";
            var item = new MenuItem({
                name:address,
                label:name,
                checked:self.isConnected(address),
                type:'checkbox',
                click:function(item,focusedWindow){
					var isConnect = false;console.log(item.name);console.log(_currentBluetooth);console.log('-----');
					if (item.name != _currentBluetooth) {
						isConnect = true;
					}
					// 先断开之前的蓝牙连接，重新进行连接
					_btSerial.close(); 
					if (isConnect) {
						console.log('进行连接...');
						self.connect(item.name);
					}
                }
            })
            _items.push(item);
            _devices[address] = {label:name,address:address,channel:channel};
            _app.getLocalStorage().setCookie("devices",_devices);
			bluetoothDevicesChannelProcessedNumber++;
			if (bluetoothDevicesChannelProcessedNumber == bluetoothDevicesFoundNumber) {
				_app.getMenu().update(); // 更新菜单
				bluetoothDevicesFoundNumber = 0;
				bluetoothDevicesChannelProcessedNumber = 0;
			}
        }, function() {
			bluetoothDevicesChannelProcessedNumber++;
			if (bluetoothDevicesChannelProcessedNumber == bluetoothDevicesFoundNumber) {
				_app.getMenu().update(); // 更新菜单
				bluetoothDevicesFoundNumber = 0;
				bluetoothDevicesChannelProcessedNumber = 0;
			}
            console.log('can\'t found channel');
        });
    });
     _btSerial.on('finished',function(){ // 已经找完，接下来会调用findSerialPortChannel
		 //console.log("discover finished,inquiry finished");
     })
	 
    _btSerial.on('data', function(data) {
        self.onReceived(data);
    });
    _btSerial.on('closed', function() { // 当蓝牙主动断开时或蓝牙已拔出时，会调用此方法
		console.log('closed-----------');
        self.onDisconnect();
    });
    _btSerial.on('error',function(err){
        console.log('蓝牙连接发生错误了：');
		console.log(err);
    })
	/*_btSerial.on('close', function() {
        console.log('蓝牙连接已关闭--------');
		self.onDisconnect();
    });*/
	_btSerial.on('listPairedDevices', function () {
	    console.log('followed to listPairedDevices function');
    });
    this.clear = function() {
        _app.getLocalStorage().setCookie("devices",{});
		_items = [];
		_btSerial.close(); // 断开蓝牙连接
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