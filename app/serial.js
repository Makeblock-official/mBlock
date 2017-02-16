/**
 * USB串口通讯
 * zhangkun
 */
const {MenuItem} = require("electron")
const SerialPort = require("serialport");
const events = require('events');
const childProcess = require('child_process');
const sudoer = require('./sudoCommands.js');
var _emitter = new events.EventEmitter();  
var _currentSerialPort=""
var serialChild, _isopen, opening;
var _client,_app,_items=[];
function Serial(app){
	_app = app;
	var self = this;
	var _translator = app.getTranslator();
    var childProcessPath = __dirname + '/serialChild.js';
	_client = _app.getClient();
    _isopen = false;
	// 需要即时返回，不能有时序
	this.list = function(callback) {
        SerialPort.list(callback);
	}
	this.currentSerialPort = function() { return _currentSerialPort; }

	// 需要即时返回，不能有时序
	this.isConnected = function(name){
        if(name){
            return _currentSerialPort==name&&_isopen;
        }else{
            return _currentSerialPort!=""&&_isopen;
        }
	}
	this.close = function(){
        this.killChildProcess();
        self.onConnecting();
	}
	this.send = function(data){
        if (serialChild && serialChild.connected) {
            serialChild.send({func: 'write()', data: data, port: _currentSerialPort});
        }
	}
    /**
	 * 创建串口子进程伴随着看门狗检查串口状态
     */
	this.createChildProcess = function () {
		serialChild = childProcess.fork(childProcessPath);
        serialChild.on('message', function (rtn) {
			if (typeof(rtn.isopen) != "undefined") {
				if (_isopen != rtn.isopen) {
                    _isopen = rtn.isopen;
                    self.onConnecting();
				}
			}
        });
        opening = setInterval(function() {
            if (!serialChild || !serialChild.connected) {
                clearInterval(opening);
            	return;
			}
            serialChild.send({ func: 'isOpen()', port:_currentSerialPort});
        }, 3000);
    }

    /**
	 * 杀死子进程
     * @param name
     */
    this.killChildProcess = function () {
        if (serialChild && serialChild.connected) {
            clearInterval(opening);
            serialChild.kill('SIGKILL');
        }
        _isopen = false;
        _currentSerialPort = "";
    }

    /**
	 * 更新flash及菜单状态
     */
    this.onConnecting = function(){
        // 更新菜单前，需要更新串口连接状态
        var objectConnected = {'connected':self.isConnected()};
        _app.getMenu().updateConnectionStatus(objectConnected);
        self.update();
        if(_client){
            _client.send("connected", objectConnected);
        }
    }

	this.connect = function(name){ // linux : /dev/ttyUSB0
        _app.allDisconnect();	// 链接前断开所有链接
        _currentSerialPort = name;
        setTimeout(function () {
        	self.createChildProcess();
            serialChild.on('message', function(rtn) {
                if (!rtn.method) return;
                switch (rtn.method) {
                    case 'open':
                        self.onOpen();
                        break;
                    case 'error':
                        childProcess.exec("groups `whoami`", function (error, stderr, stdout) {
                            if (error) {
                                sudoer.enableSerialInLinux(errorCallbackHander);
                                return;
                            }
                            if (stderr.indexOf('dialout ') > -1) {
                                _app.alert(_translator.map("Cannot connect to the 2.4G device. Please check your USB connection or restart your computer."));
                            } else {
                                sudoer.enableSerialInLinux(errorCallbackHander);
                            }
                        });
                        self.killChildProcess();
                        break;
                    case 'locked':
                        _app.alert(_translator.map("port is locked: ") + name);
                        self.killChildProcess();
                        break;
                    case 'data':
                        self.onReceived(rtn.data);
                        break;
                    case 'close':
                        self.onDisconnect();
                        self.killChildProcess();
                        break;
                    case 'disconnect':
                        self.onDisconnect();
                        self.killChildProcess();
                        break;
                    default:
                        break;
                }
            });

            serialChild.send({ port: name });
            var errorCallbackHander = function (error, stderr, stdout) {
                if (error == null) { // 正常流程：密码输对的情况
                    _app.alert(_translator.map("Please restart your computer to enable serial ports."));
                    //_port.open(); // 死循环，因为没有重启电脑的情况下，还是需要输入密码
                }
                self.update(); // 更新菜单
            };
        }, 1500);
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
						if (self.isConnected(item.name)){
                            self.close();
						} else {
                            self.connect(item.name);
						}
					}
				})
				_items.push(item);
			}
			_app.getMenu().update();
        });
	}
	this.on = function(event,listener){
		_emitter.on(event,listener);
	}
	this.onOpen = function(){
		// 更新菜单前，需要更新串口连接状态
		var objectConnected = {'connected':self.isConnected()};
		_app.getMenu().updateConnectionStatus(objectConnected);
        self.update();
		if(_client){
			_client.send("connected", objectConnected);
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
			// var arr=[];
			// for(var i=0;i<data.length;i++){
			// 	arr.push(data[i]);
			// }
			// _client.send("package",{data:arr});
            _client.send("package",{data:data});
		}
	}
}
module.exports = Serial;
