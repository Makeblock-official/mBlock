package blockly.runtime
{
	import blockly.assert;

	internal class FunctionObjectNative
	{
		private var handler:Function;
		
		public function FunctionObjectNative(handler:Function)
		{
			this.handler = handler;
		}
		
		internal function invoke(thread:Thread, valueList:Array):void
		{
			switch(handler.length){
				case 2: handler(thread, valueList);
					break;
				case 1: handler(valueList);
					break;
				case 0: handler();
					break;
				default:assert(false);
			}
		}
	}
}