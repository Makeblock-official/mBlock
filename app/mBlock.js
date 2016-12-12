const {ipcMain,dialog,BrowserWindow,MenuItem,Menu,app} = require('electron')

const Serial = require("./serial.js")
const Boards = require("./boards.js");
const Project = require("./project.js");
const AppMenu = require('./menu.js')
const Translator = require("./translator.js")

var _project,_menu,_serial,_translator,_this;

function mBlock(){
	_this = this;
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
	this.getName = function(){
		return app.getName()
	}
	this.getLocale = function(){
		return app.getLocale();
	}
	this.updateMenu = function(){
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
	_project = new Project(_this);
	_translator = new Translator(_this);
	_serial = new Serial(_this);
	_boards = new Boards(_this);
	_menu = new AppMenu(_this)
	_boards.selectBoard("me/auriga_mega2560");
	_this.init();
}

module.exports = mBlock;