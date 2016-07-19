/*
 * Scratch Project Editor and Player
 * Copyright (C) 2014 Massachusetts Institute of Technology
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

// ScriptsPart.as
// John Maloney, November 2011
//
// This part holds the palette and scripts pane for the current sprite (or stage).

package ui.parts {
	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.html.HTMLLoader;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	import blocks.Block;
	
	import cc.makeblock.util.HexUtil;
	
	import extensions.ArduinoManager;
	import extensions.ConnectionManager;
	import extensions.SerialDevice;
	import extensions.SerialManager;
	
	import scratch.ScratchObj;
	import scratch.ScratchSprite;
	import scratch.ScratchStage;
	
	import translation.Translator;
	
	import ui.BlockPalette;
	import ui.PaletteSelector;
	
	import uiwidgets.Button;
	import uiwidgets.DialogBox;
	import uiwidgets.IndicatorLight;
	import uiwidgets.ScriptsPane;
	import uiwidgets.ScrollFrame;
	import uiwidgets.ZoomWidget;
	
	import util.JSON;
	import cc.makeblock.mbot.util.AppTitleMgr;

public class ScriptsPart extends UIPart {
	private var htmlLoader:HTMLLoader;
	
	private var shape:Shape;
	public var selector:PaletteSelector;
	private var spriteWatermark:Bitmap;
	private var paletteFrame:ScrollFrame;
	private var scriptsFrame:ScrollFrame;
	private var arduinoFrame:ScrollFrame;
	private var zoomWidget:ZoomWidget;

	private const readoutLabelFormat:TextFormat = new TextFormat(CSS.font, 12, CSS.textColor, true);
	private const readoutFormat:TextFormat = new TextFormat(CSS.font, 12, CSS.textColor);

	private var xyDisplay:Sprite;
	private var xLabel:TextField;
	private var yLabel:TextField;
	private var xReadout:TextField;
	private var yReadout:TextField;
	private var lastX:int = -10000000; // impossible value to force initial update
	private var lastY:int = -10000000; // impossible value to force initial update
	private var backBt:Button = new Button(Translator.map("Back"));
	private var uploadBt:Button = new Button(Translator.map("Upload to Arduino"));
	private var openBt:Button = new Button(Translator.map("Open with Arduino IDE"));
//	private var sendBt:Button = new Button(Translator.map("Send"));
//	private var sendTextPane:TextPane;
//	
//	private var isByteDisplayMode:Boolean = true;
//	private var displayModeBtn:Button = new Button(Translator.map("binary mode"));
	
//	private var isByteInputMode:Boolean = false;
//	private var inputModeBtn:Button = new Button(Translator.map("char mode"));
	
	private var arduinoCodeText:String = "";
	
	public function ScriptsPart(app:MBlock) {
		this.app = app;

		addChild(shape = new Shape());
		addChild(spriteWatermark = new Bitmap());
		addXYDisplay();
		addChild(selector = new PaletteSelector(app));

		var palette:BlockPalette = new BlockPalette();
		palette.color = CSS.tabColor;
		paletteFrame = new ScrollFrame();
		paletteFrame.allowHorizontalScrollbar = false;
		paletteFrame.setContents(palette);
		addChild(paletteFrame);

		var scriptsPane:ScriptsPane = new ScriptsPane(app);
		scriptsFrame = new ScrollFrame(true);
		scriptsFrame.setContents(scriptsPane);
		addChild(scriptsFrame);
		
		app.palette = palette;
		app.scriptsPane = scriptsPane;

		addChild(zoomWidget = new ZoomWidget(scriptsPane));
		
		arduinoFrame = new ScrollFrame(false);
		arduinoFrame.visible = false;
		
//		arduinoTextPane.type = TextFieldType.INPUT;
		var ft:TextFormat = new TextFormat("Arial",14,0x00325a);
		ft.blockIndent = 5;
		/*
		sendTextPane = new TextPane();
		sendTextPane.textField.defaultTextFormat = ft;
		sendTextPane.textField.background = true;
		sendTextPane.textField.backgroundColor = 0xf8f8f8;
		sendTextPane.textField.type = TextFieldType.INPUT;
		sendTextPane.textField.multiline = false;
		sendTextPane.scrollbar.visible = false;
		*/
		backBt.x = 10;
		backBt.y = 10;
		backBt.addEventListener(MouseEvent.CLICK,onHideArduino);
		arduinoFrame.addChild(backBt);
		uploadBt.x = 70;
		uploadBt.y = 10;
		uploadBt.addEventListener(MouseEvent.CLICK,onCompileArduino);
		arduinoFrame.addChild(uploadBt);
		
		openBt.y = 10;
		openBt.addEventListener(MouseEvent.CLICK,onOpenArduinoIDE);
		
