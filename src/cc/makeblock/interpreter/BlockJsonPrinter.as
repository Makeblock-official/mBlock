package cc.makeblock.interpreter
{
	import blockly.SyntaxTreeFactory;
	
	import blocks.Block;
	import blocks.BlockArg;

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
				return SyntaxTreeFactory.NewDefine(argList, printBlockList(block.nextBlock));
			}
			var result:Array = [];
			while(block != null){
				printBlock(block, result);
				block = block.nextBlock;
			}
			return result;
		}
		
		private function addFrameSuspend(block:Block):Array
		{
			var result:Array = printBlockList(block.subStack1);
			if(null == result){
				return null;
			}
			result.push(SyntaxTreeFactory.NewStatement("suspendUntilNextFrame", []));
			return result;
		}
		
		public function printBlock(block:Block, result:Array):void
		{
			if(block.isHat){
				return;
			}
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
						result.push(SyntaxTreeFactory.NewInvoke(block.spec, collectArgs(block), 0));
					}else{
						var blockType:String = block.type.toLowerCase();
						var retCount:int = (blockType == "r") || (blockType == "b") ? 1 : 0;
						result.push(SyntaxTreeFactory.NewFunction(block.op, collectArgs(block), retCount));
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
				}
				return SyntaxTreeFactory.NewString(item.argValue);
			}
			if(Specs.GET_PARAM == item.op){
				return SyntaxTreeFactory.NewGetVar(item.spec);
			}
			if(item.op == Specs.GET_VAR){
				return SyntaxTreeFactory.NewExpression(item.op, [SyntaxTreeFactory.NewString(item.spec)]);
			}
			return SyntaxTreeFactory.NewExpression(item.op, collectArgs(item));
		}
	}
}