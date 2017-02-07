/**
 * 蓝牙串口通讯
 * @author Bear
 */
const {MenuItem} = require("electron");
const events = require('events');
const childProcess = require('child_process'); // 子进程
var _emitter = new events.EventEmitter();  
var _app,_client,_items=[];
var _devices = {}; // 缓存中[Cookie]的蓝牙设备
var _currentBluetooth = '';
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
	
    this.close = function (isUpdateMenu) { // 断开蓝牙连接
	    _currentBluetooth = '';
		if (typeof(isUpdateMenu) == 'undefined') {
			isUpdateMenu = true;
		}
        if (typeof(bluetoothChildProcess) != 'undefined') {
			self.onDisconnect();
		}
		if (isUpdateMenu) {
			self.updateMenu(); // 需要更新菜单
		}
    };
	
    this.send = function(data){ // 向蓝牙发送数据
        bluetoothChildProcess.send({'method':'writeData', 'data':data});
    };
	
	this.foundBluetooth = function (device) { // 找到一个蓝牙设备
        _devices[device.address] = {
			'label'   : device.label,
			'address' : device.address,
			'channel' : device.channel
		};
        _app.getLocalStorage().setCookie('bluetoothDevices', _devices);
	};
	
	this.createBluetoothChildProcess = function () { // 创建蓝牙子进程，并托管各消息处理函数
	    var childProcessPath = __dirname + '/bluetoothChildProcess.js';
		bluetoothChildProcess = childProcess.fork(childProcessPath);
		// 监控所有子进程过来的消息
		bluetoothChildProcess.on('message', function (message) {
			if (message.method == 'noBluetoothDevices') { // 周围未找到任何蓝牙设备或最后一个蓝牙设备未找到通道
                self.updateMenu(); // 更新菜单
				if (message.isAlertMessage) {
					_client.send('alertBox', 'show', _translator.map('No Bluetooth devices found around it!'));
					//_app.alert(_translator.map('No Bluetooth devices found around it!'));
				}
				// 关闭子进程
				self.killBluetoothChildProcess();
			} else if (message.method == 'foundBluetooth') { // 找到一个蓝牙设备
				self.foundBluetooth(message.device);
			} else if (message.method == 'finishedBluetooth') { // 已完成蓝牙设备的查找
				self.updateMenu(); // 更新菜单
				// 关闭子进程
				self.killBluetoothChildProcess();
			} else if (message.method == 'receivedData') { // 接收数据
				self.onReceived(message.data);
			} else if (message.method == 'onConnected') { // 进行了连接蓝牙
				if (message.isConnected) { // 已连接成功
					self.onOpen(message.address);
				} else { // 未连接成功
					self.onDisconnect();
					_currentBluetooth = '';
					self.updateMenu();
				}
			}
		});
        bluetoothChildProcess.on('exit', function (code) { // 不为0时，为异常退出
		});
	};
	
	this.killBluetoothChildProcess = function () { // 杀死子进程
        bluetoothChildProcess.kill('SIGKILL');
	};
	
    this.discover = function(item){ // 发现蓝牙
        _items = [];
        _devices = {};
		self.close(false); // 一定要断开蓝牙连接
        self.createBluetoothChildProcess();
        bluetoothChildProcess.send({'method':'inquire'});
    };
	
	this.getMenuItems = function(){
		return _items;
	};
	
	this.on = function(event,listener){
		_emitter.on(event,listener);
	};
	
	this.onOpen = function(address){ // 蓝牙已连接
		_currentBluetooth = address;
		self.updateMenu();
		if(_client){
			_client.send("connected",{connected:true});
		}
	};
	
	this.onDisconnect = function(){ // 断开连接 close the connection when you're ready
	    self.killBluetoothChildProcess();
		if(_client){
			try {
				_client.send("connected",{connected:false});
			} catch (e) {
				// when the program is shutting down, front-end web page
				// no longer exists; in this case, ignore the 
				// "Object has been destroyed" Exception.
			}
		}
	};
	
	this.onReceived = function(data){ // 接受蓝牙数据
		if(_client){
			_client.send("package",{data:data})
		}
	};
	
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
