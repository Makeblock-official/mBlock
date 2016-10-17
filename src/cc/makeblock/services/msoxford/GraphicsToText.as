package cc.makeblock.services.msoxford
{
	import flash.display.BitmapData;
	import flash.display.JPEGEncoderOptions;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.geom.Matrix;
	import flash.media.Video;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.utils.ByteArray;
	
	import util.SharedObjectManager;
	
	public class GraphicsToText 
	{
		private var _vid:Video;
		//d30bb3fa0e40461eaf1d0b11b609a75a
		public function GraphicsToText()
		{
			
		}
		public function capture():void{
			if(_vid==null){
				_vid = MBlock.app.stageObj().currentVideo;
			}
			var bmd:BitmapData = new BitmapData(_vid.width,_vid.height,true,0);
			var matrix:Matrix = new Matrix;
			//matrix.a = 1;
			//matrix.tx = _vid.width;
			bmd.draw(_vid,matrix);
			var bytes:ByteArray = new ByteArray;
			bmd.encode(bmd.rect,new JPEGEncoderOptions(60),bytes);
			bytes.position = 0;
			var urlloader:URLLoader = new URLLoader;
			
			urlloader.dataFormat = URLLoaderDataFormat.BINARY;
			var req:URLRequest = new URLRequest();
			req.url = "https://api.projectoxford.ai/vision/v1/ocr?language=unk&detectOrientation=true";
			req.method = URLRequestMethod.POST;
			req.data = bytes;
			var secret:String = SharedObjectManager.sharedManager().getObject("keyOCR","d30bb3fa0e40461eaf1d0b11b609a75a");//;
			if(secret.length<10){
				return;
			}
			MBlock.app.track("/OxfordAi/OCR/launch");
			req.requestHeaders.push(new URLRequestHeader("Content-Type","application/octet-stream"));
			req.requestHeaders.push(new URLRequestHeader("Ocp-Apim-Subscription-Key",secret));
			urlloader.addEventListener(Event.COMPLETE,onRequestComplete);
			urlloader.addEventListener(IOErrorEvent.IO_ERROR,onIOError);
			urlloader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS,onHttpStatus);
			urlloader.load(req);
		}
		private function onRequestComplete(evt:Event):void{
			MBlock.app.track("/OxfordAi/OCR/success");
			var ret:Object = JSON.parse(evt.target.data);
			var regions:Array = ret.regions;
			var len:uint = regions.length;
			var result:String = "";
			for(var i:uint=0;i<len;i++){
				var region:Object = regions[i];
				var lines:Array = region.lines;
				for(var j:uint=0;j<lines.length;j++){
					var words:Array = lines[j].words;
					for(var k:uint=0;k<words.length;k++){
						result+=words[k].text+" ";
					}
					result+="\n";
				}
			}
			/*return;
			var ret:XML = new XML(evt.target.data);
			if (ret.namespace("") != undefined) 
			{ 
				default xml namespace = ret.namespace(""); 
			}
			for(var i:uint=0;i<len;i++){
				var faceAttributes:XMLList = ret[i].DetectedFace.faceAttributes;
				var faceId:String = ret[i].DetectedFace.faceId;
				var faceRectangle:XMLList = ret[i].DetectedFace.faceRectangle;
				var faceLandmarks:XMLList = ret[i].DetectedFace.faceLandmarks;
				
				var obj:Object = {};
				obj.x = faceRectangle.left;
				obj.y = faceRectangle.top;
				obj.width = faceRectangle.width;
				obj.height = faceRectangle.height;
				obj.age = faceAttributes.age;
				obj.gender = faceAttributes.gender;
				obj.smile = faceAttributes.smile;
				result.push(obj);
				//				var output:String = "用户（"+(i+1)+"）愤怒:"+Math.round(ret.FaceRecognitionResult[i].scores.anger*100)+"%   ";
				//				output += "鄙视:"+Math.round(ret.FaceRecognitionResult[i].scores.contempt*100)+"%    ";
				//				output += "厌恶:"+Math.round(ret.FaceRecognitionResult[i].scores.disgust*100)+"%    ";
				//				output += "恐惧:"+Math.round(ret.FaceRecognitionResult[i].scores.fear*100)+"%\r";
				//				output += "开心:"+Math.round(ret.FaceRecognitionResult[i].scores.happiness*100)+"%    ";
				//				output += "中立:"+Math.round(ret.FaceRecognitionResult[i].scores.neutral*100)+"%    ";
				//				output += "悲伤:"+Math.round(ret.FaceRecognitionResult[i].scores.sadness*100)+"%    ";
				//				output += "吃惊:"+Math.round(ret.FaceRecognitionResult[i].scores.surprise*100)+"%\r";
			}*/
			MBlock.app.extensionManager.extensionByName("Microsoft Cognitive Services").stateVars["textResultReceived"] = result;
			MBlock.app.runtime.textResultReceived.notify(true);
		}
		private function onIOError(evt:IOErrorEvent):void{
			MBlock.app.track("/OxfordAi/OCR/error");
			trace("error：",evt);
		}
		private function onHttpStatus(evt:HTTPStatusEvent):void{
			trace("Status:",evt);
		}
	}
}