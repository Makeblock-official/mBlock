package cc.makeblock.services.msoxford
{
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.StatusEvent;
	import flash.media.Microphone;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import org.bytearray.micrecorder.MicRecorder;
	import org.bytearray.micrecorder.encoder.WaveEncoder;
	
	import util.SharedObjectManager;
	
	public class SpeakerDetection
	{
		private var _waveEncoder:WaveEncoder = new WaveEncoder();
		private var _recorder:MicRecorder = new MicRecorder(_waveEncoder);
		private var _secret:String = "";
		private var _recordStatus:uint = 0;
		private var _silentTime:uint = 0;
		//判断声音是否符合已保存的身份
		public function SpeakerDetection()
		{
			//			var ret:XML = new XML('<speechbox-root><version>3.0</version><header><status>success</status><scenario>ulm</scenario><name>喂喂喂喂喂喂喂</name><lexical>喂喂喂 喂喂喂 喂</lexical><properties><property name="requestid">b8934c0e-b622-436a-8376-a114d51101b6</property><property name="HIGHCONF">1</property></properties></header><results><result><scenario>ulm</scenario><name>喂喂喂喂喂喂喂</name><lexical>喂喂喂 喂喂喂 喂</lexical><confidence>0.8946657</confidence><properties><property name="HIGHCONF">1</property></properties></result></results></speechbox-root>');
			//			if(ret.header.status=="success"){
			//				trace(ret.header.name);
			//			}
		} 
		public function start():void{
			_secret = SharedObjectManager.sharedManager().getObject("keySpeaker","94712db8e9b34e25933af9e5b37b4807");//"94712db8e9b34e25933af9e5b37b4807"
			_recorder.microphone = Microphone.getMicrophone();
			trace("voice start:",_recorder.microphone);
			if(_recorder.microphone==null){
				return;
			}
			_recorder.silenceLevel = 5;
			_recorder.rate = 11;
			_recorder.gain = 60;
			_recorder.timeOut = 100;
			//			_recorder.microphone.setLoopBack(true);
			_recorder.microphone.setUseEchoSuppression(true);
			_recorder.onActivity = onActivity;
			_recorder.microphone.addEventListener(StatusEvent.STATUS, onMicStatus);
			//			_recorder.addEventListener(RecordingEvent.RECORDING, function(e):void{});
			_recorder.addEventListener(Event.COMPLETE,onRecordComplete);
			_recorder.record();
		}
		public function stop():void{
			if(_recorder.microphone!=null){
				_recorder.microphone.setLoopBack(false);
				_recorder.microphone.removeEventListener(StatusEvent.STATUS, onMicStatus);
				_recorder.removeEventListener(Event.COMPLETE,onRecordComplete);
				_recorder.microphone = null;
			}
		}
		private function startRecord():void{
			trace("recording...");
			setTimeout(function():void{
				_recordStatus = 2;
				stopRecord();
			},2000);
		}
		private function stopRecord():void{
			trace("stop recording...");
			_recorder.stop();
		}
		private function onMicStatus(evt:StatusEvent):void{
			trace(evt);
		}
		private function onActivity(v:Number):void{
			if(Math.abs(v*100)>30){
				trace(v);
				if(_recordStatus==0){
					_recordStatus = 1;
					startRecord();
				}
				_silentTime = getTimer();
			}else{
				if(_recordStatus==1&&(getTimer()-_silentTime>2000)){
					
				}
			}
		}
		private function onRecordComplete(evt:Event):void{
			
			//			var file:File = File.desktopDirectory.resolvePath("record_"+getTimer()+".wav");
			//			var stream:FileStream = new FileStream();
			//			stream.open(file,FileMode.WRITE);
			//			stream.writeBytes(_recorder.output,0,_recorder.output.length);
			//			stream.close();
			//			return;
			var urlloader:URLLoader = new URLLoader;
			var req:URLRequest = new URLRequest();
			req.url = "https://oxford-speech.cloudapp.net/token/issueToken";
			var vars:URLVariables = new URLVariables;
			vars["grant_type"] = "client_credentials";
			vars["client_id"] = "client_credentials";
			vars["client_secret"] = _secret;
			vars["scope"] = encodeURI("https://speech.platform.bing.com");
			req.method = URLRequestMethod.POST;
			req.data = vars;
			req.requestHeaders.push(new URLRequestHeader("Content-Type","application/x-www-form-urlencoded"));
			urlloader.addEventListener(Event.COMPLETE,onRequestAuthComplete);
			urlloader.addEventListener(IOErrorEvent.IO_ERROR,onIOError);
			urlloader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS,onHttpStatus);
			urlloader.load(req);
		}
		private function onRequestAuthComplete(evt:Event):void{
			var obj:Object = JSON.parse(evt.target.data);
			var appid:String = "f84e364c-ec34-4773-a783-73707bd9a585";
			var scenarios:String = "ulm";
			var locale:String = "zh-CN";
			var device:String = "Windows OS";
			var version:String = "3.0";
			var format:String = "xml";
			var requestid:String = "1d4b6030-9099-11e0-91e4-0800200c9a66";
			var instanceid:String = "1d4b6030-9099-11e0-91e4-0800200c9a66";
			var urlloader:URLLoader = new URLLoader;
			
			urlloader.dataFormat = URLLoaderDataFormat.BINARY;
			var req:URLRequest = new URLRequest();
			https://api.projectoxford.ai/spid/v1.0/identificationProfiles/{identificationProfileId}/enroll
			req.url = "https://speech.platform.bing.com/recognize/query?appid="+appid;
			req.url += "&device.os="+device;
			req.url += "&scenarios="+scenarios;
			req.url += "&locale="+locale;
			req.url += "&version="+version;
			req.url += "&format="+format;
			req.url += "&requestid="+requestid;
			req.url += "&instanceid="+instanceid;
			req.method = URLRequestMethod.POST;
			req.data = _recorder.output;
			var authCode:String = obj.access_token;
			req.requestHeaders.push(new URLRequestHeader("Content-Type","audio/wav; samplerate=8000"));
			req.requestHeaders.push(new URLRequestHeader("Authorization","Bearer "+authCode));
			urlloader.addEventListener(Event.COMPLETE,onSpeechRequestComplete);
			urlloader.addEventListener(IOErrorEvent.IO_ERROR,onIOError);
			urlloader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS,onHttpStatus);
			urlloader.load(req);
		}
		private function onHttpStatus(evt:HTTPStatusEvent):void{
			trace("Status:",evt);
		}
		private function onIOError(evt:IOErrorEvent):void{
			trace("error：",evt);
		}
		private function onSpeechRequestComplete(evt:Event):void{
			var ret:XML = new XML(evt.target.data);
			if (ret.namespace("") != undefined) 
			{ 
				default xml namespace = ret.namespace(""); 
			}
			/*
			<speechbox-root>
			<version>3.0</version>
			<header>
			<status>error</status>
			<properties>
			<property name="requestid">5fae3764-4a2d-4011-a9b8-2573a4db26af</property>
			<property name="NOSPEECH">1</property>
			</properties>
			</header>
			</speechbox-root>
			*/
			/*
			<speechbox-root>
			<version>3.0</version>
			<header>
			<status>success</status>
			<scenario>ulm</scenario>
			<name>喂喂喂喂喂喂喂</name>
			<lexical>喂喂喂 喂喂喂 喂</lexical>
			<properties>
			<property name="requestid">b8934c0e-b622-436a-8376-a114d51101b6</property>
			<property name="HIGHCONF">1</property>
			</properties>
			</header>
			<results>
			<result>
			<scenario>ulm</scenario>
			<name>喂喂喂喂喂喂喂</name>
			<lexical>喂喂喂 喂喂喂 喂</lexical>
			<confidence>0.8946657</confidence>
			<properties>
			<property name="HIGHCONF">1</property>
			</properties>
			</result>
			</results>
			</speechbox-root>
			*/
			if(ret.header.status=="success"){
				trace(ret.header.name);
				if(ret.header.name.profanity!=undefined&&ret.header.name.profanity.length>0){
					ret.header.name = "敏感词";
				}
				MBlock.app.extensionManager.extensionByName("Microsoft Cognitive Services").stateVars["voiceCommandReceived"] = ret.header.name;
				MBlock.app.runtime.voiceReceived.notify(true);
			}
			_recordStatus = 0;
		}
	}
}

