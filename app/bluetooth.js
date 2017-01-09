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

function Bluetooth(app){
    var self = this;
    _app = app;
	_client = _app.getClient();
	var _translator = _app.getTranslator(); // 多语言类
    _btSerial = new SPP.BluetoothSerialPort();
	//var _serialPortServer = new SPP.BluetoothSerialPortServer();

	this.isConnected = function(name){
		if(name){
			return _currentBluetooth==name&&_btSerial&&_btSerial.isOpen();
		}else{
			return _currentBluetooth!=""&&_btSerial&&_btSerial.isOpen();
		}
	}
    this.connect = function(name){ // 连接蓝牙
        _currentBluetooth = name;
        _btSerial.connect(_devices[name].address, _devices[name].channel, function() {
            self.onOpen();
        }, function (error) {
            console.log('open connect is error:');
			console.log(error);
        });
    }
    this.close = function () { // 断开蓝牙连接
        //_serialPortServer.close();
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
		try {
            _btSerial.inquire(); // 异步
		} catch (e) { // 如果linux没有蓝牙设备，“发现”蓝牙时程序会直接关闭，并且不抛任何异常（貌似内存溢出）
			console.log(e);
		}
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
			_client.send("connected",{connected:true});
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
	this.clear = function() { // 清空蓝牙列表
        _app.getLocalStorage().setCookie("devices",{});
		_items = [];
		self.close(); // 断开蓝牙连接
    };
	/**
	 * 单击蓝牙，进行连接
	 */
    this.clickEventConnecting = function(item, focusedWindow){
		var isConnect = false;
		if (item.name != _currentBluetooth) {
			isConnect = true;
		}
		// 先断开之前的蓝牙连接，重新进行连接
		_app.allDisconnect();
		if (isConnect) {
			setTimeout(function () {self.connect(item.name);}, 1000);
		}
	};
	
    _btSerial.on('found', function(address, name) { // 已找到蓝牙设备
	    // name : 蓝牙名称； address ： 蓝牙物理地址
		//console.log('已找到蓝牙:'+name+"("+address+")");
		bluetoothDevicesFoundNumber++;
		
        _btSerial.findSerialPortChannel(address, function(channel) { // 找到多少个蓝牙，就是循环多少次
            name = name+"("+address+")";
            var item = new MenuItem({
                name:address,
                label:name,
                checked:self.isConnected(address),
                type:'checkbox',
                click:self.clickEventConnecting
            })
            _items.push(item);
            _devices[address] = {label:name,address:address,channel:channel};
            _app.getLocalStorage().setCookie("devices", _devices);
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
            //console.log('can\'t found channel');
        });
    });
    _btSerial.on('finished',function(){ // 已经找完，接下来会调用findSerialPortChannel  
        if (bluetoothDevicesFoundNumber == 0) { // 周围未找到任何蓝牙设备
			_app.getMenu().update(); // 更新菜单
            //_app.alert(_translator.map('No Bluetooth devices found around it!'));
            _client.send('alertBox', 'show', _translator.map('No Bluetooth devices found around it!'));
		}
    })
    _btSerial.on('data', function(data) {
        self.onReceived(data);
    });
    _btSerial.on('closed', function() { // 当蓝牙主动断开时或蓝牙已拔出时，会调用此方法
        self.onDisconnect();
    });
    _btSerial.on('error',function(err){
        //console.log('蓝牙连接发生错误了：');
		//console.log(err);
    })
    
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
                click:self.clickEventConnecting
            })
            _items.push(item);
        }
        _app.getMenu().update();
        }
    });
}
module.exports = Bluetooth;