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

// MotionAndPenPrims.as
// John Maloney, April 2010
//
// Scratch motion and pen primitives.

package cc.makeblock.interpreter {
	import com.greensock.TweenLite;
	
	import flash.display.Graphics;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import blockly.runtime.FunctionProvider;
	import blockly.runtime.Thread;
	
	
	import scratch.ScratchObj;
	import scratch.ScratchSprite;
	import scratch.ScratchStage;

	internal class FunctionMotionAndPen {

	public function FunctionMotionAndPen() {
	}

	public function addPrimsTo(provider:FunctionProvider):void {
		provider.register("forward:", primMove);
		provider.register("turnRight:", primTurnRight);
		provider.register("turnLeft:", primTurnLeft);
		provider.register("heading:", primSetDirection);
		provider.register("pointTowards:", primPointTowards);
		provider.register("gotoX:y:", primGoTo);
		provider.register("gotoSpriteOrMouse:", primGoToSpriteOrMouse);
		provider.register("glideSecs:toX:y:elapsed:from:", primGlide);

		provider.register("changeXposBy:", primChangeX);
		provider.register("xpos:", primSetX);
		provider.register("changeYposBy:", primChangeY);
		provider.register("ypos:", primSetY);

		provider.register("bounceOffEdge", primBounceOffEdge);

		provider.register("xpos", primXPosition);
		provider.register("ypos", primYPosition);
		provider.register("heading", primDirection);

		provider.register("clearPenTrails", primClear);
		provider.register("putPenDown", primPenDown);
		provider.register("putPenUp", primPenUp);
		provider.register("penColor:", primSetPenColor);
		provider.register("setPenHueTo:", primSetPenHue);
		provider.register("changePenHueBy:", primChangePenHue);
		provider.register("setPenShadeTo:", primSetPenShade);
		provider.register("changePenShadeBy:", primChangePenShade);
		provider.register("penSize:", primSetPenSize);
		provider.register("changePenSizeBy:", primChangePenSize);
		provider.register("stampCostume", primStamp);
	}

	private function primMove(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		if (s == null) return;
		var radians:Number = (Math.PI * (90 - s.direction)) / 180;
		var d:Number = Number(argList[0]);
		moveSpriteTo(s, s.scratchX + (d * Math.cos(radians)), s.scratchY + (d * Math.sin(radians)));
	}

	private function primTurnRight(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		if (s != null) s.setDirection(s.direction + Number(argList[0]));
	}

	private function primTurnLeft(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		if (s != null) s.setDirection(s.direction - Number(argList[0]));
	}

	private function primSetDirection(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		if (s != null) s.setDirection(Number(argList[0]));
	}

	private function primPointTowards(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		var p:Point = mouseOrSpritePosition(s,argList[0]);
		if ((s == null) || (p == null)) return;
		var dx:Number = p.x - s.scratchX;
		var dy:Number = p.y - s.scratchY;
		var angle:Number = 90 - ((Math.atan2(dy, dx) * 180) / Math.PI);
		s.setDirection(angle);
	}

	private function primGoTo(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		if (s != null) moveSpriteTo(s, Number(argList[0]), Number(argList[1]));
	}

	private function primGoToSpriteOrMouse(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		var p:Point = mouseOrSpritePosition(s,argList[0]);
		if ((s == null) || (p == null)) return;
		moveSpriteTo(s, p.x, p.y);
	}

	private function primGlide(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		if (s == null) return;
		var secs:Number = Number(argList[0]);
		var destX:Number = Number(argList[1]);
		var destY:Number = Number(argList[2]);
		if (secs <= 0) {
			moveSpriteTo(s, destX, destY);
			return;
		}
		thread.suspend();
		// record state: [0]start msecs, [1]duration, [2]startX, [3]startY, [4]endX, [5]endY
//		[interp.currentMSecs, 1000 * secs, s.scratchX, s.scratchY, destX, destY];
		// in progress: move to intermediate position along path
//		var frac:Number = (interp.currentMSecs - state[0]) / state[1];
//		var newX:Number = state[2] + (frac * (state[4] - state[2]));
//		var newY:Number = state[3] + (frac * (state[5] - state[3]));
		var obj:Object = {"x":s.scratchX,"y":s.scratchY}
		TweenLite.to(obj, secs, {"x":destX, "y":destY,"onUpdate":function():void{
				moveSpriteTo(s, obj.x, obj.y);
			},"onComplete":thread.resume}
		);
	}

	private function mouseOrSpritePosition(targetSprite:ScratchSprite, arg:String):Point {
		var w:ScratchStage = MBlock.app.stagePane;
		var pt:Point;
		switch(arg)
		{
			case "_mouse_":
				pt = new Point(w.scratchMouseX(), w.scratchMouseY());
				break;
			case "rhp":
				pt = new Point(w.width * (Math.random() - 0.5), targetSprite.scratchY);
				break;
			case "rvp":
				pt = new Point(targetSprite.scratchX, w.height * (Math.random() - 0.5));
				break;
			case "rsp":
				pt = new Point(w.width * (Math.random() - 0.5), w.height * (Math.random() - 0.5));
				break;
			default:
				var s:ScratchSprite = MBlock.app.stagePane.spriteNamed(arg);
				if (s == null) return null;
				pt = new Point(s.scratchX, s.scratchY);
		}
		return pt;
	}

	private function primChangeX(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		if (s != null) moveSpriteTo(s, s.scratchX + Number(argList[0]), s.scratchY);
	}

	private function primSetX(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		if (s != null) moveSpriteTo(s, Number(argList[0]), s.scratchY);
	}

	private function primChangeY(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		if (s != null) moveSpriteTo(s, s.scratchX, s.scratchY + Number(argList[0]));
	}

	private function primSetY(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		if (s != null) moveSpriteTo(s, s.scratchX, Number(argList[0]));
	}

	private function primBounceOffEdge(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		if (s == null) return;
		if (!turnAwayFromEdge(s)) return;
		ensureOnStageOnBounce(s);
	}

	private function primXPosition(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		thread.push( (s != null) ? snapToInteger(s.scratchX) : 0);
	}

	private function primYPosition(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		thread.push( (s != null) ? snapToInteger(s.scratchY) : 0);
	}

	private function primDirection(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		thread.push( (s != null) ? snapToInteger(s.direction) : 0);
	}

	private function snapToInteger(n:Number):Number {
		var rounded:Number = Math.round(n);
		var delta:Number = n - rounded;
		if (delta < 0) delta = -delta;
		return (delta < 1e-9) ? rounded : n;
	}

	private function primClear(thread:Thread, argList:Array):void {
		MBlock.app.stagePane.clearPenStrokes();
	}

	private function primPenDown(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		if (s != null) s.penIsDown = true;
		stroke(s, s.scratchX, s.scratchY, s.scratchX + 0.2, s.scratchY + 0.2);
	}

	private function primPenUp(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		if (s != null) s.penIsDown = false;
	}

	private function primSetPenColor(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		if (s != null) s.setPenColor(Number(argList[0]));
	}

	private function primSetPenHue(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		if (s != null) s.setPenHue(Number(argList[0]));
	}

	private function primChangePenHue(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		if (s != null) s.setPenHue(s.penHue + Number(argList[0]));
	}

	private function primSetPenShade(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		if (s != null) s.setPenShade(Number(argList[0]));
	}

	private function primChangePenShade(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		if (s != null) s.setPenShade(s.penShade + Number(argList[0]));
	}

	private function primSetPenSize(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		if (s != null) s.setPenSize(Math.max(1, Math.min(960, Math.round(Number(argList[0])))));
	}

	private function primChangePenSize(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		if (s != null) s.setPenSize(s.penWidth + Number(argList[0]));
	}

	private function primStamp(thread:Thread, argList:Array):void {
		var s:ScratchSprite = thread.userData;
		doStamp(s, s.img.transform.colorTransform.alphaMultiplier);
	}

	private function doStamp(s:ScratchSprite, stampAlpha:Number):void {
		if (s == null) return;
		MBlock.app.stagePane.stampSprite(s, stampAlpha);
	}

	private function moveSpriteTo(s:ScratchSprite, newX:Number, newY:Number):void {
		if (!(s.parent is ScratchStage)) return; // don't move while being dragged
		var oldX:Number = s.scratchX;
		var oldY:Number = s.scratchY;
		s.setScratchXY(newX, newY);
		s.keepOnStage();
		if (s.penIsDown) stroke(s, oldX, oldY, s.scratchX, s.scratchY);
	}

	private function stroke(s:ScratchSprite, oldX:Number, oldY:Number, newX:Number, newY:Number):void {
		var g:Graphics = MBlock.app.stagePane.newPenStrokes.graphics;
		g.lineStyle(s.penWidth, s.penColorCache);
		g.moveTo(240 + oldX, 180 - oldY);
		g.lineTo(240 + newX, 180 - newY);
//trace('pen line('+oldX+', '+oldY+', '+newX+', '+newY+')');
		MBlock.app.stagePane.penActivity = true;
	}

	private function turnAwayFromEdge(s:ScratchSprite):Boolean {
		// turn away from the nearest edge if it's close enough; otherwise do nothing
		// Note: comparisions are in the stage coordinates, with origin (0, 0)
		// use bounding rect of the sprite to account for costume rotation and scale
		var r:Rectangle = s.getRect(MBlock.app.stagePane);
		// measure distance to edges
		var d1:Number = Math.max(0, r.left);
		var d2:Number = Math.max(0, r.top);
		var d3:Number = Math.max(0, ScratchObj.STAGEW - r.right);
		var d4:Number = Math.max(0, ScratchObj.STAGEH - r.bottom);
		// find the nearest edge
		var e:int = 0, minDist:Number = 100000;
		if (d1 < minDist) { minDist = d1; e = 1 }
		if (d2 < minDist) { minDist = d2; e = 2 }
		if (d3 < minDist) { minDist = d3; e = 3 }
		if (d4 < minDist) { minDist = d4; e = 4 }
		if (minDist > 0) return false;  // not touching to any edge
		// point away from nearest edge
		var radians:Number = ((90 - s.direction) * Math.PI) / 180;
		var dx:Number = Math.cos(radians);
		var dy:Number = -Math.sin(radians);
		if (e == 1) { dx = Math.max(0.2, Math.abs(dx)) }
		if (e == 2) { dy = Math.max(0.2, Math.abs(dy)) }
		if (e == 3) { dx = 0 - Math.max(0.2, Math.abs(dx)) }
		if (e == 4) { dy = 0 - Math.max(0.2, Math.abs(dy)) }
		var newDir:Number = ((180 * Math.atan2(dy, dx)) / Math.PI) + 90;
		s.setDirection(newDir);
		return true;
	}

	private function ensureOnStageOnBounce(s:ScratchSprite):void {
		var r:Rectangle = s.getRect(MBlock.app.stagePane);
		if (r.left < 0) moveSpriteTo(s, s.scratchX - r.left, s.scratchY);
		if (r.top < 0) moveSpriteTo(s, s.scratchX, s.scratchY + r.top);
		if (r.right > ScratchObj.STAGEW) {
			moveSpriteTo(s, s.scratchX - (r.right - ScratchObj.STAGEW), s.scratchY);
		}
		if (r.bottom > ScratchObj.STAGEH) {
			moveSpriteTo(s, s.scratchX, s.scratchY + (r.bottom - ScratchObj.STAGEH));
		}
	}

}}
