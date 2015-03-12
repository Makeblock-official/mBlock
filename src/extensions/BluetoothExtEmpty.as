package extensions
{
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	
	public class BluetoothExtEmpty extends EventDispatcher
	{
		public var connected:Boolean = false;
		public var supported:Boolean = false;
		public var connectName:String = "";
		public var isDiscovering:Boolean = false;
		public function BluetoothExtEmpty()
		{
			super();
		}
		public function writeBuffer(bytes:ByteArray):int{
			return 0;
		}
		public function writeString(msg:String):int{
			return 0;
		}
		public function disconnect():void{
			
		}
		public function beginDiscover():void{
			
		}
		public function connect(index:uint):void{
			
		}
		public function discoverResult():String{
			return "";
		}
		public function receivedBuffer():ByteArray{
			return null;
		}
	}
}