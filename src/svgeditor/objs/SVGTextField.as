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

package svgeditor.objs
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.filters.BlurFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Transform;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.text.TextLineMetrics;
	import flash.utils.setTimeout;
	
	import svgeditor.objs.ISVGEditable;
	
	import svgutils.SVGDisplayRender;
	import svgutils.SVGElement;
	
	public class SVGTextField extends Sprite implements ISVGEditable
	{
		private var element:SVGElement;
		private var _editable:Boolean;
		private var _tf:TextField = new TextField;
		private var _ttf:TextField = new TextField;
		private var _tfOri:TextField = new TextField;
		public function SVGTextField(elem:SVGElement=null) {
			element = elem;
			if(element){
				if (element.text == null) element.text = '';
			}
			_editable = false;
			_tf.antiAliasType = AntiAliasType.ADVANCED;
			_tf.cacheAsBitmap = true;
			_tf.embedFonts = false;
			_tf.backgroundColor = 0xFFFFFF;
			_tf.multiline = true;
			this.cacheAsBitmap = true;
			this.cacheAsBitmapMatrix = new Matrix;
			_ttf.antiAliasType = AntiAliasType.ADVANCED;
			_ttf.cacheAsBitmap = true;
			_ttf.cacheAsBitmapMatrix = new Matrix;
			_ttf.embedFonts = false;
			_ttf.backgroundColor = 0xFFFFFF;
			_ttf.multiline = true;
			_ttf.selectable = true;
			_ttf.type = TextFieldType.INPUT;
			_tf.alpha = 0;
			addChild(_tf);
			addChild(_ttf);
			_ttf.rotationX = 0;
			_ttf.addEventListener(Event.CHANGE,onChanged);
			_tf.addEventListener(FocusEvent.FOCUS_IN,onFocusIn);
			addEventListener(Event.ADDED_TO_STAGE, addedStage);
		}
		private function onFocusIn(evt:FocusEvent):void{
			setTimeout(function():void{
				_ttf.setSelection(0,0);
				if(stage){
					stage.focus = _ttf;
					if(element){
						var ascent:Number = getLineMetrics(0).ascent;
						element.setAttribute('x', _tfOri.transform.matrix.tx + 2);
						element.setAttribute('y', _tfOri.transform.matrix.ty + 2 + ascent);
					}
				}
			},100);
		}
		private function addedStage(evt:Event):void{
			setTimeout(function():void{
			_ttf.setSelection(0,0);
			stage.focus = _ttf;
			},100);
		}
		private function onChanged(evt:Event):void{
			element.text = _ttf.text;
			_tf.text = element.text;
			redraw();
		}
		public function getElement():SVGElement {
			_tfOri.x = this.x;
			_tfOri.y = this.y;
			_tfOri.width = this.width;
			_tfOri.height = this.height;
			_tfOri.scaleX = this.scaleX;
			_tfOri.scaleY = this.scaleY;
			_tfOri.rotation = this.rotation;
			element.transform = _tfOri.transform.matrix.clone();
			return element;
		}
		public function getTransform():Matrix{
			return this.transform.matrix;
		}
		public function get original():TextField{
			return _tfOri;
		}
		public function get textfield3D():TextField{
			return _ttf;
		}
		public function redraw(forHitTest:Boolean = false):void {
			var fixup:Boolean = (_tf.type == TextFieldType.INPUT && element.text.length < 4);
			var origText:String = element.text;
			if(element.text == "") {};
			element.renderSVGTextOn(this);
			element.text = origText;
			if(fixup) _tf.width += 25;
		}
		//----------------------------------
		override public function set x(v:Number):void{
			super.x = v;
		}
		public function set defaultTextFormat(v:TextFormat):void{
			_tf.defaultTextFormat = v;
		}
		public function set embedFonts(v:Boolean):void{
			_tf.embedFonts = v;
		}
		public function set antiAliasType(v:String):void{
			_tf.antiAliasType = v;
		}
		public function set background(v:Boolean):void{
			_tf.background = v;
		}
		public function set type(v:String):void{
			_tf.type = v;
			updateTextDisplay();
		}
		public function get type():String{
			return _tf.type;
		}
		public function set autoSize(v:String):void{
			_tf.autoSize = v;
			updateTextDisplay();
		}
		public function get selectable():Boolean{
			return _tf.selectable;
		}
		public function set selectable(v:Boolean):void{
			_tf.selectable = v;
			updateTextDisplay();
		}
		public function get textfield():TextField{
			return _tf;
		}
		public function get textWidth():uint{
			return _tf.textWidth;
		}
		public function get textHeight():uint{
			return _tf.textHeight;
		}
		public function get textColor():uint{
			return _tf.textColor;
		}
		public function set textColor(v:uint):void{
			_tf.textColor = v;
			updateTextDisplay();
		}
		public function getLineMetrics(v:int):TextLineMetrics{
			return _tf.getLineMetrics(v);
		}
		public function get text():String{
			updateTextDisplay();
			return _tf.text;
		}
		public function set text(v:String):void{
			_tf.text = v;
			updateTextDisplay();
		}
		public function setTextFormat(v:TextFormat):void{
			_tf.setTextFormat(v);
			updateTextDisplay();
		}
		private function updateTextDisplay():void{
			_ttf.height = _tf.height;
			_ttf.width = _tf.width;
			_ttf.type = _tf.type;
			_ttf.defaultTextFormat = _tf.defaultTextFormat;
			_ttf.embedFonts = _tf.embedFonts;
			_ttf.background = _tf.background;
			_ttf.backgroundColor = _tf.backgroundColor;
			_ttf.antiAliasType = _tf.antiAliasType;
			_ttf.textColor = _tf.textColor;
			_ttf.autoSize = _tf.autoSize;
			_ttf.selectable = _tf.selectable;
			_ttf.text = _tf.text;
//			trace(x,_tf.text,_tf.width,_tf.height);
//			_ttf.x = _tf.x;
//			_ttf.y = _tf.y;
//			_ttf.setTextFormat(_tf.getTextFormat());
		}
		public function clone():ISVGEditable {
			var copy:SVGTextField = new SVGTextField(element.clone());
			copy.transform.matrix = _tfOri.transform.matrix.clone();
			copy.selectable = false;
			copy.redraw();
			return copy as ISVGEditable;
		}
	}
}