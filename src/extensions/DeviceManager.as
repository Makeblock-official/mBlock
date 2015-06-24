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
			_board = SharedObjectManager.sharedManager().getObject("board","mbot_uno");
			_device = _board.split("_")[1];
		}
		public static function sharedManager():DeviceManager{
			if(_instance==null){
				_instance = new DeviceManager;
			}
			return _instance;
		}
		public function onSelectBoard(board:String):void{
			_board = board.toString();
			_device = _board.split("_")[1];
			SharedObjectManager.sharedManager().setObject("board",board);
			if(_board=="picoboard_unknown"){
				MBlock.app.extensionManager.singleSelectExtension("PicoBoard");
			}else{
				if(_board=="mbot_uno"){
					if(!MBlock.app.extensionManager.checkExtensionSelected("mBot")){
						MBlock.app.extensionManager.singleSelectExtension("mBot");
					}
				}else if(_board.indexOf("arduino")>-1){
					if(!MBlock.app.extensionManager.checkExtensionSelected("Arduino")){
						MBlock.app.extensionManager.singleSelectExtension("Arduino");
					}
				}else if(_board.indexOf("me/")>-1){
					if(_board == "me/orion_uno"){
						MBlock.app.openOrion();
					}
					if(!MBlock.app.extensionManager.checkExtensionSelected("Makeblock")){
						MBlock.app.extensionManager.singleSelectExtension("Makeblock");
					}
				}else if(MBlock.app.extensionManager.checkExtensionSelected("PicoBoard")){
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