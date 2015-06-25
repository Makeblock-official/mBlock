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

// PaletteSelector.as
// John Maloney, August 2009
//
// PaletteSelector is a UI widget that holds set of PaletteSelectorItems
// and supports changing the selected category. When the category is changed,
// the blocks palette is filled with the blocks for the selected category.

package ui {
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.filters.ColorMatrixFilter;
	
	import scratch.PaletteBuilder;
	
	import translation.Translator;

public class PaletteSelector extends Sprite {

	private static const categories:Array = [
		'Motion', 'Looks', 'Sound', 'Pen', 'Data&Blocks', // column 1
		'Events', 'Control', 'Sensing', 'Operators', 'Robots']; // column 2

	public var selectedCategory:int = 0;
	private var app:MBlock;

	public function PaletteSelector(app:MBlock) {
		this.app = app;
		initCategories();
	}

	public static function strings():Array { return categories }
	public function updateTranslation():void { initCategories() }

	public function select(id:int, shiftKey:Boolean = false):void {
		for (var i:int = 0; i < numChildren; i++) {
			var item:PaletteSelectorItem = getChildAt(i) as PaletteSelectorItem;
			item.setSelected(item.categoryID == id);
			if(i<=3||i==5||i==7){
				if(app.stageIsArduino){
					item.mouseEnabled = false;
					item.mouseChildren = false;
					item.alpha = 0.4;
				}else{
					item.mouseEnabled = true;
					item.mouseChildren = true;
					item.alpha = 1.0;
				}
			}
		}
		var oldID:int = selectedCategory;
		selectedCategory = id;
		app.getPaletteBuilder().showBlocksForCategory(selectedCategory, (id != oldID), shiftKey);
	}

	private function initCategories():void {
		const numberOfRows:int = 5;
		const w:int = 208+60;
		const startY:int = 3;
		var itemH:int;
		var x:int, i:int;
		var y:int = startY;
		while (numChildren > 0) removeChildAt(0); // remove old contents

		for (i = 0; i < categories.length; i++) {
			if (i == numberOfRows) {
				x = (w / 2) - 3;
				y = startY;
			}
			var entry:Array = Specs.entryForCategory(categories[i]);
			var item:PaletteSelectorItem = new PaletteSelectorItem(entry[0], Translator.map(entry[1]), entry[2]);
			itemH = item.height;
			item.x = x;
			item.y = y;
			addChild(item);
			y += itemH;
		}
		setWidthHeightColor(w, startY + (numberOfRows * itemH) + 5);
	}

	private function setWidthHeightColor(w:int, h:int):void {
		var g:Graphics = graphics;
		g.clear();
		g.beginFill(0x000000, 0); // invisible (alpha = 0) rectangle used to set size
		g.drawRect(0, 0, w, h);
	}

}}
