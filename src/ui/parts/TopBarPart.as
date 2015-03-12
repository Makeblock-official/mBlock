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

// TopBarPart.as
// John Maloney, November 2011
//
// This part holds the Scratch Logo, cursor tools, screen mode buttons, and more.

package ui.parts {
	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import assets.Resources;
	
	import extensions.ParseManager;
	import extensions.SerialManager;
	
	import translation.Translator;
	
	import uiwidgets.CursorTool;
	import uiwidgets.IconButton;
	import uiwidgets.Menu;
	import uiwidgets.SimpleTooltips;
	
	import util.ApplicationManager;

public class TopBarPart extends UIPart {

	private var shape:Shape;
	protected var languageButton:IconButton;

	protected var fileMenu:IconButton;
	protected var editMenu:IconButton;
//	protected var examplesMenu:IconButton;
	protected var serialMenu:IconButton;
	protected var bluetoothMenu:IconButton;
	protected var socketMenu:IconButton;
	protected var shareMenu:IconButton;
	protected var faqMenu:IconButton;
	protected var aboutMenu:IconButton;
	
	private var copyTool:IconButton;
	private var cutTool:IconButton;
	private var growTool:IconButton;
	private var shrinkTool:IconButton;
	private var helpTool:IconButton;
	private var toolOnMouseDown:String;

	private var offlineNotice:TextField = new TextField;
	private const offlineNoticeFormat:TextFormat = new TextFormat(CSS.font, 12, CSS.white, true,null,null,null,null,"right");

	public function TopBarPart(app:MBlock) {
		this.app = app;
		addButtons();
		refresh();
	}

	protected function addButtons():void {
		addChild(shape = new Shape());
		addChild(languageButton = new IconButton(app.setLanguagePressed, 'languageButton'));
		languageButton.x = 9;
		languageButton.isMomentary = true;
		addTextButtons();
		addToolButtons();
	}

	public static function strings():Array {
		if (MBlock.app) {
			MBlock.app.showFileMenu(Menu.dummyButton());
			MBlock.app.showEditMenu(Menu.dummyButton());
			MBlock.app.showSerialMenu(Menu.dummyButton());
			MBlock.app.showExamplesMenu(Menu.dummyButton());
		}
		return ['File', 'Edit', 'Tips', 'Duplicate', 'Delete', 'Grow', 'Shrink', 'Block help', 'Offline Editor'];
	}

	protected function removeTextButtons():void {
		if (fileMenu.parent&&serialMenu.parent) {
			removeChild(fileMenu);
			removeChild(editMenu);
//			removeChild(examplesMenu);
			removeChild(serialMenu);
			if(ApplicationManager.sharedManager().system==ApplicationManager.WINDOWS){
				removeChild(bluetoothMenu);
			}
			removeChild(socketMenu);
			removeChild(shareMenu);
			removeChild(faqMenu);
			removeChild(aboutMenu);
			removeChild(offlineNotice);
		}
	}

	public function updateTranslation():void {
		removeTextButtons();
		addTextButtons();
		updateVersion();
		refresh();
	}
	public function updateVersion():void{
		if (offlineNotice) 
		{
			offlineNotice.visible = true;
			if(ParseManager.sharedManager().firmVersion.split(".").length<=1){
				offlineNotice.text = Translator.map('Unknown Firmware');
			}else{
				var hardwareVer:uint = ParseManager.sharedManager().firmVersion.split(".")[1];
				offlineNotice.text = Translator.map('Current Firmware') + ' v '+ParseManager.sharedManager().firmVersion+(hardwareVer==1?" (Arduino)":" (mBot)");
			}
			offlineNotice.defaultTextFormat = offlineNoticeFormat;
			offlineNotice.selectable = false;
		}
	}
	public function setWidthHeight(w:int, h:int):void {
		this.w = w;
		this.h = h;
		var g:Graphics = shape.graphics;
		g.clear();
		g.beginFill(CSS.topBarColor);
		g.drawRect(0, 0, w, h);
		g.endFill();
		fixLayout();
	}

	protected function fixLayout():void {
		var buttonY:int = 5;
		languageButton.y = buttonY - 1;

		// new/more/tips buttons
		const buttonSpace:int = 12;
		var nextX:int = languageButton.x + languageButton.width + 13;
		fileMenu.x = nextX;
		fileMenu.y = buttonY;
		nextX += fileMenu.width + buttonSpace;

		editMenu.x = nextX;
		editMenu.y = buttonY;
		nextX += editMenu.width + buttonSpace;
		
//		examplesMenu.x = nextX;
//		examplesMenu.y = buttonY;
//		nextX += examplesMenu.width + buttonSpace;
		
		serialMenu.x = nextX;
		serialMenu.y = buttonY;
		nextX += serialMenu.width + buttonSpace;
		if(ApplicationManager.sharedManager().system==ApplicationManager.WINDOWS){
			bluetoothMenu.x = nextX;
			bluetoothMenu.y = buttonY;
			nextX += bluetoothMenu.width + buttonSpace;
		}
		socketMenu.x = nextX;
		socketMenu.y = buttonY;
		nextX += socketMenu.width + buttonSpace;
		
		shareMenu.x = nextX;
		shareMenu.y = buttonY;
		nextX += shareMenu.width + buttonSpace;
		
		faqMenu.x = nextX;
		faqMenu.y = buttonY;
		nextX += faqMenu.width + buttonSpace;
		
		aboutMenu.x = nextX;
		aboutMenu.y = buttonY;
		nextX += aboutMenu.width + buttonSpace;
		// cursor tool buttons
		var space:int = 3;
		copyTool.x = 760+(app.stageIsContracted?ApplicationManager.sharedManager().contractedOffsetX:0);
		cutTool.x = copyTool.right() + space;
		growTool.x = cutTool.right() + space;
		shrinkTool.x = growTool.right() + space;
		//helpTool.x = shrinkTool.right() + space;
		copyTool.y = cutTool.y = shrinkTool.y = growTool.y = 32;//buttonY - 3;

		if(offlineNotice) {
			offlineNotice.x = w - offlineNotice.width - 5;
			offlineNotice.y = 5;
		}
	}

	public function refresh():void {
		if (app.isOffline) {
			//helpTool.visible = app.isOffline;
		}
		fixLayout();
	}

	protected function addTextButtons():void {
		addChild(fileMenu = makeMenuButton('File', app.showFileMenu, true));
		addChild(editMenu = makeMenuButton('Edit', app.showEditMenu, true));
//		addChild(examplesMenu = makeMenuButton('Examples', app.showExamplesMenu, false));
		addChild(serialMenu = makeMenuButton(SerialManager.sharedManager().isConnected?(SerialManager.sharedManager().currentPort+" "+Translator.map('Connected')):'Serial Port', app.showSerialMenu, true));
		if(ApplicationManager.sharedManager().system==ApplicationManager.WINDOWS){
			addChild(bluetoothMenu = makeMenuButton(!SerialManager.sharedManager().isBluetoothSupported?"No Bluetooth":(SerialManager.sharedManager().isBluetoothConnected?'Disconnect Bluetooth':'Bluetooth'), app.openBluetooth, false));
		}
		addChild(socketMenu = makeMenuButton('Network',app.showNetworkMenu,true));
		addChild(shareMenu = makeMenuButton('Share Your Project', app.openShare, false));
		addChild(faqMenu = makeMenuButton('FAQ', app.openFaq, false));
		addChild(aboutMenu = makeMenuButton('Help', app.openAbout, true));
		addChild(offlineNotice);
		offlineNotice.visible = false;
		offlineNotice.width = 250;
	}

	private function addToolButtons():void {
		function selectTool(b:IconButton):void {
			var newTool:String = '';
			if (b == copyTool) newTool = 'copy';
			if (b == cutTool) newTool = 'cut';
			if (b == growTool) newTool = 'grow';
			if (b == shrinkTool) newTool = 'shrink';
			if (b == helpTool) newTool = 'help';
			if (newTool == toolOnMouseDown) {
				clearToolButtons();
				CursorTool.setTool(null);
			} else {
				clearToolButtonsExcept(b);
				CursorTool.setTool(newTool);
			}
		}
		addChild(copyTool = makeToolButton('copyTool', selectTool));
		addChild(cutTool = makeToolButton('cutTool', selectTool));
		addChild(growTool = makeToolButton('growTool', selectTool));
		addChild(shrinkTool = makeToolButton('shrinkTool', selectTool));
		//addChild(helpTool = makeToolButton('helpTool', selectTool));

		SimpleTooltips.add(copyTool, {text: 'Duplicate', direction: 'bottom'});
		SimpleTooltips.add(cutTool, {text: 'Delete', direction: 'bottom'});
		SimpleTooltips.add(growTool, {text: 'Grow', direction: 'bottom'});
		SimpleTooltips.add(shrinkTool, {text: 'Shrink', direction: 'bottom'});
		//SimpleTooltips.add(helpTool, {text: 'Block help', direction: 'bottom'});
	}

	public function clearToolButtons():void { clearToolButtonsExcept(null) }

	private function clearToolButtonsExcept(activeButton: IconButton):void {
		for each (var b:IconButton in [copyTool, cutTool, growTool, shrinkTool]) {
			if (b != activeButton) b.turnOff();
		}
	}

	private function makeToolButton(iconName:String, fcn:Function):IconButton {
		function mouseDown(evt:MouseEvent):void { toolOnMouseDown = CursorTool.tool }
		var onImage:Sprite = toolButtonImage(iconName, 0xcfefff, 1);
		var offImage:Sprite = toolButtonImage(iconName, 0, 0);
		var b:IconButton = new IconButton(fcn, onImage, offImage);
		b.actOnMouseUp();
		b.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown); // capture tool on mouse down to support deselecting
		return b;
	}

	private function toolButtonImage(iconName:String, color:int, alpha:Number):Sprite {
		const w:int = 23;
		const h:int = 24;
		var img:Bitmap;
		var result:Sprite = new Sprite();
		var g:Graphics = result.graphics;
		g.clear();
		g.beginFill(color, alpha);
		g.drawRoundRect(0, 0, w, h, 8, 8);
		g.endFill();
		result.addChild(img = Resources.createBmp(iconName));
		img.x = Math.floor((w - img.width) / 2);
		img.y = Math.floor((h - img.height) / 2);
		return result;
	}

	protected function makeButtonImg(s:String, c:int, isOn:Boolean):Sprite {
		var result:Sprite = new Sprite();

		var label:TextField = makeLabel(Translator.map(s), CSS.topBarButtonFormat, 2, 2);
		label.textColor = CSS.white;
		label.x = 6;
		result.addChild(label); // label disabled for now

		var w:int = label.textWidth + 16;
		var h:int = 22;
		var g:Graphics = result.graphics;
		g.clear();
		g.beginFill(c);
		g.drawRoundRect(0, 0, w, h, 8, 8);
		g.endFill();

		return result;
	}
	public function setConnectedTitle(title:String):void{
		removeChild(serialMenu);
		addChild(serialMenu = makeMenuButton(title, app.showSerialMenu, true));
		this.fixLayout();
	}
	public function setSocketConnectedTitle(title:String):void{
		removeChild(socketMenu);
		addChild(socketMenu = makeMenuButton(title, app.showNetworkMenu, true));
		this.fixLayout();
	}
	public function setBluetoothTitle(connected:Boolean):void{
		if(ApplicationManager.sharedManager().system==ApplicationManager.WINDOWS){
			removeChild(bluetoothMenu);
			addChild(bluetoothMenu = makeMenuButton(!SerialManager.sharedManager().isBluetoothSupported?"No Bluetooth":(connected?"Disconnect Bluetooth":"Bluetooth"), app.openBluetooth, false));
		}
		this.fixLayout();
	}
	public function setDisconnectedTitle():void{
		removeChild(serialMenu);
		addChild(serialMenu = makeMenuButton('Serial Port', app.showSerialMenu, true));
		this.fixLayout();
	}
	public function setSocketDisconnectedTitle():void{
		removeChild(socketMenu);
		addChild(socketMenu = makeMenuButton('Network', app.showNetworkMenu, true));
		this.fixLayout();
	}
}}
