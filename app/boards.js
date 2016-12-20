var _currentBoardName;
var _client,_app,self;
function Boards(app){
    self = this;
    _app = app;
    _client = _app.getClient();
    this.selectBoard = function(name){
        _currentBoardName = name;
        console.log(name);
        if(_client){
            _client.send("changeToBoard",{board:name})
        }
        _app.updateMenu();
    }
    this.selected = function(name){
        return _currentBoardName == name;
    }
}
module.exports = Boards;