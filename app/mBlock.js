/**
 * mBlock 	// 实现与web通讯
 * 		|----menu.js  		//菜单:构造、刷新
 * 		|----project.js		//项目文件：创建、保存、加载
 * 		|----translator.js  //多国语言
 * 		|----boards.js		//控制板
 * 		|----serial.js		//USB串口通讯
 * 		|----hid.js			//无线2.4G串口通讯
 * 		|----autoupdater.js	//自动更新
 */
const {ipcMain,dialog,BrowserWindow,MenuItem,Menu,app} = require('electron')

const path = require('path');
const Serial = require("./serial.js")
const Boards = require("./boards.js");
const Project = require("./project.js");
const AppMenu = require('./menu.js')
const Bluetooth = require('./bluetooth.js')
const Translator = require("./translator.js")
const FontSize = require("./fontSize.js");
const Stage = require("./stage.js")
const HID = require("./hid.js");
const LocalStorage = require("./localStorage.js");
const FirmwareUploader = require('./firmwareUploader.js');
const ArduinoIDE = require('./arduinoIDE.js');
const Emotions = require('./emotions.js');
var _project,_menu,_serial,_hid,_translator,_fontSize,_stage,_firmwareUploader,_bluetooth,_localStorage,_arduinoIDE,_emotions;
function mBlock(){
	var self = this;
	ipcMain.on('flashReady',function(event,arg){
		console.log("ready")
		_client = event.sender;
		_localStorage = new LocalStorage();
		_project = new Project(self);
		_translator = new Translator(self);
		_fontSize = new FontSize(self);
		_serial = new Serial(self);
		_boards = new Boards(self);
		_stage = new Stage(self);
		_hid = new HID(self);
		_bluetooth = new Bluetooth(self);
		_firmwareUploader = FirmwareUploader.init(self);
		_arduinoIDE = ArduinoIDE.init(self);
		_menu = new AppMenu(self);
        _emotions = new Emotions(self);
		
		self.init();
		_boards.selectBoard("me/mbot_uno");
	})
	ipcMain.on('saveProject',function(event,arg){
		_project.saveProject(arg.title,arg.data);
	});
	ipcMain.on('fullscreen',function(event,arg){
		var win = BrowserWindow.getFocusedWindow();
		win.setFullScreen(arg);
	})
	ipcMain.on('package',function(event,arg){
		if(_serial.isConnected()){
			_serial.send(arg.data);
		}
		if(_hid.isConnected()){
			_hid.send(arg.data);
		}
		if(_bluetooth.isConnected()){
			_bluetooth.send(arg.data);
		}
		self.logToArduinoConsole(arg.data);
	});
	ipcMain.on('connectionStatus',function(event,obj){
		_menu.updateConnectionStatus(obj);
	})
	ipcMain.on('updateMenuStatus',function(event,arr){
		for (i=0;i< arr.length;i++){
			if(arr[i] == "small stage layout")
			{
				_stage.changeStageMode(arr[i]);
			}
		}
	})
	ipcMain.on('openArduinoIDE', function(event, code) {
		_arduinoIDE.openArduinoIDE(code);
	});
	ipcMain.on('uploadToArduino', function(event, code) {
		_arduinoIDE.uploadCodeToBoard(code);
	});
	ipcMain.on('changeArduinoStageMode', function(event, bool) {
		_stage.onlyChangeArduinoStageMode(bool);
	});
	ipcMain.on('itemDeleted', function(event, arg) {
		_menu.enableUnDelete();
	});
    // 保存收藏表情面板文件
    ipcMain.on('saveDrawFile', function (event, arg) {
		_emotions.save(arg.filename, arg.data);
    });
    // 删除表情面板文件
	ipcMain.on('deleteDrawFile', function (event, arg) {
		_emotions.del(arg.filename);
    });
	// 读取表情面板文件
	ipcMain.on('readDrawFile', function (event, arg) {
        event.sender.send('responseEmotions', {code:'single', data: _emotions.read(arg.filename)});
    });
	ipcMain.on('getDirectoryListing', function (event, arg) {
        event.sender.send('responseEmotions', {code:'more', data: _emotions.list()});
    });
	this.getClient = function(){
		return _client;
	}
	this.getProject = function(){
		return _project;
	}
	this.getTranslator = function(){
		return _translator;
	}
	this.getFontSize = function(){
		return _fontSize;
	}
	this.getSerial = function(){
		return _serial;
	}
	this.getHID = function(){
		return _hid;
	}
	this.getLocalStorage = function(){
		return _localStorage;
	}
	this.getName = function(){
		return app.getName()
	}
	this.getLocale = function(){
		return app.getLocale();
	}
	this.getBluetooth = function(){
		return _bluetooth;
	}
	this.getMenu = function(){
		return _menu;
	}
	this.getStage = function(){
		return _stage;
	}
	this.getBoards = function() {
		return _boards;
	}
	this.getFirmwareUploader = function() {
		return _firmwareUploader;
	}
	this.quit = function(){
        this.allDisconnect();
	}
	this.init = function(){
		_menu.on("newProject",function (){
			_project.newProject();
		});
		_menu.on("saveProject",function (){
			_project.saveAs(false);
		});
		_menu.on("saveProjectAs",function (){
			_project.saveAs(true);
		});
		_menu.on("openURL",function(url){
			require('electron').shell.openExternal(url)
		});
		_menu.on("boardChanged",function(name){
			_boards.selectBoard(name);
		});
		_menu.on("upgradeFirmware",function(url){
			_firmwareUploader.upgradeFirmware();
		});
		_menu.on("resetDefaultProgram",function(url){
			_firmwareUploader.resetDefaultProgram();
		});
		// _serial.on("list",function(){
		// 	_menu.update();
		// });

		_serial.update();
	}

	this.alert = function(message) {
		this.getClient().send('alertBox', 'show', message);
	};
	this.logToArduinoConsole = function(message) {
		this.getClient().send('logToArduinoConsole', message);
	};
	this.allDisconnect = function () { // 断开所有的连接，
        if (typeof(_bluetooth) != 'undefined') { // 防止flash还没有加载完用户就点击了关闭按钮
			_bluetooth.close();
		}
		if (typeof(_hid) != 'undefined') { // 防止flash还没有加载完用户就点击了关闭按钮
			_hid.close();
		}
        if (typeof(_serial) != 'undefined') { // 防止flash还没有加载完用户就点击了关闭按钮
			_serial.close();
		}
	};
}

module.exports = mBlock;