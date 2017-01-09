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
	
	import util.DESParser;
	import util.JSON;
	import util.SharedObjectManager;
	
	public class FaceDetection 
	{
		private var _vid:Video;
		private var _time:Number = 0;
		private var _source:String = "system";
		public function FaceDetection()
		{
			
		}
		public function capture():void{
			if(_vid==null){
				_vid = MBlock.app.stageObj().currentVideo;
			}
			if(_vid==null){
				return;
			}
			if(new Date().time-_time>4000){
				_time = new Date().time;
			}else{
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
			req.url = "https://api.projectoxford.ai/face/v1.0/detect?format=json&returnFaceId=true&returnFaceLandmarks=true&returnFaceAttributes=age,gender,headPose,smile";
			req.method = URLRequestMethod.POST;
			req.data = bytes;
			var secret:String = SharedObjectManager.sharedManager().getObject("keyFace-user","");//"";
			if(secret.length<10){
				secret = SharedObjectManager.sharedManager().getObject("keyFace-system","");
			}else{
				_source = "user";
			}
			if(secret.length<10){
				trace("no secret");
				return;
			}
			MBlock.app.track("/OxfordAi/face/launch/"+_source);
			req.requestHeaders.push(new URLRequestHeader("Content-Type","application/octet-stream"));
			req.requestHeaders.push(new URLRequestHeader("Ocp-Apim-Subscription-Key",secret));
			urlloader.addEventListener(Event.COMPLETE,onRequestComplete);
			urlloader.addEventListener(IOErrorEvent.IO_ERROR,onIOError);
			urlloader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS,onHttpStatus);
			urlloader.load(req);
		}
		private function onRequestComplete(evt:Event):void{
			
			MBlock.app.track("/OxfordAi/face/success/"+_source);
			var ret:*;
			if(evt.target.data.toString().indexOf("xmlns")>-1){
				try{
					ret = new XML(evt.target.data);
					if (ret.namespace("") != undefined) 
					{ 
						default xml namespace = ret.namespace(""); 
					}
					var len:uint = ret.length();
					var result:Array = [];
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
					}
					if(len>0){
						MBlock.app.extensionManager.extensionByName("Microsoft Cognitive Services").stateVars["faceResultReceived"] = result;
						MBlock.app.runtime.faceResultReceived.notify(true);
					}
				}catch(e:*){
					
					
				}
				return;
			}
			try{
				ret = util.JSON.parse(evt.target.data);
				var len:uint = ret.length;
				var result:Array = [];
				
				for(var i:uint=0;i<len;i++){
					var faceAttributes_obj:Object = ret[i].faceAttributes;
					var faceId:String = ret[i].faceId;
					var faceRectangle_obj:Object = ret[i].faceRectangle;
					var faceLandmarks_obj:Object = ret[i].faceLandmarks;
					
					var obj:Object = {};
					obj.x = faceRectangle_obj.left;
					obj.y = faceRectangle_obj.top;
					obj.width = faceRectangle_obj.width;
					obj.height = faceRectangle_obj.height;
					obj.age = faceAttributes_obj.age;
					obj.gender = faceAttributes_obj.gender;
					obj.smile = faceAttributes_obj.smile;
					result.push(obj);
				}
				if(len>0){
					MBlock.app.extensionManager.extensionByName("Microsoft Cognitive Services").stateVars["faceResultReceived"] = result;
					MBlock.app.runtime.faceResultReceived.notify(true);
				}
			}catch(e:*){
				
			}
		}
		private function onIOError(evt:IOErrorEvent):void{
			trace("error：",evt);
			MBlock.app.track("/OxfordAi/face/error/"+_source);
		}
		private function onHttpStatus(evt:HTTPStatusEvent):void{
			trace("Status:",evt);
		}
	}
}

