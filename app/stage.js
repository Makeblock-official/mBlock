/**
 * 舞台状态管理：对应菜单->编辑
 */
var _app,_client,_menu;
var _isArduinoMode = false;
var _stageMode = {};
function Stage(app){
    var self = this;
    _app = app;
    _client = _app.getClient();
	this.isStageMode = function(name){
		if(_stageMode[name]==undefined){
			_stageMode[name] = false;
		}
		return _stageMode[name];
	}
    this.undelete = function(){
        _client.send("changeStageMode",{name:"undelete"});
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
			_client.send("changeStageMode",{name:"small stage layout"});
			_stageMode["small stage layout"] = false;
		}
		_client.send("changeStageMode",{name:name});
		_app.getMenu().update();
	}
	this.onlyChangeArduinoStageMode = function(bool){
		_stageMode["arduino mode"] = bool;
		_app.getMenu().update();
	}
}
module.exports = Stage;