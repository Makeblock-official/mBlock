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
		//flash当前已有逻辑：
		// 1.勾选或者取消 隐藏模式时，同时取消小舞台模式
		// 2.勾选或者取消 小舞台模式时，如果当前是隐藏模式，则取消隐形模式和取消小舞台模式
		// 3.arduino mode 取消时，同时取消小舞台和隐藏模式， arduino mode 勾选时，同时勾选小舞台和隐藏模式

		_stageMode[name] = !_stageMode[name];
		if(name=="arduino mode"){
			if(_stageMode[name] == false){
				//取消勾选
				_stageMode["hide stage layout"] = false;
				_stageMode["small stage layout"] = false;

			}else{
				//勾选
				_stageMode["hide stage layout"] = true;
				_stageMode["small stage layout"] = false;
			}
			_client.send("changeStageMode",{name:name});

		}else if(name=="small stage layout"){

			if (_stageMode["hide stage layout"]){
				//如果当前为隐藏模式，则取消隐藏模式，什么也不做
				//(取消隐藏模式时，需要一起取消 arduino mode)
				if (_stageMode['arduino mode']){
					_client.send("changeStageMode",{name:"arduino mode"}); //取消arduino mode 是，隐藏模式和小舞台模式也会一并取消
					_stageMode["arduino mode"] = false;
					_stageMode["hide stage layout"] = false;
					_stageMode[name] = false;
				}else{
					_client.send("changeStageMode",{name:"small stage layout"});
					_stageMode["hide stage layout"] = false;
					_stageMode[name] = false;
				}
			}else{
				_client.send("changeStageMode",{name:"small stage layout"});
			}


		}else if(name=="hide stage layout") {


			if (_stageMode['arduino mode']) {
				_client.send("changeStageMode", {name: "arduino mode"}); //取消arduino mode 是，隐藏模式和小舞台模式也会一并取消
				_stageMode["arduino mode"] = false;
				_stageMode["hide stage layout"] = false;
				_stageMode['small stage layout'] = false;
			}else{
				_client.send("changeStageMode", {name: "hide stage layout"});
				_stageMode["small stage layout"] = false;
			}

		}
		_app.getMenu().update();
	}
	this.onlyChangeArduinoStageMode = function(bool){
		_stageMode["arduino mode"] = bool;
		_app.getMenu().update();
	}
}
module.exports = Stage;