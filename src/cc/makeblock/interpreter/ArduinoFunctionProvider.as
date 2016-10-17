package cc.makeblock.interpreter
{
	import flash.utils.getTimer;
	
	import blockly.runtime.FunctionProvider;
	import blockly.runtime.Thread;
	import blockly.util.FunctionProviderHelper;
	
	import cc.makeblock.services.msoxford.EmotionDetection;
	import cc.makeblock.services.msoxford.FaceDetection;
	import cc.makeblock.services.msoxford.FaceDetectionOffline;
	import cc.makeblock.services.msoxford.GraphicsToText;
	import cc.makeblock.services.msoxford.SpeakerDetection;
	import cc.makeblock.services.msoxford.SpeechToText;
	
	import extensions.ScratchExtension;
	import extensions.SerialDevice;
	
	internal class ArduinoFunctionProvider extends FunctionProvider
	{
		public function ArduinoFunctionProvider()
		{
			FunctionProviderHelper.InitMath(this);
			FunctionSounds.Init(this);
			new FunctionList().addPrimsTo(this);
			new FunctionLooks().addPrimsTo(this);
			new FunctionMotionAndPen().addPrimsTo(this);
			new Primitives().addPrimsTo(this);
			new FunctionSensing().addPrimsTo(this);
			new FunctionVideoMotion().addPrimsTo(this);
			PrimInit.Init(this);
		}
		
		private var mbotTimer:int;
		private var netExt:NetExtension = new NetExtension();
		private var speechAPI:SpeechToText = new SpeechToText();
		private var speakerAPI:SpeakerDetection = new SpeakerDetection();
		private var emotionAPI:EmotionDetection = new EmotionDetection();
		private var faceAPI:FaceDetection = new FaceDetection();
		private var realtimeFaceAPI:FaceDetectionOffline = new FaceDetectionOffline;
		private var ocrAPI:GraphicsToText = new GraphicsToText();
		
		override protected function onCallUnregisteredFunction(thread:Thread, name:String, argList:Array, retCount:int):void
		{
			var index:int = name.indexOf(".");
			if(index < 0){
				if(name.indexOf("when") < 0){
					super.onCallUnregisteredFunction(thread, name, argList, retCount);
				}
				return;
			}
			var extName:String = name.slice(0, index);
			var opName:String = name.slice(index+1);
			if(extName == "Communication"){
				netExt.exec(thread, opName, argList);
				return;
			}
			var ext:ScratchExtension = MBlock.app.extensionManager.extensionByName(extName);
			if(extName.toLocaleLowerCase().indexOf("microsoft cognitive services")>-1){
				if(opName=="startVoiceRecognition"){
					speechAPI.start();
				}else if(opName=="stopVoiceRecognition"){
					speechAPI.stop();
					speakerAPI.stop();
				}else if(opName=="capturePhoto"){
					if(argList[0]=="emotion"){
						emotionAPI.capture();
					}else if(argList[0]=="face"){
						faceAPI.capture();
					}else if(argList[0]=="text"){
						ocrAPI.capture();
					}
				}else if(opName=="captureFace"){
					if(argList[0]=="start"){
						realtimeFaceAPI.start();
					}else if(argList[0]=="stop"){
						realtimeFaceAPI.stop();
					}
				}else if(opName=="voiceCommandReceived"){
					thread.push(ext.getStateVar(opName));
				}else if(opName.indexOf("emotionResultReceived")>-1){
					thread.push(ext.getStateVar(opName)[argList[0]-1][argList[1]]);
				}else if(opName.indexOf("faceResultReceived")>-1){
					thread.push(ext.getStateVar(opName)[argList[0]-1][argList[1]]);
				}else if(opName.indexOf("realFaceResultReceived")>-1){
					thread.push(ext.getStateVar(opName)[argList[0]-1][argList[1]]);
				}else if(opName.indexOf("textResultReceived")>-1){
					thread.push(ext.getStateVar(opName));
				}
				return;
			}
			if(null == ext){
				thread.interrupt();
				return;
			}
			if(!ext.useSerial){
				thread.push(ext.getStateVar(opName));
			}else if(SerialDevice.sharedDevice().connected){
				thread.suspend();
				RemoteCallMgr.Instance.call(thread, opName, argList, ext, retCount);
			}else if(retCount > 0){
				thread.push(0);
			}
		}
	}
}