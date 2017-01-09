package cc.makeblock.services.msoxford
{
	import com.google.analytics.core.Utils;
	
	import flash.display.BitmapData;
	import flash.display.JPEGEncoderOptions;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.media.Video;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.utils.ByteArray;
	
	import util.JSON;
	import util.SharedObjectManager;

	public class EmotionDetection
	{
		private var _vid:Video;
		private var _time:Number = 0;
		private var _source:String = "system";
		public function EmotionDetection()
		{
			
		}
		public function capture():void{
			if(_vid==null){
				_vid = MBlock.app.stageObj().currentVideo;
			}
			if(new Date().time-_time>4000){
				_time = new Date().time;
			}else{
				return;
			}
			if(!_vid){
				return;
			}
			var bmd:BitmapData = new BitmapData(_vid.width,_vid.height,true,0);
			var matrix:Matrix = new Matrix;
			matrix.a = -1;
			matrix.tx = _vid.width;
			bmd.draw(_vid,matrix);
			var bytes:ByteArray = new ByteArray;
			bmd.encode(bmd.rect,new JPEGEncoderOptions(60),bytes);
			bytes.position = 0;
			var urlloader:URLLoader = new URLLoader; 
			
			urlloader.dataFormat = URLLoaderDataFormat.BINARY;
			var req:URLRequest = new URLRequest();
			req.url = "https://api.projectoxford.ai/emotion/v1.0/recognize";
			req.method = URLRequestMethod.POST;
			req.data = bytes;
			var secret:String = SharedObjectManager.sharedManager().getObject("keyEmotion-user","");//;
			if(secret.length<10){
				secret = SharedObjectManager.sharedManager().getObject("keyEmotion-system","");
			}else{
				_source = "user";
			}
			if(secret.length<10){
				return;
			}
			MBlock.app.track("/OxfordAi/emotion/launch/"+_source);
			req.requestHeaders.push(new URLRequestHeader("Content-Type","application/octet-stream"));
			req.requestHeaders.push(new URLRequestHeader("Ocp-Apim-Subscription-Key",secret));
			urlloader.addEventListener(Event.COMPLETE,onRequestComplete);
			urlloader.addEventListener(IOErrorEvent.IO_ERROR,onIOError);
			urlloader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS,onHttpStatus);
			urlloader.load(req);
		}
		private function onRequestComplete(evt:Event):void{
			MBlock.app.track("/OxfordAi/emotion/success/"+_source);
			var ret:*;
			if(evt.target.data.toString().indexOf("xmlns")>-1){
				try{
					ret = new XML(evt.target.data);
					if (ret.namespace("") != undefined) 
					{ 
						default xml namespace = ret.namespace(""); 
					}
					var len:uint = ret.FaceRecognitionResult.length();
					var result:Array = [];
					for(var i:uint=0;i<len;i++){
						var h:uint = ret.FaceRecognitionResult[i].faceRectangle.height;
						var w:uint = ret.FaceRecognitionResult[i].faceRectangle.width;
						var l:uint = ret.FaceRecognitionResult[i].faceRectangle.left;
						var t:uint = ret.FaceRecognitionResult[i].faceRectangle.top;
						var obj:Object = {};
						obj.x = l;
						obj.y = t;
						obj.width = w;
						obj.height = h;
						obj.anger = Math.round(ret.FaceRecognitionResult[i].scores.anger*100);
						obj.contempt = Math.round(ret.FaceRecognitionResult[i].scores.contempt*100);
						obj.disgust = Math.round(ret.FaceRecognitionResult[i].scores.disgust*100);
						obj.fear = Math.round(ret.FaceRecognitionResult[i].scores.fear*100);
						obj.happiness = Math.round(ret.FaceRecognitionResult[i].scores.happiness*100);
						obj.neutral = Math.round(ret.FaceRecognitionResult[i].scores.neutral*100);
						obj.sadness = Math.round(ret.FaceRecognitionResult[i].scores.sadness*100);
						obj.surprise = Math.round(ret.FaceRecognitionResult[i].scores.surprise*100);
						result.push(obj);
					}
					if(len>0){
						MBlock.app.extensionManager.extensionByName("Microsoft Cognitive Services").stateVars["emotionResultReceived"] = result;
						MBlock.app.runtime.emotionResultReceived.notify(true);
					}
				}catch(e:*){
					
				}
				return;
			}
			ret = util.JSON.parse(evt.target.data);
			var len:uint = ret.length;
			var result:Array = [];
			for(var i:uint=0;i<len;i++){
				var h:uint = ret[i].faceRectangle.height;
				var w:uint = ret[i].faceRectangle.width;
				var l:uint = ret[i].faceRectangle.left;
				var t:uint = ret[i].faceRectangle.top;
				var obj:Object = {};
				obj.x = l;
				obj.y = t;
				obj.width = w;
				obj.height = h;
				obj.anger = Math.round(ret[i].scores.anger*100);
				obj.contempt = Math.round(ret[i].scores.contempt*100);
				obj.disgust = Math.round(ret[i].scores.disgust*100);
				obj.fear = Math.round(ret[i].scores.fear*100);
				obj.happiness = Math.round(ret[i].scores.happiness*100);
				obj.neutral = Math.round(ret[i].scores.neutral*100);
				obj.sadness = Math.round(ret[i].scores.sadness*100);
				obj.surprise = Math.round(ret[i].scores.surprise*100);
				result.push(obj);
			}
			if(len>0){
				MBlock.app.extensionManager.extensionByName("Microsoft Cognitive Services").stateVars["emotionResultReceived"] = result;
				MBlock.app.runtime.emotionResultReceived.notify(true);
			}
		}
		private function onIOError(evt:IOErrorEvent):void{
			trace("error：",evt);
			MBlock.app.track("/OxfordAi/emotion/error/"+_source);
		}
		private function onHttpStatus(evt:HTTPStatusEvent):void{
			trace("Status:",evt);
		}
	}
}