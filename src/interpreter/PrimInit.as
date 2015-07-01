package interpreter
{
	import blocks.Block;
	
	import extensions.ParseManager;
	
	import scratch.ScratchObj;

	internal class PrimInit
	{
		static public function Init(primTable:Object):void
		{
			// control
			primTable["whenGreenFlag"]		= doNothing;
			primTable["whenKeyPressed"]		= doNothing;
			primTable["whenKeyReleased"]	= doNothing;
			primTable["whenClicked"]		= doNothing;
			primTable["whenSceneStarts"]	= doNothing;
			primTable["wait:elapsed:from:"]	= doWait;
			primTable["doForever"]			= doForever;
			primTable["doRepeat"]			= doRepeat;
			primTable["broadcast:"]			= doBroadcast;
			primTable["doBroadcastAndWait"]	= doBroadcastAndWait;
			primTable["whenIReceive"]		= doNothing;
			primTable["doForeverIf"]		= doForeverIf;
			primTable["doForLoop"]			= doForLoop;
			primTable["doIf"]				= doIf;
			primTable["doIfElse"]			= doIfElse;
			primTable["doWaitUntil"]		= doWaitUntil;
			primTable["doWhile"]			= doWhile;
			primTable["doUntil"]			= doUntil;
			primTable["doReturn"]			= doReturn;
			primTable["stopAll"]			= stopAll;
			primTable["stopScripts"]		= stopScripts;
			primTable["warpSpeed"]			= warpSpeed;
			
			// procedures
			primTable[Specs.CALL]			= doCall;
			
			// variables
			primTable[Specs.GET_VAR]		= doGetVar;
			primTable[Specs.SET_VAR]		= doSetVar;
			primTable[Specs.CHANGE_VAR]		= increaseVar;
			primTable[Specs.GET_PARAM]		= getParam;
			
			// edge-trigger hat blocks
			primTable["whenDistanceLessThan"]	= doNothing;
			primTable["whenSensorConnected"]	= doNothing;
			primTable["whenSensorGreaterThan"]	= doNothing;
			primTable["whenTiltIs"]				= doNothing;
		}
		
		static private function doNothing(b:Block):void
		{
		}
		
		static private function doWait(b:Block, target:Interpreter):void {
			if (target.activeThread.firstTime) {
				target.startTimer(target.numarg(b, 0));
				target.redraw();
			} else {
				target.checkTimer();
			}
		}
		
		static private function doForever(b:Block, target:Interpreter):void
		{
			target.startCmdList(b.subStack1, true);
		}
		
		static private function doRepeat(b:Block, target:Interpreter):void
		{
			if (target.activeThread.firstTime) {
				var repeatCount:Number = Math.max(0, Math.min(Math.round(target.numarg(b, 0)), 2147483647)); // clip to range: 0 to 2^31-1
				target.activeThread.tmp = repeatCount;
				target.activeThread.firstTime = false;
			}
			if (target.activeThread.tmp > 0) {
				target.activeThread.tmp--; // decrement count
				target.startCmdList(b.subStack1, true);
			} else {
				target.activeThread.firstTime = true;
			}
		}
		
		static private function broadcast(target:Interpreter, msg:String, waitFlag:Boolean):void
		{
			ParseManager.sharedManager().parse("serial/line/"+msg);
			if (target.activeThread.firstTime) {
				var receivers:Array = [];
				msg = msg.toLowerCase();
				function findReceivers(stack:Block, obj:ScratchObj):void {
					try{
						if ((stack.op == "whenIReceive") && (stack.args[0].argValue.toLowerCase() == msg)) {
							receivers.push([stack, obj]);
						}
					}catch(e:Error){
						trace(e);
						var b:Block = (stack.args[0] as Block);
						if ((stack.op == "whenIReceive") && (target.evalCmd(b).toLowerCase() == msg)) {
							receivers.push([stack, obj]);
						}
					}
				}
				MBlock.app.runtime.allStacksAndOwnersDo(findReceivers);
				target.startAllReceivers(receivers, waitFlag);
				if(!waitFlag){
					return;
				}
			}
			target.checkDone();
		}
		
		static private function doBroadcast(b:Block, target:Interpreter):void
		{
			broadcast(target, target.arg(b, 0), false);
		}
		
		static private function doBroadcastAndWait(b:Block, target:Interpreter):void
		{
			broadcast(target, target.arg(b, 0), true);
		}
		
		static private function doForeverIf(b:Block, target:Interpreter):void
		{
			if (target.arg(b, 0)) {
				target.startCmdList(b.subStack1, true);
			} else {
				target.yield = true;
			}
		}
		
		static private function doForLoop(b:Block, target:Interpreter):void
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
		
		static private function doIf(b:Block, target:Interpreter):void
		{
			if (target.arg(b, 0)){
				target.startCmdList(b.subStack1);
			}
		}
		
		static private function doIfElse(b:Block, target:Interpreter):void
		{
			if (target.arg(b, 0)){
				target.startCmdList(b.subStack1);
			}else{
				target.startCmdList(b.subStack2);
			}
		}
		
		static private function doWaitUntil(b:Block, target:Interpreter):void
		{
			if (!target.arg(b, 0)) {
				target.yield = true;
			}
		}
		
		static private function doWhile(b:Block, target:Interpreter):void
		{
			if (target.arg(b, 0)){
				target.startCmdList(b.subStack1, true);
			}
		}
		
		static private function doUntil(b:Block, target:Interpreter):void
		{
			if (!target.arg(b, 0)){
				target.startCmdList(b.subStack1, true);
			}
		}
		
		static private function doReturn(b:Block, target:Interpreter):void
		{
			// Return from the innermost procedure. If not in a procedure, stop the thread.
			if (!target.activeThread.returnFromProcedure()) {
				target.activeThread.stop();
				target.yield = true;
			}
		}
		
		static private function stopScripts(b:Block, target:Interpreter):void
		{
			switch(target.arg(b, 0))
			{
				case "all":
					MBlock.app.runtime.stopAll();
					target.yield = true;
					break;
				case "this script":
					doReturn(b, target);
					break;
				case "other scripts in sprite":
				case "other scripts in stage":
					target.stopThreadsFor(target.activeThread.target, true);
					break;
			}
		}
		
		static private function doCall(b:Block, target:Interpreter):void
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
				if ((target.currentMSecs - target.startTime) > Interpreter.warpMSecs) target.yield = true;
			} else {
				if (proc.warpProcFlag) {
					// Start running in warp mode.
					target.warpBlock = b;
					target.warpThread = target.activeThread;
					target.activeThread.firstTime = true;
				}
				else if (target.activeThread.isRecursiveCall(b, proc)) {
					target.yield = true;
				}
			}
			var argCount:int = proc.parameterNames.length;
			var argList:Array = [];
			for (var i:int = 0; i < argCount; ++i) argList.push(target.arg(b, i));
			target.startCmdList(proc, false, argList);
		}
		
		static private function doGetVar(b:Block, target:Interpreter):Object
		{
			if(null == target.activeThread){
				return null;
			}
			var v:Variable = target.activeThread.target.varCache[b.spec];
			if(v != null){
				// XXX: Do we need a get() for persistent variables here ?
				return v.value;
			}
			v = target.activeThread.target.varCache[b.spec] = target.activeThread.target.lookupOrCreateVar(b.spec);
			return (v != null) ? v.value : 0;
		}
		
		static private function doSetVar(b:Block, target:Interpreter):Variable
		{
			var v:Variable = target.activeThread.target.varCache[target.arg(b, 0)];
			if (!v) {
				v = target.activeThread.target.varCache[b.spec] = target.activeThread.target.lookupOrCreateVar(target.arg(b, 0));
				if (!v) return null;
			}
//			var oldvalue:* = v.value;
			var r:* = target.arg(b, 1);
			if(r!=null){
				v.value = r;
			}
			return v;
		}
		
		static private function increaseVar(b:Block, target:Interpreter):Variable
		{
			var v:Variable = target.activeThread.target.varCache[target.arg(b, 0)];
			if (!v) {
				v = target.activeThread.target.varCache[b.spec] = target.activeThread.target.lookupOrCreateVar(target.arg(b, 0));
				if (!v) return null;
			}
			v.value = Number(v.value) + target.numarg(b, 1);
			return v;
		}
		
		static private function getParam(b:Block, target:Interpreter):Object
		{
			if (b.parameterIndex < 0) {
				var proc:Block = b.topBlock();
				if (proc.parameterNames) b.parameterIndex = proc.parameterNames.indexOf(b.spec);
				if (b.parameterIndex < 0) return 0;
			}
			if ((target.activeThread.args == null) || (b.parameterIndex >= target.activeThread.args.length)) return 0;
			return target.activeThread.args[b.parameterIndex];
		}
		
		static private function warpSpeed(b:Block, target:Interpreter):void
		{
			// Semi-support for old warp block: run substack at normal speed.
			if(b.subStack1 != null){
				target.startCmdList(b.subStack1);
			}
		}
		
		static private function stopAll(b:Block, target:Interpreter):void
		{
			MBlock.app.runtime.stopAll();
			target.yield = true;
		}
	}
}