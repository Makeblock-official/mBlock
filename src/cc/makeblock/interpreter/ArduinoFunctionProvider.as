package cc.makeblock.interpreter
{
	import flash.utils.getTimer;
	
	import blockly.runtime.FunctionProvider;
	import blockly.runtime.Thread;
	import blockly.util.FunctionProviderHelper;
	
	import extensions.ScratchExtension;
	import extensions.SerialDevice;
	
	internal class ArduinoFunctionProvider extends FunctionProvider
	{
		private const remoteCallMgr:RemoteCallMgr = new RemoteCallMgr();
		
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
		
		override protected function onCallUnregisteredFunction(thread:Thread, name:String, argList:Array):void
		{
			var index:int = name.indexOf(".");
			if(index < 0){
				if(name.indexOf("when") < 0){
					super.onCallUnregisteredFunction(thread, name, argList);
				}
				return;
			}
			var extName:String = name.slice(0, index);
			var opName:String = name.slice(index+1);
			switch(opName){
				case "getTimer":
					thread.push(0.001 * (getTimer()-mbotTimer));
					return;
				case "resetTimer":
					mbotTimer = getTimer();
					return;
			}
			var ext:ScratchExtension = MBlock.app.extensionManager.extensionByName(extName);
			if (ext == null || (ext.useSerial && !SerialDevice.sharedDevice().connected) || !ext.js.connected){
				thread.interrupt();
				return;
			}
			thread.suspend();
			remoteCallMgr.call(thread, opName, argList, ext);
		}
	}
}