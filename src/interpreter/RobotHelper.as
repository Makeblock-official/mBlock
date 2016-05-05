package interpreter
{
	
	import blocks.Block;
	import blocks.BlockArg;
	import blocks.BlockIO;

	public class RobotHelper
	{
		static private function cloneBlock(block:Block):Block
		{
			return BlockIO.stringToStack(BlockIO.stackToString(block), false);
		}
		
		static private var varIndex:int;
		
		static public function Modify(block:Block):Block
		{
			varIndex = 0;
			var newBlock:Block = cloneBlock(block);
			newBlock = modifyBlockList(newBlock);
			//*
//			trace(blockToString(block));
//			trace("----------");
////			trace(JSON.stringify(new BlockJsonPrinter().printBlockList(block)));
//			trace(blockToString(newBlock));
//			trace("----------");
			//*/
			if(blockToString(block) == blockToString(newBlock)){
				return block;
			}
			return newBlock;
		}
		
		static private function checkLoop(block:Block, prevBlock:Block):Block
		{
			switch(block.op){
				case "doWaitUntil":
					var newBlock:Block = new Block("repeat until %b", "c", 0xD00000, "doUntil");
					newBlock.args[0] = block.args[0];
					newBlock.nextBlock = block.nextBlock;
					if(prevBlock != null){
						prevBlock.nextBlock = newBlock;
					}
					block = newBlock;
				case "doRepeat":
				case "doUntil":
					_loopBlock = block;
					break;
				default:
					_loopBlock = null;
			}
			return block;
		}
		
		static private function addBlockToLoop(block:Block):void
		{
			if(null == _loopBlock.subStack1){
				_loopBlock.subStack1 = block;
				return;
			}
			var b:Block = _loopBlock.subStack1;
			while(b.nextBlock != null){
				b = b.nextBlock;
			}
			b.nextBlock = block;
		}
		
		static private var _loopBlock:Block;
		
		static private function modifyBlockList(block:Block):Block
		{
			var root:Block = block;
			var prevBlock:Block;
			while(block != null){
				var isRoot:Boolean = root == block;
				block = checkLoop(block, prevBlock);
				if(isRoot){
					root = block;
				}
				root = modifyBlock(block, root);
				if(block.subStack1 != null){
					block.subStack1 = modifyBlockList(block.subStack1);
				}
				if(block.subStack2 != null){
					block.subStack2 = modifyBlockList(block.subStack2);
				}
				prevBlock = block;
				block = block.nextBlock;
			}
			return root;
		}
		
		static public function isAutoVarName(varName:String):Boolean
		{
			return varName.indexOf("__") == 0;
		}
		
		static private function modifyBlock(b:Block, root:Block):Block
		{
			var delayTime:int;
			if(b.op.indexOf("runBuzzer") >= 0){
				if(b.args[1] is BlockArg){
					delayTime = beatsDict[b.args[1].argValue];
					createDelayBlock(b, delayTime);
				}else{
					createDelayBlock(b, delayTime);
					var tempBlock:Block = new Block("%n * %n", "r", 0xd00000, "*", ["",""]);
					tempBlock.args[0] = b.args[1];
					tempBlock.args[1] = new BlockArg("n",0, false);
					tempBlock.args[1].argValue = 0.001;
					b.nextBlock.args[0] = tempBlock;
				}
				return root;
			}
			if(b.op.indexOf("runTone") >= 0){
				delayTime = beatsDict[b.args[2].argValue];
				createDelayBlock(b, delayTime);
				return root;
			}
			if(b.op.indexOf("runLed") >= 0){
				createDelayBlock(b, 100);
				return root;
			}
			for(var i:int=0; i<b.args.length; i++){
				var blockArg:* = b.args[i];
				if(!(blockArg is Block)){
					continue;
				}
				var block:Block = blockArg as Block;
				root = modifyBlock(block, root);
				if(!isRobotOp(block)){
					continue;
				}
				if(!(isSimpleOp(b) || isRobotOp(b))){
					break;
				}
				var varName:String = "__" + (varIndex++).toString();
				var newBlock:Block = new Block("set %m.var to %s", " ", 0xD00000, Specs.SET_VAR, [varName, 0]);
				newBlock.args[1] = block;
				if(_loopBlock != null){
					addBlockToLoop(cloneBlock(newBlock));
				}
				newBlock.nextBlock = root;
				root = newBlock;
				b.args[i] = new Block(varName, "r", 0xD00000, Specs.GET_VAR);
			}
			return root;
		}
		
		static private function isRobotOp(b:Block):Boolean
		{
			return b.op.indexOf(".") >= 0;
		}
		
		static private function isSimpleOp(b:Block):Boolean
		{
			switch(b.op)
			{
				case "+":
				case "-":
				case "*":
				case "/":
				case "%":
				case ">":
				case "<":
				case "=":
				case "concatenate:with:":
				case "doIf":
				case "append:toList:":
				case "insert:at:ofList:":
				case "setLine:ofList:to:":
				case "list:contains:":
				case "computeFunction:of:":
				case "rounded":
					return true;
			}
			return false;
		}
		
		static public function blockToString(block:Block):String
		{
			return printBlockList(block).join("\n");
		}
		
		static private function printBlockList(block:Block, offset:int=0):Array
		{
			var offsetStr:String = "";
			while(offsetStr.length < offset){
				offsetStr += "\t";
			}
			var result:Array = [];
			while(block != null){
				result.push(offsetStr+printBlock(block));
				if(block.subStack1){
					result.push.apply(null, printBlockList(block.subStack1, offset+1));
				}
				if(block.subStack2){
					result.push(offsetStr+"else");
					result.push.apply(null, printBlockList(block.subStack2, offset+1));
				}
				block = block.nextBlock;
			}
			return result;
		}
		
		static private function printBlock(block:Block):String
		{
			var argList:Array = [];
			
			for each (var item:* in block.args)
			{
				if(item is BlockArg){
					argList.push(item.argValue);
				}else{
					argList.push(printBlock(item));
				}
			}
			
			if(block.op == Specs.GET_VAR){
				argList.push(block.spec);
			}
			
			return block.op + "(" + argList.join(", ") + ")";
		}
		
		static private function createDelayBlock(b:Block, delaySeconds:Number):void
		{
			var delayBlock:Block = new Block("wait %n secs", " ", 0xD00000, "wait:elapsed:from:", [0]);
			delayBlock.args[0] = new BlockArg("n", 0, false,"");
			delayBlock.args[0].argValue = delaySeconds * 0.001;
			
			delayBlock.nextBlock = b.nextBlock;
			b.nextBlock = delayBlock;
		}
		
		static private const beatsDict:Object = {
			"Half":500,
			"Quarter":250,
			"Eighth":125,
			"Whole":1000,
			"Double":2000,
			"Zero":0
		};
	}
}