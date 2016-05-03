package blockly.runtime
{
	import blockly.arithmetic.IScriptContext;

	internal class FunctionObject
	{
		private var context:IScriptContext;
		private var argList:Array;
		private var address:int;
		
		internal var invokeCount:int;
		
		public function FunctionObject(context:IScriptContext, argList:Array, address:int)
		{
			this.context = context;
			this.argList = argList;
			this.address = address;
		}
		
		internal function initArgs(thread:Thread, valueList:Array):void
		{
			for(var i:int=argList.length-1; i>=0; --i)
				thread.newVar(argList[i], valueList[i]);
		}
		
		internal function createScope(thread:Thread, regCount:int):FunctionScope
		{
			var scope:FunctionScope = new FunctionScope(this);
			scope.prevContext = thread.getContext();
			scope.nextContext = context.createChildContext();
			scope.defineAddress = address;
			scope.returnAddress = thread.ip;
			scope.regCount = regCount;
			return scope;
		}
		
		internal function isRecursiveInvoke():Boolean
		{
			return invokeCount > 1;
		}
	}
}