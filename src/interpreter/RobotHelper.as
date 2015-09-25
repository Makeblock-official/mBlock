package interpreter
{
	import blocks.Block;
	import blocks.BlockArg;
	import blocks.BlockIO;

	public class RobotHelper
	{
		static private var varIndex:int;
		
		static public function Modify(block:Block):Block
		{
			varIndex = 0;
			var newBlock:Block = BlockIO.stringToStack(BlockIO.stackToString(block), false);
			newBlock = modifyBlockList(newBlock);
			if(blockToString(block) == blockToString(newBlock)){
				return block;
			}
//			trace(blockToString(newBlock));
			return newBlock;
		}
		
		static private function modifyBlockList(block:Block):Block
		{
			var root:Block = block;
			while(block != null){
				root = modifyBlock(block, root);
				if(block.subStack1 != null){
					block.subStack1 = modifyBlockList(block.subStack1);
				}
				if(block.subStack2 != null){
					block.subStack2 = modifyBlockList(block.subStack2);
				}
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
				case ">":
				case "<":
				case "=":
				case "concatenate:with:":
				case "doIf":
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
	}
}