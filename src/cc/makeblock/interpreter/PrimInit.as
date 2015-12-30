package cc.makeblock.interpreter
{
	import blockly.runtime.FunctionProvider;
	import blockly.runtime.Thread;
	
	import blocks.Block;
	
	import extensions.ParseManager;
	
	import interpreter.Variable;
	
	import scratch.ScratchObj;
	
	import uiwidgets.StretchyBitmap;
	
	internal class PrimInit
	{
		static public function Init(provider:FunctionProvider):void
		{
			provider.alias("sleep", "wait:elapsed:from:");
			provider.register("broadcast:", doBroadcast);
			provider.register("doBroadcastAndWait", doBroadcastAndWait);
			provider.register("stopAll", stopAll);
			provider.register("stopScripts", stopScripts);
			
			provider.register(Specs.GET_VAR, doGetVar);
			provider.register(Specs.SET_VAR, doSetVar);
			provider.register(Specs.CHANGE_VAR, increaseVar);
		}
		
		static private function broadcast(thread:Thread, msg:String, waitFlag:Boolean):void
		{
			ParseManager.sharedManager().parse("serial/line/"+msg);
//			if (target.activeThread.firstTime) {
			var receivers:Array = [];
			msg = msg.toLowerCase();
			function findReceivers(stack:Block, obj:ScratchObj):void {
				if ((stack.op == "whenIReceive") && (stack.args[0].argValue.toLowerCase() == msg)) {
					receivers.push([stack, obj]);
				}
			}
			MBlock.app.runtime.allStacksAndOwnersDo(findReceivers);
			var threadList:Array = [];
			for each(var item:Array in receivers){
				var newThread:Thread = MBlock.app.interp.toggleThread(item[0], item[1]);
				threadList.push(newThread);
			}
//			target.startAllReceivers(receivers, waitFlag);
			if(waitFlag){
				thread.suspend();
				thread.suspendUpdater = [checkSubThreadFinish, threadList];
			}
		}
		
		static public function checkSubThreadFinish(thread:Thread, threadList:Array):void
		{
			for each(var t:Thread in threadList){
				if(!t.isFinish()){
					return;
				}
			}
			thread.resume();
		}
		
		static private function doBroadcast(thread:Thread, argList:Array):void
		{
			broadcast(thread, argList[0], false);
		}
		
		static private function doBroadcastAndWait(thread:Thread, argList:Array):void
		{
			broadcast(thread, argList[0], true);
		}
		/*
		static private function doForLoop(thread:Thread, argList:Array):void
		{
			var list:Array = [];
			var loopVar:Variable;
			
			if (target.activeThread.firstTime) {
				if (!(target.arg(b, 0) is String)) return;
				var listArg:* = target.arg(b, 1);
				if (listArg is Array) {
					list = listArg as Array;
				}
				if (listArg is String) {
					var n:Number = Number(listArg);
					if (!isNaN(n)) listArg = n;
				}
				if ((listArg is Number) && !isNaN(listArg)) {
					var last:int = int(listArg);
					if (last >= 1) {
						list = new Array(last - 1);
						for (var i:int = 0; i < last; i++) list[i] = i + 1;
					}
				}
				loopVar = target.activeThread.target.lookupOrCreateVar(target.arg(b, 0));
				target.activeThread.args = [list, loopVar];
				target.activeThread.tmp = 0;
				target.activeThread.firstTime = false;
			}
			
			list = target.activeThread.args[0];
			loopVar = target.activeThread.args[1];
			if (target.activeThread.tmp < list.length) {
				loopVar.value = list[target.activeThread.tmp++];
				target.startCmdList(b.subStack1, true);
			} else {
				target.activeThread.args = null;
				target.activeThread.tmp = 0;
				target.activeThread.firstTime = true;
			}
		}
		static private function doIf(thread:Thread, argList:Array):void
		{
			if (target.arg(b, 0)){
				target.startCmdList(b.subStack1);
			}
		}
		
		static private function doIfElse(thread:Thread, argList:Array):void
		{
			if (target.arg(b, 0)){
				target.startCmdList(b.subStack1);
			}else{
				target.startCmdList(b.subStack2);
			}
		}
		
		static private function doWaitUntil(thread:Thread, argList:Array):void
		{
			if (!target.arg(b, 0)) {
				target.setYielded();
			}
		}
		
		static private function doWhile(thread:Thread, argList:Array):void
		{
			if (target.arg(b, 0)){
				target.startCmdList(b.subStack1, true);
			}
		}
		
		static private function doUntil(thread:Thread, argList:Array):void
		{
			if (!target.arg(b, 0)){
				target.startCmdList(b.subStack1, true);
			}
		}
		
		static private function doReturn(thread:Thread, argList:Array):void
		{
			// Return from the innermost procedure. If not in a procedure, stop the thread.
			if (!target.activeThread.returnFromProcedure()) {
				target.activeThread.stop();
				target.setYielded();
			}
		}
		*/
		
		static private function stopScripts(thread:Thread, argList:Array):void
		{
			switch(argList[0])
			{
				case "all":
					MBlock.app.runtime.stopAll();
					break;
				case "this script":
					thread.interrupt();
					break;
				case "other scripts in sprite":
				case "other scripts in stage":
					BlockInterpreter.Instance.stopObjOtherThreads(thread);
					break;
			}
		}
		/*
		static private function doCall(thread:Thread, argList:Array):void
		{
			// Call a procedure. Handle recursive calls and "warp" procedures.
			// The activeThread.firstTime flag is used to mark the first call
			// to a procedure running in warp mode. activeThread.firstTime is
			// false for subsequent calls to warp mode procedures.
			
			// Lookup the procedure and cache for future use
			var obj:ScratchObj = target.activeThread.target;
			var spec:String = b.spec;
			var proc:Block = obj.procCache[spec];
			if (!proc) {
				proc = obj.lookupProcedure(spec);
				obj.procCache[spec] = proc;
			}
			if (!proc) return;
			
			if (target.warpThread) {
				target.activeThread.firstTime = false;
				if (target.isTimeOut()) target.setYielded();
			} else {
				if (proc.warpProcFlag) {
					// Start running in warp mode.
					target.warpBlock = b;
					target.warpThread = target.activeThread;
					target.activeThread.firstTime = true;
				}
				else if (target.activeThread.isRecursiveCall(b, proc)) {
					target.setYielded();
				}
			}
			var argCount:int = proc.parameterNames.length;
			var argList:Array = [];
			for (var i:int = 0; i < argCount; ++i) argList.push(target.arg(b, i));
			target.startCmdList(proc, false, argList);
		}
		*/
		static private const numPattern:RegExp = /^-?\d+(.\d+)?$/;
		static private function getVarRealVal(val:*):*
		{
			var result:* = val;
			if(val is String && numPattern.test(val)){
				return parseFloat(val);
			}
			return result;
		}
		
		static private function doGetVar(thread:Thread, argList:Array):void
		{
			var target:* = thread.userData;
			var v:Variable = target.varCache[argList[0]];
			if(v != null){
				// XXX: Do we need a get() for persistent variables here ?
				thread.push(getVarRealVal(v.value));
				return;
			}
			v = target.varCache[argList[0]] = target.lookupOrCreateVar(argList[0]);
			thread.push( (v != null) ? getVarRealVal(v.value) : 0);
		}
		
		static private function doSetVar(thread:Thread, argList:Array):void
		{
			var target:* = thread.userData;
			var v:Variable = target.varCache[argList[0]];
			if (!v) {
				v = target.varCache[argList[0]] = target.lookupOrCreateVar(argList[0]);
				if (!v){
					return;
				}
			}
			v.value = argList[1];
		}
		
		static private function increaseVar(thread:Thread, argList:Array):void
		{
			var target:* = thread.userData;
			var v:Variable = target.varCache[argList[0]];
			if (!v) {
				v = target.varCache[argList[0]] = target.lookupOrCreateVar(argList[0]);
				if (!v){
					return;
				}
			}
			v.value = Number(v.value) + Number(argList[1]);
		}
		
//		static private function getParam(thread:Thread, argList:Array):void
//		{
//			if (b.parameterIndex < 0) {
//				var proc:Block = b.topBlock();
//				if (proc.parameterNames) b.parameterIndex = proc.parameterNames.indexOf(b.spec);
//				if (b.parameterIndex < 0) return 0;
//			}
//			if ((target.activeThread.args == null) || (b.parameterIndex >= target.activeThread.args.length)) return 0;
//			return target.activeThread.args[b.parameterIndex];
//		}
//		
//		static private function warpSpeed(thread:Thread, argList:Array):void
//		{
//			// Semi-support for old warp block: run substack at normal speed.
//			if(b.subStack1 != null){
//				target.startCmdList(b.subStack1);
//			}
//		}
		
		static private function stopAll(thread:Thread, argList:Array):void
		{
			MBlock.app.runtime.stopAll();
		}
	}
}