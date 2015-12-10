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

// SensingPrims.as
// John Maloney, April 2010
//
// Sensing primitives.

package cc.makeblock.interpreter {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	import blockly.runtime.FunctionProvider;
	import blockly.runtime.Thread;
	
	import scratch.ScratchObj;
	import scratch.ScratchSprite;
	import scratch.ScratchStage;

	internal class FunctionSensing {


	public function FunctionSensing() {
	}

	public function addPrimsTo(provider:FunctionProvider):void {
		// sensing
		provider.register('touching:', primTouching);
		provider.register('touchingColor:', primTouchingColor);
		provider.register('color:sees:', primColorSees);

		provider.register('doAsk', primAsk);
		provider.register('answer', function(thread:Thread, argList:Array):void { thread.push( MBlock.app.runtime.lastAnswer) });

		provider.register('mousePressed', function(thread:Thread, argList:Array):void { thread.push( MBlock.app.gh.mouseIsDown) });
		provider.register('mouseX', function(thread:Thread, argList:Array):void { thread.push( MBlock.app.stagePane.scratchMouseX()) });
		provider.register('mouseY', function(thread:Thread, argList:Array):void { thread.push( MBlock.app.stagePane.scratchMouseY()) });
		provider.register('timer', function(thread:Thread, argList:Array):void { thread.push( MBlock.app.runtime.timer()) });
		provider.register('timerReset', function(thread:Thread, argList:Array):void { MBlock.app.runtime.timerReset() });
		provider.register('keyPressed:', primKeyPressed);
		provider.register('distanceTo:', primDistanceTo);
		provider.register('getAttribute:of:', primGetAttribute);
		provider.register('soundLevel', function(thread:Thread, argList:Array):void { thread.push( MBlock.app.runtime.soundLevel()) });
		provider.register('isLoud', function(thread:Thread, argList:Array):void { thread.push( MBlock.app.runtime.isLoud() )});
		provider.register('timestamp', primTimestamp);
		provider.register('timeAndDate', function(thread:Thread, argList:Array):void { thread.push( MBlock.app.runtime.getTimeString(argList[0])) });

		// sensor
		provider.register('sensor:', function(thread:Thread, argList:Array):void { thread.push( MBlock.app.runtime.getSensor(argList[0])) });
		provider.register('sensorPressed:', function(thread:Thread, argList:Array):void { thread.push( MBlock.app.runtime.getBooleanSensor(argList[0])) });

		// variable and list watchers
		provider.register('showVariable:', primShowWatcher);
		provider.register('hideVariable:', primHideWatcher);
		provider.register('showList:', primShowListWatcher);
		provider.register('hideList:', primHideListWatcher);
	}

	// TODO: move to stage
	static private var stageRect:Rectangle = new Rectangle(0, 0, 480, 360);
	private function primTouching(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		if (s == null) {
			thread.push(false);
			return;
		}
		var arg:* = argList[0];
		if ('_edge_' == arg) {
			if(stageRect.containsRect(s.getBounds(s.parent))) {
				thread.push(false);
				return;
			}

			var r:Rectangle = s.bounds();
			thread.push(  (r.left < 0) || (r.right > ScratchObj.STAGEW) ||
					(r.top < 0) || (r.bottom > ScratchObj.STAGEH));
			return;
		}
		if ('_mouse_' == arg) {
			thread.push( mouseTouches(s));
			return;
		}
		
		r = s.bounds();
		switch(arg)
		{
			case "top edge":
				thread.push( r.top < 0);
				return;
			case "right edge":
				thread.push( r.right > ScratchObj.STAGEW);
				return;
			case "bottom edge":
				thread.push( r.bottom > ScratchObj.STAGEH);
				return;
			case "left edge":
				thread.push( r.left < 0);
				return;
		}
		
		if (!s.visible) {
			thread.push(false);
			return;
		}

		var s2:ScratchSprite;
//		if(true || !app.isIn3D) {
			var sBM:BitmapData = s.bitmap();
			for each (s2 in MBlock.app.stagePane.spritesAndClonesNamed(arg))
				if (s2.visible && sBM.hitTest(s.bounds().topLeft, 1, s2.bitmap(), s2.bounds().topLeft, 1)){
					thread.push(true);
					return;
				}
//		}
//		else {
			// TODO: Re-implement something like the method above for rotated bitmaps.
//			var sBM:BitmapData = s.bitmap();
//            var oBM:BitmapData = new BitmapData(sBM.width, sBM.height, true, 0);
//			for each (s2 in app.stagePane.spritesAndClonesNamed(arg)) {
//				if(s2.visible) {
//					oBM.fillRect(oBM.rect, 0);
//					// now draw s2 into oBM
//					oBM.draw(s2.bitmap());
//				}
//				if (s2.visible && sBM.hitTest(s.bounds().topLeft, 1, oBM, s2.bounds().topLeft, 1))
//					return true;
//			}
//		}

		thread.push(false);
	}

	public function mouseTouches(s:ScratchSprite):Boolean {
		// True if the mouse touches the given sprite. This test is independent
		// of whether the sprite is hidden or 100% ghosted.
		// Note: p and r are in the coordinate system of the sprite's parent (i.e. the ScratchStage).
		if (!s.parent) return false;
		if(!s.getBounds(s).contains(s.mouseX, s.mouseY)) return false;
		var r:Rectangle = s.bounds();
		if (!r.contains(s.parent.mouseX, s.parent.mouseY)) return false;
		return s.bitmap().hitTest(r.topLeft, 1, new Point(s.parent.mouseX, s.parent.mouseY));
	}

//	private var testSpr:Sprite;
//	private var myBMTest:Bitmap;
//	private var stageBMTest:Bitmap;
	private function primTouchingColor(thread:Thread, argList:Array):void {
		// Note: Attempted to switch app.stage.quality to LOW to disable anti-aliasing, which
		// can create false colors. Unfortunately, that caused serious performance issues.
		var s:ScratchSprite = thread.userData;
		if (s == null){
			thread.push(false);
			return;
		}
		var c:int = int(argList[0]) | 0xFF000000;
		var myBM:BitmapData = s.bitmap(true);
		var stageBM:BitmapData = stageBitmapWithoutSpriteFilteredByColor(s, c);
//		if(s.objName == 'sensor') {
//			if(!testSpr) {
//				testSpr = new Sprite();
//				app.stage.addChild(testSpr);
//				myBMTest = new Bitmap();
//				myBMTest.y = 300;
//				testSpr.addChild(myBMTest);
//				stageBMTest = new Bitmap();
//				stageBMTest.y = 300;
//				testSpr.addChild(stageBMTest);
//			}
//			myBMTest.bitmapData = myBM;
//			stageBMTest.bitmapData = stageBM;
//			testSpr.graphics.clear();
//			testSpr.graphics.lineStyle(1);
//			testSpr.graphics.drawRect(myBM.width, 300, stageBM.width, stageBM.height);
//		}
		thread.push( myBM.hitTest(new Point(0, 0), 1, stageBM, new Point(0, 0), 1));
	}

	private function primColorSees(thread:Thread, argList:Array):void {
		// Note: Attempted to switch app.stage.quality to LOW to disable anti-aliasing, which
		// can create false colors. Unfortunately, that caused serious performance issues.
		var s:ScratchSprite = thread.userData;
		if (s == null){
			thread.push(false);
			return;
		}
		var c1:int = int(argList[0]) | 0xFF000000;
		var c2:int = int(argList[1]) | 0xFF000000;
		var myBM:BitmapData = bitmapFilteredByColor(s.bitmap(true), c1);
		var stageBM:BitmapData = stageBitmapWithoutSpriteFilteredByColor(s, c2);
//		if(!testSpr) {
//			testSpr = new Sprite();
//			testSpr.y = 300;
//			app.stage.addChild(testSpr);
//			stageBMTest = new Bitmap();
//			testSpr.addChild(stageBMTest);
//			myBMTest = new Bitmap();
//			myBMTest.filters = [new GlowFilter(0xFF00FF)];
//			testSpr.addChild(myBMTest);
//		}
//		myBMTest.bitmapData = myBM;
//		stageBMTest.bitmapData = stageBM;
//		testSpr.graphics.clear();
//		testSpr.graphics.lineStyle(1);
//		testSpr.graphics.drawRect(0, 0, stageBM.width, stageBM.height);
		thread.push( myBM.hitTest(new Point(0, 0), 1, stageBM, new Point(0, 0), 1));
	}

	// used for debugging:
	private var debugView:Bitmap;
	private function showBM(bm:BitmapData):void {
		if (debugView == null) {
			debugView = new Bitmap();
			debugView.x = 100;
			debugView.y = 600;
			MBlock.app.addChild(debugView);
		}
		debugView.bitmapData = bm;
	}

//	private var testBM:Bitmap = new Bitmap();
	private function bitmapFilteredByColor(srcBM:BitmapData, c:int):BitmapData {
//		if(!testBM.parent) {
//			testBM.y = 360; testBM.x = 15;
//			app.stage.addChild(testBM);
//		}
//		testBM.bitmapData = srcBM;
		var outBM:BitmapData = new BitmapData(srcBM.width, srcBM.height, true, 0);
		outBM.threshold(srcBM, srcBM.rect, srcBM.rect.topLeft, '==', c, 0xFF000000, 0xF0F8F8F0); // match only top five bits of each component
		return outBM;
	}

	private function stageBitmapWithoutSpriteFilteredByColor(s:ScratchSprite, c:int):BitmapData {
		return MBlock.app.stagePane.getBitmapWithoutSpriteFilteredByColor(s, c);
	}

	private function primAsk(thread:Thread, argList:Array):void {
		if (MBlock.app.runtime.askPromptShowing()) {
			thread.suspend();
			var timerId:uint = setInterval(function():void{
				if (MBlock.app.runtime.askPromptShowing()) {
					return;
				}
				clearInterval(timerId);
				primAskImpl(thread, argList);
				thread.resume();
			}, 1000);
		}else{
			primAskImpl(thread, argList);
		}
	}
	
	private function primAskImpl(thread:Thread, argList:Array):void {
		var obj:ScratchObj = thread.userData;
//		if (interp.activeThread.firstTime) {
			var question:String = argList[0];
			if ((obj is ScratchSprite) && (obj.visible)) {
				ScratchSprite(obj).showBubble(question, 'talk', true);
				MBlock.app.runtime.showAskPrompt('');
			} else {
				MBlock.app.runtime.showAskPrompt(question);
			}
			thread.suspend();
			MBlock.app.runtime.askPromptHideSignal.add(thread.resume, true);
//			interp.activeThread.firstTime = false;
//			interp.doYield();
//		} else {
//			if ((obj is ScratchSprite) && (obj.visible)) ScratchSprite(obj).hideBubble();
//			interp.activeThread.firstTime = true;
//		}
		
	}

	private function primKeyPressed(thread:Thread, argList:Array):void {
 		var key:String = argList[0];
		var ch:int = key.charCodeAt(0);
		if (ch > 127) {
			thread.push(false);
			return;
		}
		if (key == 'left arrow') ch = 28;
		if (key == 'right arrow') ch = 29;
		if (key == 'up arrow') ch = 30;
		if (key == 'down arrow') ch = 31;
		if (key == 'space') ch = 32;
		thread.push( MBlock.app.runtime.keyIsDown[ch]);
	}

	private function primDistanceTo(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		var p:Point = mouseOrSpritePosition(argList[0]);
		if ((s == null) || (p == null)) {
			thread.push(0);
			return;
		}
		var dx:Number = p.x - s.scratchX;
		var dy:Number = p.y - s.scratchY;
		thread.push( Math.sqrt((dx * dx) + (dy * dy)));
	}

	private function primGetAttribute(thread:Thread, argList:Array):void {
		thread.push(primGetAttributeImpl(argList));
	}
	private function primGetAttributeImpl(argList:Array):* {
//		var s:ScratchSprite = thread.userData;
		var attribute:String = argList[0];
		var obj:ScratchObj = MBlock.app.stagePane.objNamed(argList[1]);
		if (!(obj is ScratchObj)) return 0;
		if (obj is ScratchSprite) {
			var s:ScratchSprite = ScratchSprite(obj);
			if ('x position' == attribute) return s.scratchX;
			if ('y position' == attribute) return s.scratchY;
			if ('direction' == attribute) return s.direction;
			if ('costume #' == attribute) return s.costumeNumber();
			if ('costume name' == attribute) return s.currentCostume().costumeName;
			if ('size' == attribute) return s.getSize();
			if ('volume' == attribute) return s.volume;
		} if (obj is ScratchStage) {
			if ('background #' == attribute) return obj.costumeNumber(); // support for old 1.4 blocks
			if ('backdrop #' == attribute) return obj.costumeNumber();
			if ('backdrop name' == attribute) return obj.currentCostume().costumeName;
			if ('volume' == attribute) return obj.volume;
		}
		if (obj.ownsVar(attribute)) return obj.lookupVar(attribute).value; // variable
		return 0;
	}

	private function mouseOrSpritePosition(arg:String):Point {
		if (arg == '_mouse_') {
			var w:ScratchStage = MBlock.app.stagePane;
			return new Point(w.scratchMouseX(), w.scratchMouseY());
		} else {
			var s:ScratchSprite = MBlock.app.stagePane.spriteNamed(arg);
			if (s == null) return null;
			return new Point(s.scratchX, s.scratchY);
		}
		return null;
	}

	private function primShowWatcher(thread:Thread, argList:Array):void {
		var obj:ScratchObj = thread.userData;
		if (obj) MBlock.app.runtime.showVarOrListFor(argList[0], false, obj);
	}

	private function primHideWatcher(thread:Thread, argList:Array):void {
		var obj:ScratchObj = thread.userData;
		if (obj) MBlock.app.runtime.hideVarOrListFor(argList[0], false, obj);
	}

	private function primShowListWatcher(thread:Thread, argList:Array):void {
		var obj:ScratchObj = thread.userData;
		if (obj) MBlock.app.runtime.showVarOrListFor(argList[0], true, obj);
	}

	private function primHideListWatcher(thread:Thread, argList:Array):void {
		var obj:ScratchObj = thread.userData;
		if (obj) MBlock.app.runtime.hideVarOrListFor(argList[0], true, obj);
	}

	private function primTimestamp(thread:Thread, argList:Array):void {
		const millisecondsPerDay:int = 24 * 60 * 60 * 1000;
		const epoch:Date = new Date(2000, 0, 1); // Jan 1, 2000 (Note: Months are zero-based.)
		var now:Date = new Date();
		var dstAdjust:int = now.timezoneOffset - epoch.timezoneOffset;
		var mSecsSinceEpoch:Number = now.time - epoch.time;
		mSecsSinceEpoch += ((now.timezoneOffset - dstAdjust) * 60 * 1000); // adjust to UTC (GMT)
		thread.push( mSecsSinceEpoch / millisecondsPerDay);
	}

}}
