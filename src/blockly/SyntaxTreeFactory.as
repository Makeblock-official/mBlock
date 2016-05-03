package blockly
{
	public class SyntaxTreeFactory
	{
		static public function NewString(value:Object):Object
		{
			return {"type":"string", "value":value};
		}
		
		static public function NewNumber(value:Object):Object
		{
			return {"type":"number", "value":value};
		}
		
		static public function Return():Object
		{
			return {"type":"return"};
		}
		
		static public function NewVar(name:String, value:Object):Object
		{
			return {"type":OpCode.NEW_VAR, "name":name, "value":value};
		}
		
		static public function GetVar(name:String):Object
		{
			return {"type":OpCode.GET_VAR, "name":name};
		}
		
		static public function SetVar(name:String, value:Object):Object
		{
			return {"type":OpCode.SET_VAR, "name":name, "value":value};
		}
		
		static public function NewInvoke(target:Object, argList:Array, retCount:int):Object
		{
			return {
				"type":"invoke",
				"target":target,
				"argList":argList,
				"retCount":retCount
			};
		}
		
		static public function Call(name:String, argList:Array, retCount:int):Object
		{
			return {
				"type":"function",
				"method":name,
				"argList":argList,
				"retCount":retCount
			};
		}
		
		static public function NewExpression(name:String, argList:Array):Object
		{
			return Call(name, argList, 1);
		}
		
		static public function NewStatement(name:String, argList:Array):Object
		{
			return Call(name, argList, 0);
		}
		
		static public function NewLoop(count:Object, code:Array):Object
		{
			return {
				"type":"loop",
				"count":count,
				"code":code
			};
		}
		
		static public function NewWhile(condition:Object, code:Array):Object
		{
			return {
				"type":"while",
				"condition":condition,
				"code":code
			};
		}
		
		static public function NewUntil(condition:Object, code:Array):Object
		{
			return {
				"type":"until",
				"condition":condition,
				"code":code
			};
		}
		
		static public function NewFor(init:Array, condition:Object, iter:Array, code:Array):Object
		{
			return {
				"type":"for",
				"init":init,
				"condition":condition,
				"iter":iter,
				"code":code
			};
		}
		
		static public function NewUnless(condition:Object, code:Array):Object
		{
			return {
				"type":"unless",
				"condition":condition,
				"code":code
			};
		}
		
		static public function NewIf(condition:Object, code:Array):Object
		{
			return {
				"type":"if",
				"condition":condition,
				"code":code
			};
		}
		
		static public function NewElseIf(condition:Object, code:Array):Object
		{
			return {
				"type":"else if",
				"condition":condition,
				"code":code
			};
		}
		
		static public function NewElse(code:Array):Object
		{
			return {
				"type":"else",
				"code":code
			};
		}
		
		static public function NewFunction(argNameList:Array, code:Array):Object
		{
			return {
				"type":OpCode.NEW_FUNCTION,
				"argList":argNameList,
				"code":code
			};
		}
	}
}