var _currentBoardName;
var _client,_app;
function Boards(app){
    _app = app;
    _client = _app.getClient();
    this.selectBoard = function(name){
        _currentBoardName = name;
        if(_client){
            _client.send("data",{method:"changeToBoard",board:name})
        }
    }
    this.selected = function(name){
        return _currentBoardName == name;
    }
}
module.exports = Boards;