package blockly.runtime
{
	import blockly.arithmetic.IScriptContext;

	internal class FunctionScope
	{
		internal var prevContext:IScriptContext;
		internal var nextContext:IScriptContext;
		internal var defineAddress:int;
		internal var returnAddress:int;
		internal var regCount:int;
		internal var funcRef:FunctionObject;
		
		public function FunctionScope(funcRef:FunctionObject)
		{
			this.funcRef = funcRef;
		}
	}
}