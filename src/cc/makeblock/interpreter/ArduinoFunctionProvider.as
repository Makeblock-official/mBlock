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
			switch(opName){
				case "getTimer":
					thread.push(0.001 * (getTimer()-mbotTimer));
					return;
				case "resetTimer":
					mbotTimer = getTimer();
					return;
			}
			var ext:ScratchExtension = MBlock.app.extensionManager.extensionByName(extName);
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