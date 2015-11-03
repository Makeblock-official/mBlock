package extensions
{
	import util.LogManager;
	import util.SharedObjectManager;

	public class DeviceManager
	{
		private static var _instance:DeviceManager;
		private var _device:String = "";
		private var _board:String = "";
		private var _name:String = "";
		public function DeviceManager()
		{
			onSelectBoard(SharedObjectManager.sharedManager().getObject("board","mbot_uno"));
		}
		public static function sharedManager():DeviceManager{
			if(_instance==null){
				_instance = new DeviceManager;
			}
			return _instance;
		}
		private function set board(value:String):void
		{
			_board = value;
			var tempList:Array = _board.split("_");
			_device = tempList[tempList.length-1];
		}
		public function onSelectBoard(value:String):void{
			if(_board == value){
				return;
			}
			this.board = value;
			var oldBoard:String = SharedObjectManager.sharedManager().getObject("board");
			SharedObjectManager.sharedManager().setObject("board",_board);
			if(_board=="picoboard_unknown"){
				MBlock.app.extensionManager.singleSelectExtension("PicoBoard");
			}else{
				if(_board=="mbot_uno"){
					MBlock.app.extensionManager.singleSelectExtension("mBot");
				}else if(_board.indexOf("arduino")>-1){
					MBlock.app.extensionManager.singleSelectExtension("Arduino");
				}else if(_board.indexOf("me/orion_uno")>-1){
					if(oldBoard.indexOf("me/orion_uno") < 0){
						MBlock.app.openOrion();
					}
					MBlock.app.extensionManager.singleSelectExtension("Makeblock");
				}else if(_board.indexOf("me/baseboard")>-1){
					MBlock.app.extensionManager.singleSelectExtension("BaseBoard");
				}else if(_board.indexOf("me/uno_shield")>-1){
					MBlock.app.extensionManager.singleSelectExtension("UNO Shield");
				}else{
					MBlock.app.extensionManager.singleSelectExtension("PicoBoard");
				}
			}
			MBlock.app.topBarPart.setBoardTitle();
		}
		public function checkCurrentBoard(board:String):Boolean{
			return _board==board;
		}
		public function get currentName():String{
			_name = "";
			if(_board.indexOf("mbot")>-1){
				_name = "mBot";
			}else if(_board.indexOf("orion")>-1){
				_name = "Me Orion";
			}else if(_board.indexOf("baseboard")>-1){
				_name = "Me Baseboard";
			}else if(_board.indexOf("arduino")>-1){
				_name = "Arduino "+_device.substr(0,1).toLocaleUpperCase()+_device.substr(1,_device.length);
			}else if(_board.indexOf("picoboard")>-1){
				_name = "PicoBoard";
			}else if(_board.indexOf("shield") > -1){
				_name = "UNO Shield";
			}
			return _name;
		}
		public function get currentBoard():String{
			LogManager.sharedManager().log("currentBoard:"+_board);
			return _board;
		}
		public function get currentDevice():String{
			return _device;
		}
	}
}