//		sendBt.addEventListener(MouseEvent.CLICK,onSendSerial);
//		displayModeBtn.addEventListener(MouseEvent.CLICK,onDisplayModeChange);
//		inputModeBtn.addEventListener(MouseEvent.CLICK,onInputModeChange);
		
		arduinoFrame.addChild(openBt);
//		arduinoFrame.addChild(sendTextPane);
//		arduinoFrame.addChild(sendBt);
//		arduinoFrame.addChild(displayModeBtn);
//		arduinoFrame.addChild(inputModeBtn);
		addChild(arduinoFrame);
		
		paletteFrame.addEventListener(MouseEvent.ROLL_OVER, __onMouseOver);
		paletteFrame.addEventListener(MouseEvent.ROLL_OUT, __onMouseOut);
		paletteIndex = getChildIndex(paletteFrame);
		
		htmlLoader = new HTMLLoader();
		htmlLoader.placeLoadStringContentInApplicationSandbox = true;
		htmlLoader.runtimeApplicationDomain = ApplicationDomain.currentDomain;
		htmlLoader.window.trace = trace;
		htmlLoader.window.onSendSerial = onSendSerial;
		htmlLoader.window.onRecvModeChanged = onRecvModeChanged;
		htmlLoader.load(new URLRequest("assets/html/index.html"));
		addChild(htmlLoader);
	}
	
	private var paletteIndex:int;
	private var maskWidth:int;
	private var _isRecvBinaryMode:Boolean = true;
	
	private function onRecvModeChanged():void
	{
		_isRecvBinaryMode = htmlLoader.window.isRecvBinaryMode();
	}
	
	private function __onMouseOver(event:MouseEvent):void
	{
		setChildIndex(paletteFrame, numChildren-1);
		paletteFrame.addEventListener(Event.ENTER_FRAME, __onEnterFrame);
		maskWidth = 0;
	}
	
	private function __onEnterFrame(event:Event):void
	{
		if(maskWidth < 1200){
			maskWidth += 30;
			paletteFrame.showRightPart(maskWidth);
		}
		if(paletteFrame.mouseX > BlockPalette.WIDTH){
			__onMouseOut(null);
		}
	}
	
	private function __onMouseOut(event:MouseEvent):void
	{
		paletteFrame.removeEventListener(Event.ENTER_FRAME, __onEnterFrame);
		paletteFrame.hideRightPart();
		setChildIndex(paletteFrame, paletteIndex);
	}
	/*
	private function onInputModeChange(evt:MouseEvent):void
	{
		var str:String = sendTextPane.textField.text;
//		isByteInputMode = !isByteInputMode;
		if(isByteInputMode){
			sendTextPane.textField.restrict = "0-9 a-fA-F";
//			inputModeBtn.setLabel(Translator.map("binary mode"));
		}else{
			sendTextPane.textField.restrict = null;
//			inputModeBtn.setLabel(Translator.map("char mode"));
		}
		if(str.length <= 0){
			return;
		}
		var bytes:ByteArray;
		if(isByteInputMode){
			bytes = new ByteArray();
			bytes.writeUTFBytes(str);
			sendTextPane.textField.text = HexUtil.bytesToString(bytes);
		}else{
			bytes = HexUtil.stringToBytes(str);
			sendTextPane.textField.text = bytes.readUTFBytes(bytes.length);
		}
		bytes.clear();
	}
	
	private function onDisplayModeChange(evt:MouseEvent):void
	{
		isByteDisplayMode = !isByteDisplayMode;
		if(isByteDisplayMode){
			displayModeBtn.setLabel(Translator.map("binary mode"));
		}else{
			displayModeBtn.setLabel(Translator.map("char mode"));
		}
	}
	*/
	public function appendMessage(msg:String):void{
		appendRawMessage(msg+"\n");
	}
	public function appendRawMessage(msg:String):void{
		htmlLoader.window.appendInfo(msg);
	}
	public function clearInfo():void
	{
		htmlLoader.window.clearInfo();
	}
	
	public function onSerialSend(bytes:ByteArray):void
	{
		if(_isRecvBinaryMode){
			appendMsgWithTimestamp(HexUtil.bytesToString(bytes), true);
		}else{
			bytes.position = 0;
			var str:String = bytes.readUTFBytes(bytes.length);
			appendMsgWithTimestamp(str, true);
		}
	}
	
	public function appendMsgWithTimestamp(msg:String, isOut:Boolean):void
	{
		var sendType:String = isOut ? " > " : " < ";
		appendMessage(formatTime() + sendType + msg);
	}
	
	static private function formatTime():String
	{
		var date:Date = new Date();
		return formatStr(date.hours.toString()  , 2) + ":"
			 + formatStr(date.minutes.toString(), 2) + ":"
			 + formatStr(date.seconds.toString(), 2) + "."
			 + formatStr(date.milliseconds.toString(), 3);
	}
	
	static private function formatStr(str:String, len:int):String
	{
		while(str.length < len){
			str = "0" + str;
		}
		return str;
	}
	
	public function onSerialDataReceived(bytes:ByteArray):void{
		if(htmlLoader.window.isRecvBinaryMode()){
			appendMsgWithTimestamp(HexUtil.bytesToString(bytes), false);
		}else{
			bytes.position = 0;
			var str:String = bytes.readUTFBytes(bytes.length);
			appendMsgWithTimestamp(str, false);
		}
		/*
		return;
		var date:Date = new Date;
		var s:String = SerialManager.sharedManager().asciiString;
		if(s.charCodeAt(0)==20){
			return;
		}
		appendMessage(""+(date.month+1)+"-"+date.date+" "+date.hours+":"+date.minutes+":"+(date.seconds+date.milliseconds/1000)+" < "+SerialManager.sharedManager().asciiString.split("\r\n").join("")+"\n");
		*/
	}
	private function onSendSerial(str:String):void{
		if(!SerialDevice.sharedDevice().connected){
			return;
		}
		if(str.length <= 0){
			return;
		}
		var bytes:ByteArray;
		if(isByteInputMode){
			bytes = HexUtil.stringToBytes(str);
		}else{
			bytes = new ByteArray();
			bytes.writeUTFBytes(str + "\n");
		}
		onSerialSend(bytes);
		ConnectionManager.sharedManager().sendBytes(bytes);
//		var date:Date = new Date;
//		messageTextPane.append(""+(date.month+1)+"-"+date.date+" "+date.hours+":"+date.minutes+":"+(date.seconds+date.milliseconds/1000)+" > "+sendTextPane.textField.text+"\n");
		
//		messageTextPane.textField.scrollV = messageTextPane.textField.maxScrollV-1;
	}
	public function get isArduinoMode():Boolean{
		return arduinoFrame.visible;
	}
	private function onCompileArduino(evt:MouseEvent):void{
		if(SerialManager.sharedManager().isConnected){
			if(ArduinoManager.sharedManager().isUploading==false){
				htmlLoader.window.clearInfo();
				if(showArduinoCode()){
					htmlLoader.window.appendInfo(ArduinoManager.sharedManager().buildAll(arduinoCodeText));
					AppTitleMgr.Instance.setConnectInfo("Uploading");
				}
			}
		}else{
			var dialog:DialogBox = new DialogBox();
			dialog.addTitle("Message");
			dialog.addText("Please connect the serial port.");
			function onCancel():void{
				dialog.cancel();
			}
			dialog.addButton("OK",onCancel);
			dialog.showOnStage(app.stage);
		}
	}
	private function onHideArduino(evt:MouseEvent):void{
		app.toggleArduinoMode();
	}
	private function onOpenArduinoIDE(evt:MouseEvent):void{
		if(showArduinoCode()){
			ArduinoManager.sharedManager().openArduinoIDE(arduinoCodeText);
		}
	}
	
	static private const classNameList:Array = [
		"SoftwareSerial",
		"MeBoard",
		"MeDCMotor",
		"MeServo",
		"MeIR",
		"Me7SegmentDisplay",
		"MeRGBLed",
		"MePort",
		"MeGyro",
		"MeJoystick",
		"MeLight",
		"MeSound",
		"MeStepper",
		"MeEncoderMotor",
		"MeInfraredReceiver",
		"MeTemperature",
		"MeUltrasonicSensor",
		"MeSerial",
		"Servo",
		"mBot",
		"Arduino",
	];
	
	public function showArduinoCode(arg:String=""):Boolean{
		var retcode:String = util.JSON.stringify(app.stagePane);
		var formatCode:String = ArduinoManager.sharedManager().jsonToCpp(retcode);
		uploadBt.visible = !ArduinoManager.sharedManager().hasUnknownCode;
		if(formatCode==null){
			return false;
		}
		if(!app.stageIsArduino){
			app.toggleArduinoMode();
		}
		for(var i:uint=0;i<5;i++){
			formatCode = formatCode.split("\r\n\r\n").join("\r\n").split("\r\n\t\r\n").join("\r\n");
		}
		/*
		var codes:Array = formatCode.split("\n");
		var fontGreen:TextFormat = new TextFormat("Arial",14,0x006633);
		var fontYellow:TextFormat = new TextFormat("Arial",14,0x999900);
		var fontOrange:TextFormat = new TextFormat("Arial",14,0x996600);
		var fontRed:TextFormat = new TextFormat("Arial",14,0x990000);
		var fontBlue:TextFormat = new TextFormat("Arial",14,0x000099);
		*/
		arduinoCodeText = formatCode;
		/*
		formatKeyword(/(setup|loop)(?=\(\))/g, fontOrange);
		formatKeyword(/for|if|else|while/g, fontOrange);
		formatKeyword(/(?=^|\s)(void|String|int|char|double|boolean|true|false|#include)(?= )/gm, fontRed);
		formatKeyword(/(PORT|SLOT)_\d/g, fontOrange);
		
		formatKeyword(arduinoTextPane.textField," setup()",fontRed,1,2);
		formatKeyword(arduinoTextPane.textField," loop()",fontRed,1,2);
		formatKeyword(arduinoTextPane.textField,"Serial.",fontRed,0,1);
		formatKeyword(arduinoTextPane.textField,".begin(",fontOrange,1,1);
		formatKeyword(arduinoTextPane.textField,".available(",fontOrange,1,1);
		formatKeyword(arduinoTextPane.textField,".println(",fontOrange,1,1);
		formatKeyword(arduinoTextPane.textField,".print(",fontOrange,1,1);
		formatKeyword(arduinoTextPane.textField,".read(",fontOrange,1,1);
		formatKeyword(arduinoTextPane.textField,".length(",fontOrange,1,1);
		formatKeyword(arduinoTextPane.textField,"return ",fontOrange,0,1);
		formatKeyword(arduinoTextPane.textField,".run(",fontOrange,1,1);
		formatKeyword(arduinoTextPane.textField,".runSpeed(",fontOrange,1,1);
		formatKeyword(arduinoTextPane.textField,".setMaxSpeed(",fontOrange,1,1);
		formatKeyword(arduinoTextPane.textField,".move(",fontOrange,1,1);
		formatKeyword(arduinoTextPane.textField,".moveTo(",fontOrange,1,1);
		formatKeyword(arduinoTextPane.textField,".attach(",fontOrange,1,1);
		formatKeyword(arduinoTextPane.textField,".charAt(",fontOrange,1,1);
		formatKeyword(arduinoTextPane.textField,"memset",fontOrange,0,0);
		formatKeyword(arduinoTextPane.textField,".write(",fontOrange,1,1);
		formatKeyword(arduinoTextPane.textField,".display(",fontOrange,1,1);
		formatKeyword(arduinoTextPane.textField,".setColorAt(",fontOrange,1,1);
		formatKeyword(arduinoTextPane.textField,".show(",fontOrange,1,1);
		formatKeyword(arduinoTextPane.textField,".dWrite1(",fontOrange,1,1);
		formatKeyword(arduinoTextPane.textField,".dWrite2(",fontOrange,1,1);
		formatKeyword(arduinoTextPane.textField,".dRead1(",fontOrange,1,1);
		formatKeyword(arduinoTextPane.textField,".dRead2(",fontOrange,1,1);
		formatKeyword(arduinoTextPane.textField,"delay(",fontRed,0,1);
		formatKeyword(arduinoTextPane.textField,"OUTPUT)",fontOrange,0,1);
		formatKeyword(arduinoTextPane.textField,"INPUT)",fontOrange,0,1);
		formatKeyword(arduinoTextPane.textField,"pinMode(",fontRed,0,1);
		formatKeyword(arduinoTextPane.textField,"digitalWrite(",fontRed,0,1);
		formatKeyword(arduinoTextPane.textField,"digitalRead(",fontRed,0,1);
		formatKeyword(arduinoTextPane.textField,"analogWrite(",fontRed,0,1);
		formatKeyword(arduinoTextPane.textField,"analogRead(",fontRed,0,1);
		formatKeyword(arduinoTextPane.textField,"getAngle(",fontRed,0,1);
		formatKeyword(arduinoTextPane.textField,"refresh(",fontRed,0,1);
		formatKeyword(arduinoTextPane.textField,"update(",fontRed,0,1);
		
		formatKeyword(arduinoTextPane.textField,"tone(",fontRed,0,1);
		formatKeyword(arduinoTextPane.textField,"noTone(",fontRed,0,1);
		formatKeyword(arduinoTextPane.textField,"Wire.",fontGreen,0,1);
		
		for each(var clsName:String in classNameList){
			formatKeyword(arduinoTextPane.textField, clsName, fontGreen, 0, 0);
		}
		*/
		
		htmlLoader.window.setCode(arduinoCodeText);
		
		fixlayout();
		if(ArduinoManager.sharedManager().hasUnknownCode){
			if(!isDialogBoxShowing){
				isDialogBoxShowing = true;
				var dBox:DialogBox = new DialogBox();
				dBox.addTitle(Translator.map("unsupported block found, remove them to continue."));
				for each(var b:Block in ArduinoManager.sharedManager().unknownBlocks){
					b.mouseEnabled = false;
					b.mouseChildren = false;
					dBox.addBlock(b);
				}
				function cancelHandle():void{
					isDialogBoxShowing = false;
					dBox.cancel();
				}
				dBox.addButton("OK",cancelHandle);
				dBox.showOnStage(app.stage);
				dBox.fixLayout();
			}
			arduinoFrame.visible = false;
			if(app.stageIsArduino){
				app.toggleArduinoMode();
			}
		}else{
			arduinoFrame.visible = true;
		}
		htmlLoader.visible = arduinoFrame.visible;
		return true;
	}
	static private var isDialogBoxShowing:Boolean;
