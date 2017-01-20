/**
 * 蓝牙串口通讯
 */
 
/*var btSerial = new (require('bluetooth-serial-port')).BluetoothSerialPort();
 
btSerial.on('found', function(address, name) {
    btSerial.findSerialPortChannel(address, function(channel) {
        btSerial.connect(address, channel, function() {
            console.log('connected');
 
            btSerial.write(new Buffer('my data', 'utf-8'), function(err, bytesWritten) {
                if (err) console.log(err);
            });
 
            btSerial.on('data', function(buffer) {
                console.log(buffer.toString('utf-8'));
            });
        }, function () {
            console.log('cannot connect');
        });
 
        // close the connection when you're ready 
        btSerial.close();
    }, function() {
        console.log('found nothing');
    });
});
 
btSerial.inquire();*/
 
const {MenuItem} = require("electron")
//const SPP = require('bluetooth-serial-port');
const events = require('events');
var _emitter = new events.EventEmitter();  
var _app,_client,_items=[];
var _devices = {}; // 缓存中[Cookie]的蓝牙设备
var _currentBluetooth = '';



const childProcess = require('child_process'); // 子进程
var bluetoothChildProcess; // 蓝牙子进程



function Bluetooth(app){
    var self = this;
    _app = app;
	_client = _app.getClient();
	var _translator = _app.getTranslator(); // 多语言类
	

	
    /**
     * 是否已连接
     */
	this.isConnected = function(name){
		if (typeof(bluetoothChildProcess) == 'undefined') {
			return false;
		} else if (_currentBluetooth == '') {
			return false;
		} else {
		    return !(bluetoothChildProcess.killed);
		}
	};
	
    this.connect = function(name) { // 连接蓝牙
        self.createBluetoothChildProcess();
		var device = {
			'address'  : _devices[name].address,
			'channel'  : _devices[name].channel
		};
		bluetoothChildProcess.send({'method':'connect', 'device':device}); 
    };
	
    this.close = function () { // 断开蓝牙连接
	    _currentBluetooth = '';
        if (typeof(bluetoothChildProcess) != 'undefined') {
            self.killBluetoothChildProcess();
			self.onDisconnect();
		} else {
            self.updateMenu(); // 需要更新菜单
		}
    };
    this.send = function(data){ // 向蓝牙发送数据
        bluetoothChildProcess.send({'method':'writeData', 'data':data});
    }
	this.foundBluetooth = function (device) { // 找到一个蓝牙设备
        _devices[device.address] = {
			'label'   : device.label,
			'address' : device.address,
			'channel' : device.channel
		};
        _app.getLocalStorage().setCookie('bluetoothDevices', _devices);
	};
	this.createBluetoothChildProcess = function () {
		bluetoothChildProcess = childProcess.fork(__root_path + '/app/bluetoothChildProcess.js');
		// 监控所有子进程过来的消息
		bluetoothChildProcess.on('message', function (message) { // (m,cor) => {}
			console.log(`from worker[child process] message:`);
			console.log(message);
			if (message.method == 'noBluetoothDevices') { // 周围未找到任何蓝牙设备或最后一个蓝牙设备未找到通道
                self.updateMenu(); // 更新菜单
				if (message.isAlertMessage) {
					_client.send('alertBox', 'show', _translator.map('No Bluetooth devices found around it!'));
					//_app.alert(_translator.map('No Bluetooth devices found around it!'));
				}
				// 关闭子进程
				self.killBluetoothChildProcess();
				console.log('周围未找到任何蓝牙设备或最后一个蓝牙设备未找到通道,且已更新菜单');
			} else if (message.method == 'foundBluetooth') { // 找到一个蓝牙设备
				self.foundBluetooth(message.device);
			} else if (message.method == 'finishedBluetooth') { // 已完成蓝牙设备的查找
			    console.log('已完成蓝牙设备的查找，准备更新菜单');
				self.updateMenu(); // 更新菜单
				// 关闭子进程
				self.killBluetoothChildProcess();
			} else if (message.method == 'receivedData') { // 接收数据
				self.onReceived(message.data);
			} else if (message.method == 'onConnected') { // 进行了连接蓝牙
				if (message.isConnected) { // 已连接成功
					self.onOpen(message.address);
				}
				self.updateMenu();console.log('已进行过连接，且已更新菜单');
			}
		});
        bluetoothChildProcess.on('exit', function (code) { // 不为0时，为异常退出
		    console.log('蓝牙子进程已经退出。退出code：');
			console.log(code);
			//bluetoothChildProcess = null;
		});
	};
	this.killBluetoothChildProcess = function () { // 杀死子进程
	console.log(bluetoothChildProcess);
        bluetoothChildProcess.kill();
		childProcess.spawn('kill', ['-9', bluetoothChildProcess.pid]);
		console.log('已杀死子进程');
	};
    this.discover = function(item){ // 发现蓝牙
        _items = [];
        _devices = {};
		self.close(); // 断开蓝牙连接
		//var arduinoProcess = spawn(this.getArduinoExecutable(), arduinoCommandArguments);
        self.createBluetoothChildProcess();
        bluetoothChildProcess.send({'method':'inquire'});

		
		/*try {
            //self.initBluetoothSerialPort();
            
		} catch (e) { // 如果linux没有蓝牙设备，“发现”蓝牙时程序会直接关闭，并且不抛任何异常（貌似内存溢出）
			console.log('发现蓝牙时，发生了错误：');
			console.log(e);
		}*/
    }
	this.getMenuItems = function(){
		return _items;
	}
	this.on = function(event,listener){
		_emitter.on(event,listener);
	}
	this.onOpen = function(address){
		_currentBluetooth = address;
		if(_client){
			_client.send("connected",{connected:true});
		}
	}
	this.onDisconnect = function(){ // 断开连接 close the connection when you're ready
        self.updateMenu();
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
        _app.getLocalStorage().setCookie('bluetoothDevices', {});
		_items = [];
        _devices = {};
        self.close(); // 断开蓝牙连接
    };
	
	/**
	 * 单击蓝牙，进行连接
	 */
    this.clickEventConnecting = function(item, focusedWindow) {
		var isConnect = false;
		if (item.name != _currentBluetooth) {
			isConnect = true;
		}
		// 先断开之前的蓝牙连接，重新进行连接
		_app.allDisconnect();
		if (isConnect) {
			setTimeout(function () {self.connect(item.name);}, 1500);
		}
	};
	
	/**
	 * 更新菜单
	 */
    this.updateMenu = function () {
        _items = [];
		for(var i in _devices){
			var menuItem = new MenuItem({
			    'name'    : _devices[i].address,
				'label'   : _devices[i].label,
				'checked' : self.isConnected(_devices[i].address),
				'type'    : 'checkbox',
				'click'   : self.clickEventConnecting
			});
			_items.push(menuItem);
		}
        _app.getMenu().update();
	};

    _app.getLocalStorage().getCookie('bluetoothDevices', function(data){ //获取上次蓝牙设备缓存清单
        if(data){
            _devices = data;
            self.updateMenu();
        }
    });
    
	
}
module.exports = Bluetooth;
