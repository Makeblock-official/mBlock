package blockly.arithmetic
{
	public interface IScriptContext
	{
		function newKey(key:String, value:Object):void;
		function delKey(key:String):void;
		
		function hasKey(key:String, searchParent:Boolean):Boolean;
		
		function getValue(key:String):*;
		function setValue(key:String, value:Object):void;
		
		function createChildContext():IScriptContext;
	}
}