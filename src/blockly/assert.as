package blockly
{
	import flash.debugger.enterDebugger;

	public function assert(value:Object, message:String=null):void
	{
		if(Boolean(value) == false){
			throw new VerifyError(message);
			enterDebugger();
		}
	}
}