package blockly.runtime
{
	import blockly.arithmetic.IScriptContext;
	import blockly.arithmetic.ScriptContext;
	import blockly.assert;

	public class FunctionProvider
	{
		private const context:IScriptContext = new ScriptContext();
		
		public function FunctionProvider(){}
		
		public function register(name:String, handler:Function):void
		{
			context.newKey(name, new FunctionObjectNative(handler));
		}
		
		public function alias(name:String, newName:String):void
		{
			assert(context.hasKey(name, false));
			context.newKey(newName, context.getValue(name));
		}
		
		internal function getContext():IScriptContext
		{
			return context;
		}
		
		internal function execute(thread:Thread, name:String, argList:Array, retCount:int):void
		{
			if(context.hasKey(name, false)){
				var handler:FunctionObjectNative = context.getValue(name);
				handler.invoke(thread, argList);
			}else{
				onCallUnregisteredFunction(thread, name, argList, retCount);
			}
		}
		
		protected function onCallUnregisteredFunction(thread:Thread, name:String, argList:Array, retCount:int):void
		{
			trace("interpreter invoke method:", name, argList, retCount);
		}
	}
}