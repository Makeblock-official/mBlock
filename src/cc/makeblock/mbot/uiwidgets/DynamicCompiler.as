package cc.makeblock.mbot.uiwidgets
{
	import extensions.DeviceManager;
	
	import org.aswing.AsWingConstants;
	import org.aswing.BorderLayout;
	import org.aswing.GridLayout;
	import org.aswing.JButton;
	import org.aswing.JCheckBox;
	import org.aswing.JPanel;
	import org.aswing.SoftBoxLayout;
	import org.aswing.event.AWEvent;

	public class DynamicCompiler extends MyFrame
	{
		static private const sensorDict:Object = {
			"Servo":"use_servo",
			"DC Motor":"use_dcMotor",
			"Steper Motor":"use_steperMotor",
			"Encode Motor":"use_encodeMotor",
			"Temperature":"",
			"RGB Led":"",
			"Ultrasonic":"",
			"7 Segment Display":"",
			"Led Matrix":"",
			"Buzzer":"",
			"IR":"",
			"Gyro":"",
			"Joystick":"",
			"Compass":"",
			"Humiture":"",
			"Flame Sensor":"",
			"Gas Sensor":""
		};
		
		public var selectAllBtn:JButton;
		public var selectNoneBtn:JButton;
		public var selectInvertBtn:JButton;
		public var compileBtn:JButton;
		
		private var checkBoxList:Array = [];
		
		public function DynamicCompiler()
		{
			super(null, "Dynamic Compiler", true);
			var content:JPanel = new JPanel(new GridLayout(4,4));
			for(var sensorName:String in sensorDict){
				var checkBox:JCheckBox = new JCheckBox(sensorName);
				checkBox.name = sensorName;
				checkBox.setHorizontalAlignment(AsWingConstants.LEFT);
				content.append(checkBox);
				checkBoxList.push(checkBox);
			}
			
			getContentPane().append(content, BorderLayout.CENTER);
			setSizeWH(550, 400);
			
			selectAllBtn = new JButton("Select All");
			selectNoneBtn = new JButton("Select None");
			selectInvertBtn = new JButton("Select Invert");
			compileBtn = new JButton("Compile");
			var bottom:JPanel = new JPanel(new SoftBoxLayout(0, 0, SoftBoxLayout.CENTER));
			bottom.append(selectAllBtn);
			bottom.append(selectNoneBtn);
			bottom.append(selectInvertBtn);
			bottom.append(compileBtn);
			getContentPane().append(bottom, BorderLayout.SOUTH);
			
			addEvents();
		}
		
		private function addEvents():void
		{
			selectAllBtn.addActionListener(__onSelectAll);
			selectNoneBtn.addActionListener(__onSelectNone);
			selectInvertBtn.addActionListener(__onSelectInvert);
			compileBtn.addActionListener(__onCompile);
		}
		
		private function getFileName():String
		{
			switch(DeviceManager.sharedManager().currentName){
				case "mBot":
					return "firmware/mbot_firmware/mbot_firmware.ino";
				case "Me Orion":
					return "firmware/orion_firmware/orion_firmware.ino";
				case "Me Baseboard":
					return "firmware/baseboard_firmware/baseboard_firmware.ino";
				case "UNO Shield":
					return "firmware/shield_firmware/shield_firmware.ino";
			}
			return null;
		}
		
		private function __onCompile(evt:AWEvent):void
		{
			/*
			var fileName:String = getFileName();
			if(null == fileName){
				return;
			}
			if(!MBlock.app.stageIsArduino){
				MBlock.app.changeToArduinoMode();
				show();
			}
			var source:String = FileUtil.ReadString(File.applicationDirectory.resolvePath(fileName));
			for(var i:int=0; i<checkBoxList.length; ++i){
				var checkBox:JCheckBox = checkBoxList[i];
				if(checkBox.isSelected()){
					continue;
				}
				source = disable(source, sensorDict[checkBox.name]);
			}
			trace(source);
			MBlock.app.scriptsPart.appendMessage(ArduinoManager.sharedManager().buildAll(source));
			*/
		}
		
		private function __onSelectAll(evt:AWEvent):void
		{
			for each(var checkBox:JCheckBox in checkBoxList){
				checkBox.setSelected(true);
			}
		}
		
		private function __onSelectNone(evt:AWEvent):void
		{
			for each(var checkBox:JCheckBox in checkBoxList){
				checkBox.setSelected(false);
			}
		}
		
		private function __onSelectInvert(evt:AWEvent):void
		{
			for each(var checkBox:JCheckBox in checkBoxList){
				checkBox.setSelected(!checkBox.isSelected());
			}
		}
		
		private function disable(text:String, module:String):String
		{
			if(!Boolean(module)){
				return text;
			}
			return text.replace(new RegExp("#define\\s+" + module + ".+"), "");
		}
	}
}