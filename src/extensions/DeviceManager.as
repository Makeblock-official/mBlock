package extensions
{
	import util.SharedObjectManager;

	public class DeviceManager
	{
		private static var _instance:DeviceManager;
		private var _device:String = "";
		private var _board:String = "";
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
			_board = board;
			_device = _board.split("_")[1];
			SharedObjectManager.sharedManager().setObject("board",board);
			if(_board=="picoboard_unknown"){
				MBlock.app.extensionManager.singleSelectExtension("PicoBoard");
			}else{
				if(_board=="mbot_uno"){
					if(!MBlock.app.extensionManager.checkExtensionSelected("mBot")){
						MBlock.app.extensionManager.onSelectExtension("mBot");
					}
				}
				if(_board.indexOf("arduino")>-1){
					if(!MBlock.app.extensionManager.checkExtensionSelected("Arduino")){
						MBlock.app.extensionManager.onSelectExtension("Arduino");
					}
				}
				if(_board.indexOf("me/")>-1){
					if(!MBlock.app.extensionManager.checkExtensionSelected("Makeblock")){
						MBlock.app.extensionManager.onSelectExtension("Makeblock");
					}
				}
				if(MBlock.app.extensionManager.checkExtensionSelected("PicoBoard")){
					MBlock.app.extensionManager.onSelectExtension("PicoBoard");
				}
			}
		}
		public function checkCurrentBoard(board:String):Boolean{
			return _board==board;
		}
		public function get currentBoard():String{
			return _board;
		}
		public function get currentDevice():String{
			return _device;
		}
	}
}