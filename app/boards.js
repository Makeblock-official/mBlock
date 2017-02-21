/**
 * 控制板管理：主控板选择、主控板选中状态
 */
var _currentBoardName;
var _client,_app;
function Boards(app){
    var self = this;
    _app = app;
    _client = _app.getClient();
    
    //切换主控板，通过ipc向flash发送切换主控板的请求
    this.selectBoard = function(name){console.log('++++++++++');console.log(name);console.log('++++++++++');
        _currentBoardName = name;
        if(_client){
            _client.send("changeToBoard",{board:name})
        }
        _app.getMenu().update();
    }

    //判断名称是否当前主控板
    this.selected = function(name){
        return _currentBoardName == name;
    }
    this.currentBoardName = function() {
        return _currentBoardName;
    };
	// 设置当前的主控板
    this.setCurrentBoardName = function (currentBoardName) {
        _currentBoardName = currentBoardName;
        _app.getMenu().update();
	};
    //auriga指令集
    this.aurigaInstructions = {
        bluetooth_mode: [0xff, 0x55, 0x05, 0x00, 0x02, 0x3c, 0x11, 0x00],
        ultrasonic_mode: [0xff, 0x55, 0x05, 0x00, 0x02, 0x3c, 0x11, 0x01],
        line_follower_mode: [0xff, 0x55, 0x05, 0x00, 0x02, 0x3c, 0x11, 0x04],
        balance_mode: [0xff, 0x55, 0x05, 0x00, 0x02, 0x3c, 0x11, 0x02]
    }
}

module.exports = Boards;