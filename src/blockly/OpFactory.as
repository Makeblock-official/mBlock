package blockly
{
	public class OpFactory
	{
		static public function JumpIfTrue(offset:int):Array
		{
			return [OpCode.JUMP_IF_TRUE, offset];
		}
		
		static public function Jump(offset:int):Array
		{
			return [OpCode.JUMP, offset];
		}
		
		static public function Push(value:Object):Array
		{
			return [OpCode.PUSH, value];
		}
		
		static public function Call(funcName:String, argCount:int, retCount:int):Array
		{
			return [OpCode.CALL, funcName, argCount, retCount];
		}
		
		static public function LoadSlot(index:int):Array
		{
			return [OpCode.LOAD_SLOT, index];
		}
		
		static public function SaveSlot(index:int):Array
		{
			return [OpCode.SAVE_SLOT, index];
		}
		
		static public function Invoke(argCount:int, retCount:int, regCount:int):Array
		{
			return [OpCode.INVOKE, argCount, retCount, regCount];
		}
		
		static public function GetVar(name:String):Array
		{
			return [OpCode.GET_VAR, name];
		}
		
		static public function NewFunction(jumpOffset:int, argList:Array):Array
		{
			return [OpCode.NEW_FUNCTION, jumpOffset, argList];
		}
	}
}