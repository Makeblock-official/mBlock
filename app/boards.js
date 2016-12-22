/**
 * 控制板管理：主控板选择、主控板选中状态
 */
var _currentBoardName;
var _client,_app;
function Boards(app){
    var self = this;
    _app = app;
    _client = _app.getClient();
    this.selectBoard = function(name){
        _currentBoardName = name;
        if(_client){
            _client.send("changeToBoard",{board:name})
        }
        _app.getMenu().update();
    }
    this.selected = function(name){
        return _currentBoardName == name;
    }
    this.currentBoardName = function() {
        return _currentBoardName;
    }
}

module.exports = Boards;