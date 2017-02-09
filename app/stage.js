/**
 * 舞台状态管理：对应菜单->编辑
 */
var _app, _client, _menu;
var _isArduinoMode = false;
var _stageMode = {};
function Stage(app) {
    var self = this;
    _app = app;
    _client = _app.getClient();
    this.isStageMode = function (name) {
        if (_stageMode[name] == undefined) {
            _stageMode[name] = false;
        }
        return _stageMode[name];
    }
    this.undelete = function () {
        _client.send("changeStageMode", {name: "undelete"});
    }

    this.changeStageMode = function (name) {
        if (name == 'hide stage layout')
            self.onClickHideStageLayout();
        if (name == 'arduino mode')
            self.onClickArduinoMode();
        if (name == 'small stage layout')
            self.onClickSmallStageLayout();
        if (name == 'turbo mode') {
            _stageMode[name] = !_stageMode[name];
            _client.send("changeStageMode", {name: name});
        }
        _app.getMenu().update();
    }
    this.onClickHideStageLayout = function () {
        if (_stageMode['arduino mode']) {
            //说明当前是 arduino mode，则直接执行 取消 arduino mode 即可(取消arduino时，会同时取消隐藏模式)
            self.onClickArduinoMode();
            return;
        }
        //执行切换隐藏模式逻辑
        var name = "hide stage layout";
        _client.send("changeStageMode", {name: name});
        _stageMode[name] = !_stageMode[name];
        _stageMode["small stage layout"] = false; //flash中会自动 取消小舞台模式，故此处需设置为false


    }
    this.onClickSmallStageLayout = function () {
        //flash中，如果当前为隐藏模式，这取消隐藏模式
        if (_stageMode['arduino mode']) {
            //说明当前是从 arduino mode 进行 小舞台模式，此时需要先取消 arduino mode
            self.onClickArduinoMode();
        } else if (_stageMode["hide stage layout"]) {
            //说明当前是从 隐藏模式 进入 小舞台模式，此时直接取消隐藏模式即可，不需要进入小舞台模式
            self.onClickHideStageLayout();
            return;
        }
        //执行切换小舞台模式操作
        var name = "small stage layout";
        _client.send("changeStageMode", {name: name});
        _stageMode[name] = !_stageMode[name];

    }
    this.onClickArduinoMode = function () {
        //flash切换arduino mode时，将同时设置隐藏模式 和 小舞台模式
        var name = "arduino mode";
        _client.send("changeStageMode", {name: name});
        _stageMode[name] = !_stageMode[name];
        _stageMode["hide stage layout"] = _stageMode[name];
        //_stageMode["small stage layout"] = _stageMode[name];为了和旧版本的行为保持一致，界面效果修改为下面。
        _stageMode["small stage layout"] = false;

   }
    this.onlyChangeArduinoStageMode = function (bool) {
        _stageMode["arduino mode"] = bool;
        _app.getMenu().update();
    }
}
module.exports = Stage;