//	private function formatKeyword(pattern:RegExp,format:TextFormat,subStart:uint=0,subEnd:uint=0):void
//	{
//		arduinoCodeText = arduinoCodeText.replace(pattern, '<font color="#' + format.color.toString(16) + '">$&</font>');
//	}
	public function resetCategory():void { selector.select(Specs.motionCategory) }

	public function updatePalette():void {
		selector.updateTranslation();
		if(!MBlock.app.stageIsArduino && MBlock.app.viewedObj() is ScratchStage){
			if(selector.selectedCategory == Specs.motionCategory){
				selector.selectedCategory = Specs.looksCategory;
			}
		}
		selector.select(selector.selectedCategory);
	}
	public function updateTranslation():void{
		backBt.setLabel(Translator.map("Back"));
		uploadBt.setLabel(Translator.map("Upload to Arduino"));
		openBt.setLabel(Translator.map("Edit with Arduino IDE"));
		if(htmlLoader.loaded){
			htmlLoader.window.updateTranslation();
		}
//		sendBt.setLabel(Translator.map("Send"));
//		displayModeBtn.setLabel(Translator.map(isByteDisplayMode ? "binary mode" :  "char mode"));
//		inputModeBtn.setLabel(Translator.map(isByteInputMode ? "binary mode" :  "char mode"));
	}
	private function get isByteInputMode():Boolean
	{
		return htmlLoader.window.isSendBinaryMode();
	}
	public function updateSpriteWatermark():void {
		var target:ScratchObj = app.viewedObj();
		if (target && !target.isStage) {
			spriteWatermark.bitmapData = target.currentCostume().thumbnail(40, 40, false);
		} else {
			spriteWatermark.bitmapData = null;
		}
	}

	public function step():void {
		// Update the mouse reaadouts. Do nothing if they are up-to-date (to minimize CPU load).
		var target:ScratchObj = app.viewedObj();
		if (target.isStage) {
			if (xyDisplay.visible) xyDisplay.visible = false;
		} else {
			if (!xyDisplay.visible) xyDisplay.visible = true;

			var spr:ScratchSprite = target as ScratchSprite;
			if (!spr) return;
			if (spr.scratchX != lastX) {
				lastX = spr.scratchX;
				xReadout.text = String(lastX);
			}
			if (spr.scratchY != lastY) {
				lastY = spr.scratchY;
				yReadout.text = String(lastY);
			}
		}
		updateExtensionIndicators();
	}

	private var lastUpdateTime:uint;

	private function updateExtensionIndicators():void {
		if ((getTimer() - lastUpdateTime) < 500) return;
		for (var i:int = 0; i < app.palette.numChildren; i++) {
			var indicator:IndicatorLight = app.palette.getChildAt(i) as IndicatorLight;
			if (indicator) app.extensionManager.updateIndicator(indicator, indicator.target);
		}		
		lastUpdateTime = getTimer();
	}

	public function setWidthHeight(w:int, h:int):void {
		this.w = w;
		this.h = h;
		fixlayout();
		redraw();
	}

	private function fixlayout():void {
		selector.x = 1;
		selector.y = 5;
		paletteFrame.x = selector.x;
		paletteFrame.y = selector.y + selector.height + 2;
		paletteFrame.setWidthHeight(selector.width + 1, h - paletteFrame.y - 2); // 模块滚动区域宽度
		scriptsFrame.x = selector.x + selector.width + 2;
		scriptsFrame.y = selector.y + 1;
		var arduinoWidth:uint = app.stageIsArduino?(w/2-150):0;
		var arduinoHeight:uint = h - 10;
		arduinoFrame.visible = app.stageIsArduino;
		scriptsFrame.setWidthHeight(w - scriptsFrame.x - 15-arduinoWidth, h - scriptsFrame.y - 5);//代码区
		arduinoFrame.x = scriptsFrame.x+ (w - scriptsFrame.x - 15-arduinoWidth)+8;
		arduinoFrame.y = scriptsFrame.y;
		arduinoFrame.setWidthHeight(arduinoWidth, arduinoHeight);
		htmlLoader.visible = arduinoFrame.visible;
		htmlLoader.x = arduinoFrame.x;
		htmlLoader.y = arduinoFrame.y + 40;
		htmlLoader.width = arduinoWidth;
		htmlLoader.height = arduinoHeight - 40;
//		arduinoTextPane.setWidthHeight(arduinoWidth-lineNumWidth-lineNumText.x-5,arduinoHeight-255);
//		arduinoTextPane.x = lineNumText.x+lineNumText.width+5;
//		arduinoTextPane.y = 45;
//		messageTextPane.x = 4;
//		messageTextPane.y = arduinoHeight-200;
//		messageTextPane.setWidthHeight(arduinoWidth-messageTextPane.x,155);
		openBt.x = arduinoWidth - openBt.width - 10;
//		sendTextPane.x = 8 + 200;
//		sendTextPane.y = arduinoHeight - 33;
//		sendTextPane.setWidthHeight(arduinoWidth-sendBt.width-sendTextPane.x-10,20);
//		sendBt.x = arduinoWidth - sendBt.width - 10;
//		sendBt.y = arduinoHeight - 35;
//		displayModeBtn.x = htmlLoader.width - displayModeBtn.width;
//		displayModeBtn.y = htmlLoader.height - 200;
//		inputModeBtn.x = 4;
//		inputModeBtn.y = sendBt.y;
//		messageTextPane.updateScrollbar(null);
		spriteWatermark.x = w - arduinoWidth - 60;
		spriteWatermark.y = scriptsFrame.y + 10;
		xyDisplay.x = spriteWatermark.x + 1;
		xyDisplay.y = spriteWatermark.y + 43;
		zoomWidget.x = w - arduinoWidth - zoomWidget.width - 30;
		zoomWidget.y = h - zoomWidget.height - 15;
	}

	private function redraw():void {
		var paletteW:int = paletteFrame.visibleW();
		var paletteH:int = paletteFrame.visibleH();
		var scriptsW:int = scriptsFrame.visibleW();
		var scriptsH:int = scriptsFrame.visibleH();

		var g:Graphics = shape.graphics;
		g.clear();
		g.lineStyle(1, CSS.borderColor, 1, true);
		g.beginFill(CSS.tabColor);
		g.drawRect(0, 0, w, h);
		g.endFill();

		var lineY:int = selector.y + selector.height;
		var darkerBorder:int = CSS.borderColor - 0x141414;
		var lighterBorder:int = 0xF2F2F2;
		g.lineStyle(1, darkerBorder, 1, true);
		hLine(g, paletteFrame.x + 8, lineY, paletteW - 20);
		g.lineStyle(1, lighterBorder, 1, true);
		hLine(g, paletteFrame.x + 8, lineY + 1, paletteW - 20);

		g.lineStyle(1, darkerBorder, 1, true);
		g.drawRect(scriptsFrame.x - 1, scriptsFrame.y - 1, scriptsW + 1, scriptsH + 1);
	}

	private function hLine(g:Graphics, x:int, y:int, w:int):void {
		g.moveTo(x, y);
		g.lineTo(x + w, y);
	}

	private function addXYDisplay():void {
		xyDisplay = new Sprite();
		xyDisplay.addChild(xLabel = makeLabel('x:', readoutLabelFormat, 0, 0));
		xyDisplay.addChild(xReadout = makeLabel('-888', readoutFormat, 15, 0));
		xyDisplay.addChild(yLabel = makeLabel('y:', readoutLabelFormat, 0, 13));
		xyDisplay.addChild(yReadout = makeLabel('-888', readoutFormat, 15, 13));
		addChild(xyDisplay);
	}

}}
