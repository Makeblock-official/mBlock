package blockly.util
{
	import blockly.runtime.FunctionProvider;
	import blockly.runtime.Thread;

	public class FunctionProviderHelper
	{
		static public function InitMath(provider:FunctionProvider):void
		{
			provider.register("+", onAdd);
			provider.register("-", onSub);
			provider.register("*", onMul);
			provider.register("/", onDiv);
			provider.register("%", onMod);
			
			provider.register("!", onNot);
			provider.register("&&", onAnd);
			provider.register("||", onOr);
			
			provider.register("<", onLess);
			provider.register("<=", onLessEqual);
			provider.register(">", onGreater);
			provider.register(">=", onGreaterEqual);
			provider.register("==", onEqual);
			provider.register("!=", onNotEqual);
			
			provider.register("trace", onTrace);
			provider.register("sleep", onSleep);
			provider.register("getProp", onGetProp);
			provider.register("setProp", onSetProp);
		}
		
		static private function onTrace(thread:Thread, argList:Array):void
		{
			trace.apply(null, argList);
		}
		
		static public function onSleep(thread:Thread, argList:Array):void
		{
			thread.suspend();
			thread.suspendUpdater = [_onSleep, argList[0] * 1000];
		}
		
		static private function _onSleep(thread:Thread, timeout:int):void
		{
			if(thread.timeElapsedSinceSuspend >= timeout){
				thread.resume();
			}
		}
		
		static private function onGetProp(thread:Thread, argList:Array):void
		{
			thread.push(argList[0][argList[1]]);
		}
		
		static private function onSetProp(thread:Thread, argList:Array):void
		{
			argList[0][argList[1]] = argList[2];
		}
		
		static private function onAdd(thread:Thread, argList:Array):void
		{
			thread.push(argList[0] + argList[1]);
		}
		
		static private function onSub(thread:Thread, argList:Array):void
		{
			thread.push(argList[0] - argList[1]);
		}
		
		static private function onMul(thread:Thread, argList:Array):void
		{
			thread.push(argList[0] * argList[1]);
		}
		
		static private function onDiv(thread:Thread, argList:Array):void
		{
			thread.push(argList[0] / argList[1]);
		}
		
		static private function onMod(thread:Thread, argList:Array):void
		{
			thread.push(argList[0] % argList[1]);
		}
		
		static private function onNot(thread:Thread, argList:Array):void
		{
			thread.push(!argList[0]);
		}
		
		static private function onAnd(thread:Thread, argList:Array):void
		{
			thread.push(argList[0] && argList[1]);
		}
		
		static private function onOr(thread:Thread, argList:Array):void
		{
			thread.push(argList[0] || argList[1]);
		}
		
		static private function onLess(thread:Thread, argList:Array):void
		{
			thread.push(argList[0] < argList[1]);
		}
		
		static private function onLessEqual(thread:Thread, argList:Array):void
		{
			thread.push(argList[0] <= argList[1]);
		}
		
		static private function onGreater(thread:Thread, argList:Array):void
		{
			thread.push(argList[0] > argList[1]);
		}
		
		static private function onGreaterEqual(thread:Thread, argList:Array):void
		{
			thread.push(argList[0] >= argList[1]);
		}
		
		static private function onEqual(thread:Thread, argList:Array):void
		{
			thread.push(argList[0] == argList[1]);
		}
		
		static private function onNotEqual(thread:Thread, argList:Array):void
		{
			thread.push(argList[0] != argList[1]);
		}
	}
}