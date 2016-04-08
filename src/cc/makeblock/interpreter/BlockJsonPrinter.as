package cc.makeblock.interpreter
{
	import blockly.SyntaxTreeFactory;
	
	import blocks.Block;
	import blocks.BlockArg;
	
	import cc.makeblock.util.StringChecker;

	internal class BlockJsonPrinter
	{
		public function BlockJsonPrinter()
		{
		}
		
		public function printBlockList(block:Block):Array
		{
			if(null == block){
				return null;
			}
			if(block.op == "procDef"){
				var argBlockList:Array = block.args[0].args;
				var argList:Array = [];
				for each(var b:Block in argBlockList){
					argList.push(b.spec);
				}
				return [
//					SyntaxTreeFactory.NewFunction(argList, printBlockList(block.nextBlock)),
					SyntaxTreeFactory.NewVar(block.args[0].spec, SyntaxTreeFactory.NewFunction(argList, printBlockList(block.nextBlock)))
				];
			}
			var result:Array = [];
			while(block != null){
				printBlock(block, result);
				block = block.nextBlock;
			}
			return result;
		}
		
		private function needAddFrameSuspend(block:Block):Boolean
		{
			var testBlock:Block = block;
			while(block != null){
				switch(block.op){
					case "forward:":
					case "turnRight:":
					case "turnLeft:":
					case "heading:":
					case "pointTowards:":
					case "gotoX:y:":
					case "gotoSpriteOrMouse:":
					case "glideSecs:toX:y:elapsed:from:":
					case "changeXposBy:":
					case "xpos:":
					case "changeYposBy:":
					case "ypos:":
						
					case "say:":
					case "think:":
					case "show":
					case "hide":
					case 'changeGraphicEffect:by:':
					case 'setGraphicEffect:to:':
					case 'filterReset':
					case 'changeSizeBy:':
					case 'setSizeTo:':
						
					case 'clearPenTrails':
						
//					case "setVar:to:":
//					case "changeVar:by:":
						return true;
					case "doIfElse":
						if( needAddFrameSuspend(block.subStack1) || needAddFrameSuspend(block.subStack2)){
							return true;
						}
						break;
					case "doIf":
						if( needAddFrameSuspend(block.subStack1)){
							return true;
						}
						break;
				}
				block = block.nextBlock;
			}
			return false;
		}
		
		private function addFrameSuspend(block:Block):Array
		{
			var result:Array = printBlockList(block.subStack1);
			if(null == result){
				return null;
			}
			if(needAddFrameSuspend(block.subStack1)){
				result.push(SyntaxTreeFactory.NewStatement("suspendUntilNextFrame", []));
			}
			return result;
		}
		
		public function printBlock(block:Block, result:Array):void
		{
			switch(block.op){
				case "doForever":
					result.push(SyntaxTreeFactory.NewWhile(SyntaxTreeFactory.NewNumber(1), addFrameSuspend(block)));
					break;
				case "doRepeat":
					result.push(SyntaxTreeFactory.NewLoop(getArg(block, 0), addFrameSuspend(block)));
					break;
				case "doWaitUntil":
				case "doUntil":
					result.push(SyntaxTreeFactory.NewUntil(getArg(block, 0), addFrameSuspend(block)));
					break;
				case "doIfElse":
					result.push(
						SyntaxTreeFactory.NewIf(getArg(block, 0), printBlockList(block.subStack1)),
						SyntaxTreeFactory.NewElse(printBlockList(block.subStack2))
					);
					break;
				case "doIf":
					result.push(
						SyntaxTreeFactory.NewIf(getArg(block, 0), printBlockList(block.subStack1))
					);
					break;
				default:
					if("call" == block.op){
						result.push(
//							SyntaxTreeFactory.GetVar(block.spec),
							SyntaxTreeFactory.NewInvoke(SyntaxTreeFactory.GetVar(block.spec), collectArgs(block), 0)
						);
					}else{
						var blockType:String = block.type.toLowerCase();
						var retCount:int = (blockType == "r") || (blockType == "b") ? 1 : 0;
						result.push(SyntaxTreeFactory.Call(block.op, collectArgs(block), retCount));
					}
					break;
			}
		}
		
		private function collectArgs(block:Block):Array
		{
			var argList:Array = [];
			for(var i:int=0; i<block.args.length; ++i){
				argList.push(getArg(block, i));
			}
			return argList;
		}
		
		private function getArg(block:Block, index:int):Object
		{
			var item:* = block.args[index];
			if(item is BlockArg){
				if(item.isNumber){
					var value:* = Number(item.argValue);
					if(isNaN(value)){
						value = item.argValue;
					}
					return SyntaxTreeFactory.NewNumber(value);
				}else if(StringChecker.IsNumber(item.argValue)){
					return SyntaxTreeFactory.NewNumber(parseFloat(item.argValue));
				}
				return SyntaxTreeFactory.NewString(item.argValue);
			}
			if(Specs.GET_PARAM == item.op){
				return SyntaxTreeFactory.GetVar(item.spec);
			}
			if(item.op == Specs.GET_VAR){
				return SyntaxTreeFactory.NewExpression(item.op, [SyntaxTreeFactory.NewString(item.spec)]);
			}
			return SyntaxTreeFactory.NewExpression(item.op, collectArgs(item));
		}
	}
}