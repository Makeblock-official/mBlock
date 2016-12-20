const {ipcMain,dialog,BrowserWindow,MenuItem,Menu,app} = require('electron')

const Serial = require("./serial.js")
const Boards = require("./boards.js");
const Project = require("./project.js");
const AppMenu = require('./menu.js')
const Translator = require("./translator.js")
const HID = require("./hid.js");
var _project,_menu,_serial,_hid,_translator,self;
var _isArduinoMode = false;
var _stageMode = {};
function mBlock(){
	self = this;
	ipcMain.on('flashReady',function(event,arg){
		console.log("ready")
		onFlashReady(event.sender);
	})
	ipcMain.on('save',function(event,arg){
		_project.saveProject(arg.title,arg.data);
	});
	ipcMain.on('fullscreen',function(event,arg){
		var win = BrowserWindow.getFocusedWindow();
		win.setFullScreen(arg);
	})
	ipcMain.on('command',function(event,arg){
		if(arg.buffer){
			Serial.send(arg.buffer);
		}
	})
	this.getClient = function(){
		return _client;
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
	this.updateMenu = function(){
		_menu.update();
	}
	this.isStageMode = function(name){
		if(_stageMode[name]==undefined){
			_stageMode[name] = false;
		}
		return _stageMode[name];
	}
	this.changeStageMode = function(name){
		_stageMode[name] = !_stageMode[name];
		if(name=="arduino mode"){
			if(_stageMode[name] == false){
				_stageMode["hide stage layout"] = false;	
			}else{
				_stageMode["hide stage layout"] = true;	
			}
			_stageMode["small stage layout"] = false;
		}else if(name=="small stage layout"){
			if(_stageMode["hide stage layout"]&&!_stageMode["arduino mode"]){
				_client.send("changeStageMode",{name:"hide stage layout"});
			}else if(_stageMode["arduino mode"]&&_stageMode["small stage layout"]){
				_client.send("changeStageMode",{name:"arduino mode"});
				_stageMode["arduino mode"] = false;
			}
			_stageMode["hide stage layout"] = false;
		}else if(name=="hide stage layout"){
			_stageMode["small stage layout"] = false;
		}
		_client.send("changeStageMode",{name:name});
		_menu.update();
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
		_serial.on("list",function(){
			_menu.update();
		});
		_serial.update();
	}
}

function onFlashReady(client){
	_client = client;
	_project = new Project(self);
	_translator = new Translator(self);
	_serial = new Serial(self);
	_boards = new Boards(self);
	_menu = new AppMenu(self)
	_hid = new HID(self);
	self.init();

	_boards.selectBoard("me/auriga_mega2560");
}

module.exports = mBlock;