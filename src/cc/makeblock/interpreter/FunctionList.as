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

// ListPrimitives.as
// John Maloney, September 2010
//
// List primitives.

package cc.makeblock.interpreter {
	
	import blockly.runtime.FunctionProvider;
	import blockly.runtime.Thread;
	
	import scratch.ScratchObj;
	
	import watchers.ListWatcher;

internal class FunctionList {


	public function FunctionList() {
	}

	public function addPrimsTo(provider:FunctionProvider):void {
		provider.register(Specs.GET_LIST, primContents);
		provider.register('append:toList:', primAppend);
		provider.register('deleteLine:ofList:', primDelete);
		provider.register('insert:at:ofList:', primInsert);
		provider.register('setLine:ofList:to:', primReplace);
		provider.register('getLine:ofList:', primGetItem);
		provider.register('lineCountOfList:', primLength);
		provider.register('list:contains:', primContains);
	}

	private function primContents(thread:Thread, argList:Array):void
	{
		var list:ListWatcher = thread.userData.lookupOrCreateList(argList[0]);
		if(null == list){
			thread.push("");
			return;
		}
		var allSingleLetters:Boolean = true;
		for each (var el:* in list.contents) {
			if (!((el is String) && (el.length == 1))) {
				allSingleLetters = false;
				break;
			}
		}
		thread.push(list.contents.join(allSingleLetters ? '' : ' '));
	}

	private function primAppend(thread:Thread, argList:Array):void {
		var list:ListWatcher = listarg(thread.userData, argList, 1);
		if (!list) return;
		var v:* = argList[0];
		if(v!=null){
			listAppend(list, v);
		}
		//避免在请求数据时添加空数据。
		if (list.visible) list.updateWatcher(list.contents.length, false);
	}

	protected function listAppend(list:ListWatcher, item:*):void {
		list.contents.push(item);
	}

	private function primDelete(thread:Thread, argList:Array):void {
		var which:* = argList[0];
		var list:ListWatcher = listarg(thread.userData, argList, 1);
		if (!list) return;
		var len:int = list.contents.length;
		if (which == 'all') {
			listSet(list, []);
			if (list.visible) list.updateWatcher(-1, false);
		}
		var n:Number = (which == 'last') ? len : Number(which);
		if (isNaN(n)) return;
		var i:int = Math.round(n);
		if ((i < 1) || (i > len)) return;
		listDelete(list, i);
		if (list.visible) list.updateWatcher(((i == len) ? i - 1 : i), false);
	}

	protected function listSet(list:ListWatcher, newValue:Array):void {
		list.contents = newValue;
	}

	protected function listDelete(list:ListWatcher, i:int):void {
		list.contents.splice(i - 1, 1);
	}

	private function primInsert(thread:Thread, argList:Array):void {
		var val:* = argList[0];
		var where:* = argList[1];
		var list:ListWatcher = listarg(thread.userData, argList, 2);
		if (!list) return;
		if (where == 'last') {
			listAppend(list, val);
			if (list.visible) list.updateWatcher(list.contents.length, false);
		} else {
			var i:int = computeIndex(where, list.contents.length + 1);
			if (i < 0) return;
			listInsert(list, i, val);
			if (list.visible) list.updateWatcher(i, false);
		}
	}

	protected function listInsert(list:ListWatcher, i:int, item:*):void {
		list.contents.splice(i - 1, 0, item);
	}

	private function primReplace(thread:Thread, argList:Array):void {
		var list:ListWatcher = listarg(thread.userData, argList, 1);
		if (!list) return;
		var i:int = computeIndex(argList[0], list.contents.length);
		if (i < 0) return;
		listReplace(list, i, argList[2]);
		if (list.visible) list.updateWatcher(i, false);
	}

	protected function listReplace(list:ListWatcher, i:int, item:*):void {
		list.contents.splice(i - 1, 1, item);
	}

	private function primGetItem(thread:Thread, argList:Array):void {
		var list:ListWatcher = listarg(thread.userData, argList, 1);
		if (!list) {
			thread.push("");
			return;
		}
		var i:int = computeIndex(argList[0], list.contents.length);
		if (i < 0){
			thread.push("");
			return;
		}
		if (list.visible) list.updateWatcher(i, true);
		thread.push( list.contents[i - 1]);
	}

	private function primLength(thread:Thread, argList:Array):void {
		var list:ListWatcher = listarg(thread.userData, argList, 0);
		thread.push(list ? list.contents.length : 0);
	}

	private function primContains(thread:Thread, argList:Array):void {
		var list:ListWatcher = listarg(thread.userData, argList, 0);
		if (!list) {
			thread.push(false);
			return
		}
		var item:* = argList[1];
		if (list.contents.indexOf(item) >= 0) {
			thread.push(true);
			return;
		}
		for each (var el:* in list.contents) {
			// use Scratch comparision operator (Scratch considers the string '123' equal to the number 123)
			if (Primitives.compare(el, item) == 0) {
				thread.push(true);
				return;
			}
		}
		thread.push(false);
	}

	private function listarg(obj:ScratchObj, argList:Array, i:int):ListWatcher {
		var listName:String = argList[i];
		if (listName.length == 0) return null;
		var result:ListWatcher = obj.listCache[listName];
		if (!result) {
			result = obj.listCache[listName] = obj.lookupOrCreateList(listName);
		}
		return result;
	}

	private function computeIndex(n:*, len:int):int {
		var i:int;
		if (!(n is Number)) {
			if (n == 'last') return (len == 0) ? -1 : len;
			if ((n ==  'any') || (n == 'random')) return (len == 0) ? -1 : 1 + Math.floor(Math.random() * len);
			n = Number(n);
			if (isNaN(n)) return -1;
		}
		i = (n is int) ? n : Math.floor(n);
		if ((i < 1) || (i > len)) return -1;
		return i;
	}

}}
