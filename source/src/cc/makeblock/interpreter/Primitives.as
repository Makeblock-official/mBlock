/*
* Scratch Project Editor and Player
* Copyright (C) 2014 Massachusetts Institute of Technology
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public License
* as published by the Free Software Foundation; either version 2
* of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

// Primitives.as
// John Maloney, April 2010
//
// Miscellaneous primitives. Registers other primitive modules.
// Note: A few control structure primitives are implemented directly in Interpreter.as.

package cc.makeblock.interpreter {
	import flash.utils.Dictionary;
	
	import blockly.runtime.FunctionProvider;
	import blockly.runtime.Thread;
	
	import blocks.Block;
	
	import interpreter.Interpreter;
	
	import scratch.ScratchSprite;
	
	
	internal class Primitives {
		
		private const MaxCloneCount:int = 300;
		
//		private var counter:int;
		
		public function addPrimsTo(provider:FunctionProvider):void {
			provider.alias("==", "=");
			provider.alias("&&", "&");
			provider.alias("||", "|");
			provider.alias("!", "not");
			provider.register("randomFrom:to:", onRandomInt);
			provider.register("abs", function(thread:Thread, argList:Array):void { thread.push( Math.abs(Number(argList[0]))) });
			provider.register("sqrt", function(thread:Thread, argList:Array):void { thread.push( Math.sqrt(Number(argList[0]))) });
			
			provider.register("concatenate:with:", function(thread:Thread, argList:Array):void { 
				thread.push( String(argList[0]) + String(argList[1]));
			});
			provider.register("castDigitToString:", castDigitToString);
			provider.register("letter:of:", primLetterOf);
			provider.register("stringLength:", function(thread:Thread, argList:Array):void { thread.push( String(argList[0]).length) });
			
			provider.register("%", primModulo);
			provider.register("rounded", function(thread:Thread, argList:Array):void { 
				thread.push( Math.round(Number(argList[0])));
			});
			provider.register("computeFunction:of:", primMathFunction);
			
			// clone
			provider.register("createCloneOf", primCreateCloneOf);
			provider.register("deleteClone", primDeleteClone);
//			
//			// testing (for development)
//			provider.register("COUNT", function(thread:Thread, argList:Array):void { return counter });
//			provider.register("INCR_COUNT", function(thread:Thread, argList:Array):void { counter++ });
//			provider.register("CLR_COUNT", function(thread:Thread, argList:Array):void { counter = 0 });
		}
		
		private function onRandomInt(thread:Thread, argList:Array):void
		{
			var n1:Number = argList[0];
			var n2:Number = argList[1];
			var low:Number = (n1 <= n2) ? n1 : n2;
			var hi:Number = (n1 <= n2) ? n2 : n1;
			if (low == hi){
				thread.push(low);
			}else if(int(low) == low && int(hi) == hi){
				thread.push(low + int(Math.random() * (hi + 1 - low)));
			}else{
				thread.push(low + Math.random() * (hi - low));
			}
		}
		
//		private function primRandom(thread:Thread, argList:Array):void {
//			var n1:Number = interp.numarg(b, 0);
//			var n2:Number = interp.numarg(b, 1);
//			var low:Number = (n1 <= n2) ? n1 : n2;
//			var hi:Number = (n1 <= n2) ? n2 : n1;
//			if (low == hi) return low;
//			// if both low and hi are ints, truncate the result to an int
//			if ((int(low) == low) && (int(hi) == hi)) {
//				return low + int(Math.random() * ((hi + 1) - low));
//			}
//			return (Math.random() * (hi - low)) + low;
//		}
		
		private function castDigitToString(thread:Thread, argList:Array):void {
			thread.push( argList[0].toString());
		}
		private function primLetterOf(thread:Thread, argList:Array):void {
			var s:String = argList[1];
			var i:int = int(argList[0]) - 1;
			if ((i < 0) || (i >= s.length)) {
				thread.push("");
			}else{
				thread.push(s.charAt(i));
			}
		}
		
		private function primModulo(thread:Thread, argList:Array):void {
			var n:Number = Number(argList[0]);
			var modulus:Number = Number(argList[1]);
			var result:Number = n % modulus;
			if (result / modulus < 0) result += modulus;
			thread.push(result);
		}
		
		private function primMathFunction(thread:Thread, argList:Array):void {
			thread.push(primMathFunctionImpl(argList));
		}
		private function primMathFunctionImpl(argList:Array):Number {
			var op:* = argList[0];
			var n:Number = Number(argList[1]);
			switch(op) {
				case "abs": return Math.abs(n);
				case "floor": return Math.floor(n);
				case "ceiling": return Math.ceil(n);
				case "int": return int(n); // used during alpha, but removed from menu
				case "sqrt": return Math.sqrt(n);
				case "sin": return Math.sin((Math.PI * n) / 180);
				case "cos": return Math.cos((Math.PI * n) / 180);
				case "tan": return Math.tan((Math.PI * n) / 180);
				case "asin": return (Math.asin(n) * 180) / Math.PI;
				case "acos": return (Math.acos(n) * 180) / Math.PI;
				case "atan": return (Math.atan(n) * 180) / Math.PI;
				case "ln": return Math.log(n);
				case "log": return Math.log(n) / Math.LN10;
				case "e ^": return Math.exp(n);
				case "10 ^": return Math.exp(n * Math.LN10);
			}
			return 0;
		}
		
		private static const lcDict:Dictionary = new Dictionary();
		public static function compare(a1:*, a2:*):int {
			// This is static so it can be used by the list "contains" primitive.
			var n1:Number = Interpreter.asNumber(a1);
			var n2:Number = Interpreter.asNumber(a2);
			if (isNaN(n1) || isNaN(n2)) {
				// at least one argument can't be converted to a number: compare as strings
				var s1:String = lcDict[a1];
				if(!s1) s1 = lcDict[a1] = String(a1).toLowerCase();
				var s2:String = lcDict[a2];
				if(!s2) s2 = lcDict[a2] = String(a2).toLowerCase();
				return s1.localeCompare(s2);
			} else {
				// compare as numbers
				if (n1 < n2) return -1;
				if (n1 == n2) return 0;
				if (n1 > n2) return 1;
			}
			return 1;
		}
		
		private function primCreateCloneOf(thread:Thread, argList:Array):void {
			var objName:String = argList[0];
			var proto:ScratchSprite = MBlock.app.stagePane.spriteNamed(objName);
			if ('_myself_' == objName) proto = thread.userData as ScratchSprite;
			if (!proto) return;
			if (MBlock.app.runtime.cloneCount > MaxCloneCount) return;
			var clone:ScratchSprite = new ScratchSprite();
			MBlock.app.stagePane.addChildAt(clone, MBlock.app.stagePane.getChildIndex(proto));
			clone.initFrom(proto, true);
			clone.objName = proto.objName;
			clone.isClone = true;
			for each (var stack:Block in clone.scripts) {
				if (stack.op == "whenCloned") {
					MBlock.app.interp.toggleThread(stack, clone);
				}
			}
			MBlock.app.runtime.cloneCount++;
		}
		
		private function primDeleteClone(thread:Thread, argList:Array):void {
			var clone:ScratchSprite = thread.userData as ScratchSprite;
			if ((clone == null) || (!clone.isClone) || (clone.parent == null)) return;
			if (clone.bubble && clone.bubble.parent) clone.bubble.parent.removeChild(clone.bubble);
			clone.parent.removeChild(clone);
			MBlock.app.interp.stopThreadsFor(clone);
			MBlock.app.runtime.cloneCount--;
		}
		
	}}
