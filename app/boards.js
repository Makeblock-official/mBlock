var currentBoardName;
var client;
exports.init = function(conn){
    client = conn;
}
exports.selectBoard = function(name){
    currentBoardName = name;
    if(client){
	    client.send("data",{method:"changeToBoard",board:name})
    }
}
exports.selected = function(name){
    return currentBoardName == name;
}