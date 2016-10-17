package com.quasimondo.bitmapdata
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.utils.Timer;
	import flash.utils.setTimeout;
	
	public class CameraBitmap extends EventDispatcher
	{
		[Event(name="Event.RENDER", type="flash.events.Event")]

		public var bitmapData:BitmapData;
		
		private var __width:int;
		private var __height:int;
		
		private var __cam:Camera;
		private var __video:Video;
		
		private var __refreshRate:int;
		private var __timer:Timer;
		private var __paintMatrix:Matrix;
		private var __smooth:Boolean;
		private var __colorTransform:ColorTransform;
		private var __colorMatrix:Array;
		private var __colorMatrixFilter:ColorMatrixFilter = new ColorMatrixFilter();
		
		private const CAMERA_DELAY:int = 100;
		private const origin:Point = new Point();
		
		public function CameraBitmap( width:int, height:int, refreshRate:int = 15, cameraWidth:int = -1, cameraHeight:int = -1 )
		{
			__width  = width;
			__height = height;
			
			bitmapData = new BitmapData( width, height, false, 0 );
			
			__cam = Camera.getCamera();
			if ( cameraWidth == -1 || cameraHeight == -1 )
			{
				__cam.setMode( width, height, refreshRate, true );
			} else {
				__cam.setMode( cameraWidth, cameraHeight, refreshRate, true );
			}
			__refreshRate = refreshRate;
			
			setTimeout( cameraInit, CAMERA_DELAY );
		}
		
		public function set active( value:Boolean ):void
		{
			if ( value ) __timer.start() else __timer.stop();
		}

		public function close():void
		{
			active = false;
			__video.attachCamera(null);
			__video = null;
			__cam = null;
		}
		public function set refreshRate( value:int ):void
		{
			__refreshRate = value;
			__timer.delay = 1000 / __refreshRate;
		}
		
		public function set cameraColorTransform( value:ColorTransform ):void
		{
			__colorTransform = value;
		}
		
		public function set colorMatrix( value:Array ):void
		{
			__colorMatrixFilter.matrix = __colorMatrix = value;
		}
		
		private function cameraInit():void
		{
			__video = new Video( __cam.width, __cam.height );
			__video.attachCamera( __cam );
			
			__paintMatrix = new Matrix( __width / __cam.width, 0, 0, __height / __cam.height, 0, 0 );
			__smooth = __paintMatrix.a != 1 || __paintMatrix.d != 1
			
			__timer = new Timer( 1000 / __refreshRate );
			__timer.addEventListener(TimerEvent.TIMER, paint );
			__timer.start(); 
		}
		
		private function paint( event:TimerEvent = null ):void
		{
			bitmapData.lock();
			bitmapData.draw ( __video, __paintMatrix, __colorTransform, "normal", null, __smooth );
			if ( __colorMatrix != null )
			{
				bitmapData.applyFilter( bitmapData, bitmapData.rect, origin, __colorMatrixFilter );
			}
			bitmapData.unlock();
			dispatchEvent( new Event( Event.RENDER ) );
		}
		
	}
}