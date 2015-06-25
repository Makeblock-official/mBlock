package extensions
{
	import flash.events.Event;
	
	public class RobotEvent extends Event
	{
		public static const SERIAL_PRINT:String = "SERIAL_PRINT";
		public static const COMPILE_OUTPUT:String = "COMPILE_OUTPUT";
		public static const HEX_DOWNLOAD:String = "HEX_DOWNLOAD";
		public static const HEX_SAVED:String = "HEX_SAVED";
		public static const CCODE_GOT:String = "CCODE_GOT";
		
		public var msg:Object;
		
		public function RobotEvent(type:String, msg:Object,bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.msg = msg;
		}
		
		public override function clone():Event
		{
			return new RobotEvent(type,msg,bubbles,cancelable);
		}
	}
}