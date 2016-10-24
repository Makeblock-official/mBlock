package cc.makeblock.services.msoxford
{
	import com.quasimondo.bitmapdata.CameraBitmap;
	
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	
	import jp.maaash.ObjectDetection.ObjectDetector;
	import jp.maaash.ObjectDetection.ObjectDetectorEvent;
	import jp.maaash.ObjectDetection.ObjectDetectorOptions;
	public class FaceDetectionOffline
	{
		private var detector    :ObjectDetector;
		private var options     :ObjectDetectorOptions;
		
		private var view :Sprite;
		private var faceRectContainer :Sprite;
		private var tf :TextField;
		
		private var camera:CameraBitmap;
		private var detectionMap:BitmapData;
		private var drawMatrix:Matrix;
		private var scaleFactor:int = 4;
		private var w:int = 480;
		private var h:int = 360;
		
		private var lastTimer:int = 0;
		public function FaceDetectionOffline()
		{
		}
		public function start():void{
			trace("start");
			initUI();
			initDetector();
			MBlock.app.track("/OxfordAi/realtime-face/launch");
		}
		public function stop():void{
			trace("stop");
			MBlock.app.stageObj().removeEventListener(Event.RENDER,cameraReadyHandler);
			MBlock.app.track("/OxfordAi/realtime-face/close");
		}
		private function initUI():void{
			MBlock.app.stageObj().removeEventListener(Event.RENDER,cameraReadyHandler);
			MBlock.app.stageObj().addEventListener(Event.RENDER,cameraReadyHandler);
			detectionMap = new BitmapData( w / scaleFactor, h / scaleFactor, false, 0 );
			drawMatrix = new Matrix( 1/ scaleFactor, 0, 0, 1 / scaleFactor );
		}
		
		private function cameraReadyHandler( event:Event ):void
		{
			if(MBlock.app.stageObj().videoImage){
				detectionMap.draw(MBlock.app.stageObj().videoImage.bitmapData,drawMatrix,null,"normal",null,true);
				detector.detect( detectionMap );
			}
		}
		
		private function initDetector():void
		{
			detector = new ObjectDetector();
			var options:ObjectDetectorOptions = new ObjectDetectorOptions();
			options.min_size  = 30;
			detector.options = options;
			detector.addEventListener(ObjectDetectorEvent.DETECTION_COMPLETE, detectionHandler );
		}
		private function detectionHandler( e :ObjectDetectorEvent ):void
		{
			if( e.rects ){
				var results:Array = [];
				e.rects.forEach( function( r :Rectangle, idx :int, arr :Array ) :void {
					var rect:Rectangle = new Rectangle;
					rect.x = r.x * scaleFactor-240;
					rect.y = 160-r.y * scaleFactor;
					rect.width = (r.width * scaleFactor);
					rect.height = (r.height * scaleFactor)*0.8;
					results.push(rect);
				});
				if(results.length>0){
					MBlock.app.extensionManager.extensionByName("Microsoft Cognitive Services").stateVars["realFaceResultReceived"] = results;
					MBlock.app.runtime.realFaceResultReceived.notify(true);
				}
			}
		}
	}
}