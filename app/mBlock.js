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

const Serial = require("./serial.js")
const Boards = require("./boards.js");
const Project = require("./project.js");
const AppMenu = require('./menu.js')
const Translator = require("./translator.js")
const Stage = require("./stage.js")
const HID = require("./hid.js");
const FirmwareUploader = require('./firmwareUploader.js');
const ArduinoIDE = require('./arduinoIDE.js');
var _project,_menu,_serial,_hid,_translator,_stage,_firmwareUploader, _arduinoIDE;
function mBlock(){
	var self = this;
	ipcMain.on('flashReady',function(event,arg){
		console.log("ready")
		_client = event.sender;
		_project = new Project(self);
		_translator = new Translator(self);
		_serial = new Serial(self);
		_boards = new Boards(self);
		_stage = new Stage(self);
		_hid = new HID(self);
		_firmwareUploader = FirmwareUploader.init(self);
		_arduinoIDE = ArduinoIDE.init(self);
		_menu = new AppMenu(self);
		
		self.init();
		_boards.selectBoard("me/auriga_mega2560");
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
	});
	ipcMain.on('openArduinoIDE', function(event, code) {
		_arduinoIDE.openArduinoIDE(code);
	});
	ipcMain.on('uploadToArduino', function(event, code) {
		_arduinoIDE.uploadCodeToBoard(code);
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
	this.getSerial = function(){
		return _serial;
	}
	this.getHID = function(){
		return _hid;
	}
	this.getName = function(){
		return app.getName()
	}
	this.getLocale = function(){
		return app.getLocale();
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
		_serial.on("list",function(){
			_menu.update();
		});
		_serial.update();
	}

	this.alert = function(message) {
		this.getClient().send('alertBox', 'show', message);
	}
	this.logToArduinoConsole = function(message) {
		this.getClient().send('logToArduinoConsole', message);
	}
}

module.exports = mBlock;