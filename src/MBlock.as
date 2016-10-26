package {
	import com.google.analytics.GATracker;
	
	import flash.desktop.NativeApplication;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.UncaughtErrorEvent;
	import flash.filesystem.File;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.system.System;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	
	import blockly.runtime.Thread;
	
	import blocks.Block;
	
	import cc.makeblock.mbot.lookandfeel.MyLookAndFeel;
	import cc.makeblock.mbot.ui.parts.TopSystemMenu;
	import cc.makeblock.mbot.uiwidgets.errorreport.ErrorReportFrame;
	import cc.makeblock.mbot.util.AppTitleMgr;
	import cc.makeblock.mbot.util.PopupUtil;
	import cc.makeblock.menu.MenuBuilder;
	import cc.makeblock.updater.AppUpdater;
	import cc.makeblock.util.FileUtil;
	import cc.makeblock.util.FlashSprite;
	import cc.makeblock.util.InvokeMgr;
	
	import extensions.BluetoothManager;
	import extensions.DeviceManager;
	import extensions.ExtensionManager;
	import extensions.HIDManager;
	import extensions.SerialManager;
	import extensions.SocketManager;
	
	import interpreter.Interpreter;
	
	import org.aswing.AsWingManager;
	import org.aswing.JOptionPane;
	import org.aswing.UIManager;
	
	import scratch.BlockMenus;
	import scratch.PaletteBuilder;
	import scratch.ScratchCostume;
	import scratch.ScratchObj;
	import scratch.ScratchRuntime;
	import scratch.ScratchSound;
	import scratch.ScratchSprite;
	import scratch.ScratchStage;
	
	import translation.Translator;
	
	import ui.BlockPalette;
	import ui.CameraDialog;
	import ui.LoadProgress;
	import ui.PaletteSelector;
	import ui.media.MediaInfo;
	import ui.media.MediaLibrary;
	import ui.media.MediaPane;
	import ui.parts.ImagesPart;
	import ui.parts.LibraryPart;
	import ui.parts.ScriptsPart;
	import ui.parts.SoundsPart;
	import ui.parts.StagePart;
	import ui.parts.TabsPart;
	import ui.parts.TopBarPart;
	
	import uiwidgets.CursorTool;
	import uiwidgets.DialogBox;
	import uiwidgets.Menu;
	import uiwidgets.ScriptsPane;
	
	import util.ApplicationManager;
	import util.DESParser;
	import util.GestureHandler;
	import util.LogManager;
	import util.ProjectIO;
	import util.Server;
	import util.SharedObjectManager;
	
	import watchers.ListWatcher;

	[SWF(frameRate="30")]
	public class MBlock extends Sprite {
		// Version
		private static var vxml:XML = NativeApplication.nativeApplication.applicationDescriptor; 
		private static var xmlns:Namespace = new Namespace(vxml.namespace());
	
		public static const versionString:String = 'v'+vxml.xmlns::versionNumber;
		public static var app:MBlock; // static reference to the app, used for debugging
	
		// Display modes
		public var editMode:Boolean; // true when project editor showing, false when only the player is showing
//		public const isOffline:Boolean = true; // true when running as an offline (i.e. stand-alone) app
		public var isSmallPlayer:Boolean; // true when displaying as a scaled-down player (e.g. in search results)
		public var stageIsContracted:Boolean; // true when the stage is half size to give more space on small screens
		public var stageIsHided:Boolean;
		public var stageIsArduino:Boolean;
	
		private var systemMenu:TopSystemMenu;
		
		// Runtime
		public var runtime:ScratchRuntime;
		public var interp:Interpreter;
		public var extensionManager:ExtensionManager;
		public const server:Server = new Server();
		public var gh:GestureHandler;
		
		private var projectFile:File;
		public var projectID:String = '';
		public var loadInProgress:Boolean;
	
		private var viewedObject:ScratchObj;
		private var lastTab:String = 'scripts';
		protected var wasEdited:Boolean; // true if the project was edited and autosaved
		private var _usesUserNameBlock:Boolean = false;
//		protected var languageChanged:Boolean; // set when language changed
	
		// UI Elements
		public var palette:BlockPalette;
		public var scriptsPane:ScriptsPane;
		public var stagePane:ScratchStage;
		public var mediaLibrary:MediaLibrary;
		public var lp:LoadProgress;
		public var cameraDialog:CameraDialog;
	
		// UI Parts
		public var libraryPart:LibraryPart;
		public var topBarPart:TopBarPart;
		public var scriptsPart:ScriptsPart;
		public var imagesPart:ImagesPart;
		protected var soundsPart:SoundsPart;
		protected var stagePart:StagePart;
		private var ga:GATracker;
		private var tabsPart:TabsPart;
		private var _welcomeView:Loader;
		private var _currentVer:String = "05.05.001";
		public function MBlock(){
			app = this;
			addEventListener(Event.ADDED_TO_STAGE,initStage);
			loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, __onError);
//			trace(DESParser.decryptDES("123456","2YNQ6N8ahls0YmQ1NGI3OTkzMWM2OWM5YTczNDUzNGQ="));
//			trace(DESParser.encryptDES("123456",'05f40ce31c9e4d339c75a77007d479b8'));//face
//			trace(DESParser.encryptDES("123456",'212ea29742574cae8add9ad79abcfe4a'));//speech
//			trace(DESParser.encryptDES("123456",'2a71aa9ef2fc478e8e35b13ca65d9e3f'));//emotion
//			trace(DESParser.encryptDES("123456",'d30bb3fa0e40461eaf1d0b11b609a75a'));//text
			SharedObjectManager.sharedManager().loadRemoteConfig();
		}
		static private var errorFlag:Boolean;
		private function __onError(evt:UncaughtErrorEvent):void
		{
			var errorText:String;
			if(evt.error is Error){
				errorText = (evt.error as Error).getStackTrace();
			}else if(evt.error is ErrorEvent){
				errorText = (evt.error as ErrorEvent).text;
			}
			if(!Boolean(errorText) || errorFlag){
				return;
			}
			errorFlag = true;
			ErrorReportFrame.OpenSendWindow(errorText);
		}
		
		private function initStage(evt:Event):void{
			removeEventListener(Event.ADDED_TO_STAGE,initStage);
			stage.nativeWindow.title += "(" + versionString + ")";
			AsWingManager.initAsStandard(this);
			UIManager.setLookAndFeel(new MyLookAndFeel());
			AppTitleMgr.Instance.init(stage.nativeWindow);
//			ApplicationManager.sharedManager().isCatVersion = NativeApplication.nativeApplication.applicationDescriptor.toString().indexOf("猫友")>-1;
			ga = new GATracker(this,"UA-54268669-1","AS3",false);
			track("/app/launch");
			new InvokeMgr();
			stage.nativeWindow.addEventListener(Event.CLOSING,onExiting);
			AppUpdater.getInstance().start();
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			if(SharedObjectManager.sharedManager().available("labelSize")){
				var labelSize:int = SharedObjectManager.sharedManager().getObject("labelSize") as int;
				var argSize:int = Math.round(0.9 * labelSize);
				var vOffset:int = labelSize > 13 ? 1 : 0;
				Block.setFonts(labelSize, argSize, false, vOffset);
			}else{
				Block.setFonts(14, 12, true, 0); // default font sizes
			}
			Block.MenuHandlerFunction = BlockMenus.BlockMenuHandler;
			CursorTool.init(this);

			stagePane = new ScratchStage();
			gh = new GestureHandler(this);
			initInterpreter();
			initRuntime();
//			try{
				extensionManager = new ExtensionManager(this);
				var extensionsPath:File = ApplicationManager.sharedManager().documents.resolvePath("mBlock");
				if(!extensionsPath.exists){
					SharedObjectManager.sharedManager().clear();
					SharedObjectManager.sharedManager().setObject(versionString+".0."+_currentVer,true);
					extensionManager.copyLocalFiles();
				}
				
		//		extensionManager.importExtension();
				addParts();
				systemMenu = new TopSystemMenu(stage, "assets/menu.xml");
				Translator.initializeLanguageList();
//				playerBG = new Shape(); // create, but don't add
				stage.addEventListener(MouseEvent.MOUSE_DOWN, gh.mouseDown);
				stage.addEventListener(MouseEvent.MOUSE_MOVE, gh.mouseMove);
				stage.addEventListener(MouseEvent.MOUSE_UP, gh.mouseUp);
				stage.addEventListener(MouseEvent.MOUSE_WHEEL, gh.mouseWheel);
				stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, gh.onRightMouseDown);
				stage.addEventListener(KeyboardEvent.KEY_DOWN, runtime.keyDown);
				stage.addEventListener(KeyboardEvent.KEY_UP, runtime.keyUp);
				stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown); // to handle escape key
				stage.addEventListener(Event.ENTER_FRAME, step);
				stage.addEventListener(Event.RESIZE, onResize);
				setEditMode(true);
			// install project before calling fixLayout()
			if (editMode) runtime.installNewProject();
			else runtime.installEmptyProject();
			
			fixLayout();
			setTimeout(SocketManager.sharedManager, 100);
			setTimeout(DeviceManager.sharedManager, 100);
			if(!SharedObjectManager.sharedManager().getObject(versionString+".0."+_currentVer,false)){
				//SharedObjectManager.sharedManager().clear();
				SharedObjectManager.sharedManager().setObject(versionString+".0."+_currentVer,true);
				extensionsPath.deleteDirectory(true);
				extensionManager.copyLocalFiles();
				SharedObjectManager.sharedManager().setObject("first-launch",true);
				
				//SharedObjectManager.sharedManager().setObject("board","mbot_uno");
			}
			//VersionManager.sharedManager().start(); //在线更新资源文件
			if(SharedObjectManager.sharedManager().getObject("first-launch",true)){
				SharedObjectManager.sharedManager().setObject("first-launch",false);
				openWelcome();
			}
			initExtension();
			MenuBuilder.BuildMenuList(XMLList(FileUtil.LoadFile("assets/context_menus.xml")));
		}
		private function initExtension():void{
//			ClickerManager.sharedManager().update();
			SerialManager.sharedManager().setMBlock(this);
			HIDManager.sharedManager().setMBlock(this);
		}
		private function openWelcome():void{
			openSwf("welcome.swf");
		}
		public function openOrion():void{
			openSwf("orion_buzzer.swf");
		}
		private function openSwf(path:String):void
		{
			_welcomeView = new Loader();
			_welcomeView.load(new URLRequest(path));
			_welcomeView.contentLoaderInfo.addEventListener(Event.COMPLETE,onWelcomeLoaded);
		}
		private function onWelcomeLoaded(evt:Event):void{
			var w:uint = stage.stageWidth;
			var h:uint = stage.stageHeight;
			_welcomeView.x = (w-550)/2;
			_welcomeView.y = (h-400)/2+30;
			setTimeout(addChild, 500, _welcomeView);
		}
		
		public function track(msg:String):void{
			ga.trackPageview(
				(ApplicationManager.sharedManager().isCatVersion?"/myh/":"/") + MBlock.versionString + msg
			);
		}
		
		protected function initTopBarPart():void {
			topBarPart = new TopBarPart(this);
		}
	
		protected function initInterpreter():void {
			interp = new Interpreter(this);
		}
	
		protected function initRuntime():void {
			runtime = new ScratchRuntime(this, interp);
		}
	
		public function showTip(tipName:String):void {}
		public function closeTips():void {}
		public function reopenTips():void {}
	
		public function getMediaLibrary(app:MBlock, type:String, whenDone:Function):MediaLibrary {
			return new MediaLibrary(app, type, whenDone);
		}
	
		public function getMediaPane(app:MBlock, type:String):MediaPane {
			return new MediaPane(app, type);
		}
	
		public function getScratchStage():ScratchStage {
			return new ScratchStage();
		}
	
		public function getPaletteBuilder():PaletteBuilder {
			return new PaletteBuilder(this);
		}
		
		private function onExiting(evt:Event):void{
			if(saveNeeded){
				evt.preventDefault();
				saveProjectAndThen(quitApp);
			}
			MBlock.app.gh.mouseUp(new MouseEvent(MouseEvent.MOUSE_UP));
			SerialManager.sharedManager().disconnect();
			HIDManager.sharedManager().disconnect();
		}
		
		public function quitApp():void
		{
			NativeApplication.nativeApplication.exit();
			track("/app/exit");
			LogManager.sharedManager().save();
		}
		
		public function log(s:String):void {
			LogManager.sharedManager().log(s+"\r\n");
		}
	
		public function logMessage(msg:String, extra_data:Object=null):void {
			trace(msg);
		}
		public function loadProjectFailed():void {}
		
		public function clearCachedBitmaps():void {
			for(var i:int=0; i<stagePane.numChildren; ++i) {
				var spr:ScratchSprite = (stagePane.getChildAt(i) as ScratchSprite);
				if(spr) spr.clearCachedBitmap();
			}
			stagePane.clearCachedBitmap();
	
			System.gc();
		}
	
		public function viewedObj():ScratchObj { return viewedObject; }
		public function stageObj():ScratchStage { return stagePane; }
		public function projectName():String { return stagePart.projectName(); }
		public function highlightSprites(sprites:Array):void { libraryPart.highlight(sprites); }
		public function refreshImageTab(fromEditor:Boolean):void { imagesPart.refresh(fromEditor); }
		public function refreshSoundTab():void { soundsPart.refresh(); }
		public function selectCostume():void { imagesPart.selectCostume(); }
		public function selectSound(snd:ScratchSound):void { soundsPart.selectSound(snd); }
		public function clearTool():void { CursorTool.setTool(null); topBarPart.clearToolButtons(); }
		public function tabsRight():int { return tabsPart.x + tabsPart.w; }
		public function enableEditorTools(flag:Boolean):void { imagesPart.editor.enableTools(flag); }
	
		public function get usesUserNameBlock():Boolean {
			return _usesUserNameBlock;
		}
	
		public function set usesUserNameBlock(value:Boolean):void {
			_usesUserNameBlock = value;
			stagePart.refresh();
		}
	
		public function updatePalette(clearCaches:Boolean = true):void {
			// Note: updatePalette() is called after changing variable, list, or procedure
			// definitions, so this is a convenient place to clear the interpreter's caches.
			if (isShowing(scriptsPart)) scriptsPart.updatePalette();
			if (clearCaches) runtime.clearAllCaches();
		}
		
		public function setProjectFile(file:File):void
		{
			if(file != null){
				setProjectName(file.name);
			}else{
				setProjectName('Untitled');
			}
			projectFile = file;
		}
	
		private function setProjectName(s:String):void {
			if (s.slice(-3) == '.sb') s = s.slice(0, -3);
			if (s.slice(-4) == '.sb2') s = s.slice(0, -4);
			stagePart.setProjectName(s);
		}
	
		protected var wasEditing:Boolean;
		public function setPresentationMode(enterPresentation:Boolean):void {
			if (enterPresentation) {
				wasEditing = editMode;
				if (wasEditing) {
					setEditMode(false);
				}
			} else if (wasEditing){
				setEditMode(true);
			}
			
			track(enterPresentation?"/enterFullscreen":"/enterNormal");
			stage.displayState = enterPresentation ? StageDisplayState.FULL_SCREEN_INTERACTIVE : StageDisplayState.NORMAL;
			
			for each (var o:ScratchObj in stagePane.allObjects()) o.applyFilters();
	
			if (lp) fixLoadProgressLayout();
			stagePane.updateCostume();
		}
	
		private function keyDown(evt:KeyboardEvent):void {
			// Escape exists presentation mode.
			if ((evt.charCode == Keyboard.ESCAPE) && stagePart.isInPresentationMode()) {
				setPresentationMode(false);
				stagePart.exitPresentationMode();
			}
			if(evt.ctrlKey && evt.keyCode == Keyboard.P){
				FileUtil.PrintScreen();
			}
		}
	
		private function setSmallStageMode(flag:Boolean):void {
			stageIsContracted = flag;
			stagePart.refresh();
			fixLayout();
			libraryPart.refresh();
			tabsPart.refresh();
			stagePane.applyFilters();
			stagePane.updateCostume();
		}
	
		public function projectLoaded():void {
			removeLoadProgressBox();
			System.gc();
//			if (autostart) runtime.startGreenFlags(true);
			saveNeeded = false;
	
			// translate the blocks of the newly loaded project
			for each (var o:ScratchObj in stagePane.allObjects()) {
				o.updateScriptsAfterTranslation();
			}
		}
	
		protected function step(e:Event):void {
			// Step the runtime system and all UI components.
			gh.step();
			runtime.stepRuntime();
			stagePart.step();
			libraryPart.step();
			scriptsPart.step();
			imagesPart.step();
		}
	
		public function updateSpriteLibrary(sortByIndex:Boolean = false):void { libraryPart.refresh() }
		public function threadStarted():void { stagePart.threadStarted() }
	
		public function selectSprite(obj:ScratchObj):void {
			if (isShowing(imagesPart)) imagesPart.editor.shutdown();
			if (isShowing(soundsPart)) soundsPart.editor.shutdown();
			viewedObject = obj;
			libraryPart.refresh();
			tabsPart.refresh();
			if (isShowing(imagesPart)) {
				imagesPart.refresh();
			}
			if (isShowing(soundsPart)) {
				soundsPart.currentIndex = 0;
				soundsPart.refresh();
			}
			if (isShowing(scriptsPart)) {
				scriptsPart.updatePalette();
				scriptsPane.viewScriptsFor(obj);
				scriptsPart.updateSpriteWatermark();
			}
		}
	
		public function setTab(tabName:String):void {
			if (isShowing(imagesPart)) imagesPart.editor.shutdown();
			if (isShowing(soundsPart)) soundsPart.editor.shutdown();
			hide(scriptsPart);
			hide(imagesPart);
			hide(soundsPart);
			if (!editMode) return;
			if (tabName == 'images') {
				show(imagesPart);
				imagesPart.refresh();
			} else if (tabName == 'sounds') {
				soundsPart.refresh();
				show(soundsPart);
			} else if (tabName && (tabName.length > 0)) {
				tabName = 'scripts';
				scriptsPart.updatePalette();
				scriptsPane.viewScriptsFor(viewedObject);
				scriptsPart.updateSpriteWatermark();
				show(scriptsPart);
			}
			show(tabsPart);
			show(stagePart); // put stage in front
			tabsPart.selectTab(tabName);
			lastTab = tabName;
			if (saveNeeded) setSaveNeeded(true); // save project when switching tabs, if needed (but NOT while loading!)
		}
	
		public function installStage(newStage:ScratchStage):void {
			var showGreenflagOverlay:Boolean = shouldShowGreenFlag();
			stagePart.installStage(newStage, showGreenflagOverlay);
			selectSprite(newStage);
			libraryPart.refresh();
			setTab('scripts');
			scriptsPart.resetCategory();
			wasEdited = false;
		}
	
		protected function shouldShowGreenFlag():Boolean {
			return !editMode;
		}
	
		protected function addParts():void {
			initTopBarPart();
			stagePart = getStagePart();
			libraryPart = getLibraryPart();
			tabsPart = new TabsPart(this);
			scriptsPart = new ScriptsPart(this);
			imagesPart = new ImagesPart(this);
			soundsPart = new SoundsPart(this);
			addChild(stagePart);
			addChild(libraryPart);
			addChild(tabsPart);
			addChild(topBarPart);
		}
	
		protected function getStagePart():StagePart {
			return new StagePart(this);
		}
	
		protected function getLibraryPart():LibraryPart {
			return new LibraryPart(this);
		}
	
		// -----------------------------
		// UI Modes and Resizing
		//------------------------------
	
		private function setEditMode(newMode:Boolean):void {
			Menu.removeMenusFrom(stage);
			editMode = newMode;
			if (editMode) {
//				hide(playerBG);
				show(topBarPart);
				show(libraryPart);
				show(tabsPart);
				setTab(lastTab);
				stagePart.hidePlayButton();
				runtime.edgeTriggersEnabled = true;
			} else {
//				addChildAt(playerBG, 0); // behind everything
//				playerBG.visible = false;
				hide(topBarPart);
				hide(libraryPart);
				hide(tabsPart);
				setTab(null); // hides scripts, images, and sounds
			}
			show(stagePart); // put stage in front
			fixLayout();
			stagePart.refresh();
		}
	
		protected function hide(obj:DisplayObject):void { if (obj.parent) obj.parent.removeChild(obj) }
		protected function show(obj:DisplayObject):void { addChild(obj) }
		protected function isShowing(obj:DisplayObject):Boolean { return obj.parent != null }
	
		private function onResize(e:Event):void {
			fixLayout();
			
		}
	
		private function fixLayout():void {
			var w:int = stage.stageWidth;
			var h:int = stage.stageHeight - 1; // fix to show bottom border...
	
			w = Math.ceil(w / scaleX);
			h = Math.ceil(h / scaleY);
	
			updateLayout(w, h);
			if(_welcomeView){
				_welcomeView.x = (w-550)/2;
				_welcomeView.y = (h-400)/2+30;
			}
		}
	
		protected function updateLayout(w:int, h:int):void {
//			topBarPart.x = 0;
//			topBarPart.y = 0;
//			topBarPart.setWidthHeight(w, 28);
			topBarPart.setWidthHeight(w, 0);
	
			var extraW:int = 0;
			var extraH:int = stagePart.computeTopBarHeight() + 1;
			if (editMode) {
				
				if(stageIsHided){
					stagePart.hideFullScreenButton();
					stagePart.setWidthHeight((240+ApplicationManager.sharedManager().contractedOffsetX/2) + extraW, ApplicationManager.sharedManager().contractedOffsetY+stage.stageHeight/2, 0.0);
				}
				// adjust for global scale (from browser zoom)
				else if (stageIsContracted) {
					stagePart.showFullScreenButton();
//					stagePart.setWidthHeight((240+ApplicationManager.sharedManager().contractedOffsetX/2) + extraW, ApplicationManager.sharedManager().contractedOffsetY+stage.stageHeight/2, 0.0);
					stagePart.setWidthHeight(240 + extraW, 180 + extraH, 0.5);
				} else {
					stagePart.showFullScreenButton();
					stagePart.setWidthHeight(480 + extraW, 360 + extraH, 1);
				}
				stagePart.x = 5;
				stagePart.y = topBarPart.bottom() + 5;
			} else {
				var pad:int = (w > 550) ? 16 : 0; // add padding for full-screen mode
				var scale:Number = Math.min((w - extraW - pad) / 480, (h - extraH - pad) / 360);
				scale = Math.max(0.01, scale);
				var scaledW:int = Math.floor((scale * 480) / 4) * 4; // round down to a multiple of 4
				scale = scaledW / 480;
				var playerW:Number = (scale * 480) + extraW;
				var playerH:Number = (scale * 360) + extraH;
				stagePart.setWidthHeight(playerW, playerH, scale);
				stagePart.x = int((w - playerW) / 2);
				stagePart.y = int((h - playerH) / 2);
				fixLoadProgressLayout();
				return;
			}
			libraryPart.x = stagePart.x;
			libraryPart.y = stagePart.bottom() + 18;
			libraryPart.setWidthHeight(stagePart.w, h - libraryPart.y);
	
			tabsPart.x = stagePart.right() + 5;
			tabsPart.y = topBarPart.bottom() + 5;
			tabsPart.fixLayout();
	
			// the content area shows the part associated with the currently selected :
			var contentY:int = tabsPart.y + 27;
			updateContentArea(tabsPart.x, contentY, w - tabsPart.x - 6, h - contentY - 5, h);
		}
	
		protected function updateContentArea(contentX:int, contentY:int, contentW:int, contentH:int, fullH:int):void {
			imagesPart.x = soundsPart.x = scriptsPart.x = contentX;
			imagesPart.y = soundsPart.y = scriptsPart.y = contentY;
			imagesPart.setWidthHeight(contentW, contentH);
			soundsPart.setWidthHeight(contentW, contentH);
			scriptsPart.setWidthHeight(contentW, contentH);
	
			if (mediaLibrary) mediaLibrary.setWidthHeight(topBarPart.w, fullH);
		}
	
		// -----------------------------
		// Translations utilities
		//------------------------------
	
		public function translationChanged():void {
			// The translation has changed. Fix scripts and update the UI.
			// directionChanged is true if the writing direction (e.g. left-to-right) has changed.
			for each (var o:ScratchObj in stagePane.allObjects()) {
				o.updateScriptsAfterTranslation();
			}
			var uiLayer:Sprite = app.stagePane.getUILayer();
			for (var i:int = 0; i < uiLayer.numChildren; ++i) {
				var lw:ListWatcher = uiLayer.getChildAt(i) as ListWatcher;
				if (lw) lw.updateTranslation();
			}
			topBarPart.updateTranslation();
			stagePart.updateTranslation();
			libraryPart.updateTranslation();
			tabsPart.updateTranslation();
			updatePalette(false);
			imagesPart.updateTranslation();
			soundsPart.updateTranslation();
			scriptsPart.updateTranslation();
			
			systemMenu.changeLang();
		}
		
		public function openBluetooth(b:*):void{
			BluetoothManager.sharedManager().discover();
		}
		
		private function clearProject():void
		{
			startNewProject('', '');
			setProjectFile(null);
			topBarPart.refresh();
			stagePart.refresh();
		}
	
		public function createNewProject(ignore:* = null):void {
			saveProjectAndThen(clearProject);
			//AppTitleMgr.Instance.setProjectModifyInfo(true);
		}
	
		public function saveProjectAndThen(postSaveAction:Function = null):void {
			// Give the user a chance to save their project, if needed, then call postSaveAction.
			/*
			function doNothing():void {}
			function cancel():void { d.cancel(); }
			function proceedWithoutSaving():void { d.cancel(); postSaveAction() }
			function save():void {
				d.cancel();
				exportProjectToFile(false,postSaveAction); // if this succeeds, saveNeeded will become false
				if (!saveNeeded) postSaveAction();
			}
			if (postSaveAction == null) postSaveAction = doNothing;
			*/
			if(isPanelShowing){
				return;
			}
			if (!saveNeeded) {
				if(postSaveAction != null){
					postSaveAction();
				}
				return;
			}
			/*
			var d:DialogBox = new DialogBox();
			d.addTitle(Translator.map('Save project') + '?');
			d.addButton('Save', save);
			d.addButton('Don\'t save', proceedWithoutSaving);
			d.addButton('Cancel', cancel);
			d.showOnStage(stage);
			*/
			isPanelShowing = true;
			PopupUtil.showQuitAlert(function(value:int):void{
				switch(value){
					case JOptionPane.YES:
						exportProjectToFile(postSaveAction);
						break;
					case JOptionPane.NO:
						if(postSaveAction != null){
							postSaveAction();
						}
						break;
				}
				isPanelShowing = false;
			});
		}
		
		public function saveFile():void
		{
			if(null == projectFile){
				exportProjectToFile();
				return;
			}
			if(!saveNeeded){
				return;
			}
			var projIO:ProjectIO = new ProjectIO(this);
			projIO.convertSqueakSounds(stagePane, __onSqueakSoundsConverted);
		}
		
		private function __onSqueakSoundsConverted(projIO:ProjectIO):void
		{
			saveNeeded = false;
			scriptsPane.saveScripts(false);
			FileUtil.WriteBytes(projectFile, projIO.encodeProjectAsZipFile(stagePane));
		}
		
		private var isPanelShowing:Boolean;
	
		public function exportProjectToFile(postSaveAction:Function=null):void {
			function squeakSoundsConverted(projIO:ProjectIO):void {
				scriptsPane.saveScripts(false);
//				var zipData:ByteArray = projIO.encodeProjectAsZipFile(stagePane);
				var file:File;
				if(projectFile != null && postSaveAction!=null){
					//如果项目已存在，并且回调函数不为空，说明当前是关闭前的保存，那么就在这个file上进行保存，并且关闭
					file = projectFile.clone();
					FileUtil.WriteBytes(file, projIO.encodeProjectAsZipFile(stagePane));
					saveNeeded = false;
					setProjectFile(file);
					if(postSaveAction!=null){
						postSaveAction();
					}
					
				}else{
					var defaultName:String = (projectName().length > 1) ? projectName() + '.sb2' : 'project.sb2';
					var path:String = fixFileName(defaultName);
					file = File.desktopDirectory.resolvePath(path);
					file.addEventListener(Event.SELECT, fileSaved);
					file.browseForSave("please choose file location");
				}
				
//				file.save(zipData, path);
			}
			function fileSaved(e:Event):void {
				var file:File = e.target as File;
				//自动为文件名加上后缀，如果用户没指定的话
				if(file.url.substr(file.url.length-4)!=".sb2")
				{
					file = File.desktopDirectory.resolvePath(file.url+".sb2");
				}
				FileUtil.WriteBytes(file, projIO.encodeProjectAsZipFile(stagePane));
				
				saveNeeded = false;
				setProjectFile(file);
				if(postSaveAction!=null){
					postSaveAction();
				}
			}
			if (loadInProgress) return;
			var projIO:ProjectIO = new ProjectIO(this);
			projIO.convertSqueakSounds(stagePane, squeakSoundsConverted);
		}
	
		private static function fixFileName(s:String):String {
			// Replace illegal characters in the given string with dashes.
			const illegal:String = '\\/:*?"<>|%';
			var result:String = '';
			for (var i:int = 0; i < s.length; i++) {
				var ch:String = s.charAt(i);
				if ((i == 0) && ('.' == ch)) ch = '-'; // don't allow leading period
				result += (illegal.indexOf(ch) > -1) ? '-' : ch;
			}
			return result;
		}
		
		public function toggleHideStage():void
		{
			stageIsHided = !stageIsHided;
			setSmallStageMode(stageIsContracted);
		}
	
		public function toggleSmallStage():void {
			if(stageIsHided){
				stageIsHided = false;
				setSmallStageMode(stageIsContracted);
			}else{
				setSmallStageMode(!stageIsContracted);
			}
		}
	
		public function toggleTurboMode():void {
			Thread.REDRAW_FLAG = interp.turboMode;
			interp.turboMode = !interp.turboMode;
			stagePart.refresh();
		}
		public function changeToArduinoMode():void{
			toggleArduinoMode();
			if(stageIsArduino)
				scriptsPart.showArduinoCode();
		}
		
		public function toggleArduinoMode():void {
			stageIsArduino = !stageIsArduino;
			stageIsHided = stageIsArduino;
			setSmallStageMode(stageIsArduino);
			
			if(stageIsArduino){
				var category:int = scriptsPart.selector.selectedCategory;
				if(!PaletteSelector.canUseInArduinoMode(category)){
					scriptsPart.selector.select(Specs.controlCategory);
				}
			}
			
//			this.scriptsPart.selector.select(stageIsArduino?6:1);
			this.tabsPart.soundsTab.visible = !stageIsArduino;
			this.tabsPart.imagesTab.visible = !stageIsArduino;
			setTab("scripts");
		}
	
		public function showBubble(text:String, x:* = null, y:* = null, width:Number = 0):void {
			if (x == null) x = stage.mouseX;
			if (y == null) y = stage.mouseY;
			gh.showBubble(text, Number(x), Number(y), width);
		}
	
		public function startNewProject(newOwner:String, newID:String):void {
			runtime.installNewProject();
//			projectOwner = newOwner;
			projectID = newID;
//			projectIsPrivate = true;
			loadInProgress = false;
			saveNeeded = true;
		}
	
		// -----------------------------
		// Save status
		//------------------------------
	
		private var _saveNeeded:Boolean;
		
		private function get saveNeeded():Boolean{
			return _saveNeeded;
		}
		private function set saveNeeded(value:Boolean):void{
			if(_saveNeeded == value){
				return;
			}
			_saveNeeded = value;
			AppTitleMgr.Instance.setProjectModifyInfo(_saveNeeded);
		}
	
		public function setSaveNeeded(saveNow:Boolean = false):void {
			saveNow = false;
			// Set saveNeeded flag and update the status string.
			saveNeeded = true;
			if (!wasEdited){ saveNow = true;} // force a save on first change
			//clearRevertUndo();//这里是根据积木是否有改动设置是否需要保存代码，保存代码的时候不应该清除revertUndo，否则revertUndo一直是null
		}
	
		protected function clearSaveNeeded():void {
			// Clear saveNeeded flag and update the status string.
//			function twoDigits(n:int):String { return ((n < 10) ? '0' : '') + n }
			saveNeeded = false;
			wasEdited = true;
		}
		public function openMicrosoftCognitiveSetting(msg:String):void{
			var dialogBox:DialogBox = new DialogBox( function():void{
				var keyFace:String = dialogBox.getField(Translator.toHeadUpperCase(Translator.map("face")));
				var keyEmotion:String = dialogBox.getField(Translator.toHeadUpperCase(Translator.map("emotion")));
				var keyOCR:String = dialogBox.getField(Translator.toHeadUpperCase(Translator.map("text")));
				var keySpeaker:String = dialogBox.getField(Translator.toHeadUpperCase(Translator.map("speaker")));
				var keySpeech:String = dialogBox.getField(Translator.toHeadUpperCase(Translator.map("speech")));
				SharedObjectManager.sharedManager().setObject("keyFace-user",keyFace);
				SharedObjectManager.sharedManager().setObject("keyEmotion-user",keyEmotion);
				SharedObjectManager.sharedManager().setObject("keyOCR-user",keyOCR);
				SharedObjectManager.sharedManager().setObject("keySpeaker-user",keySpeaker);
				SharedObjectManager.sharedManager().setObject("keySpeech-user",keySpeech); 
				MBlock.app.track("/OxfordAi/setting/save");
			}); 
			dialogBox.setTitle(msg+" "+Translator.map("API Key"));
			dialogBox.addField(Translator.toHeadUpperCase(Translator.map("face")),300,SharedObjectManager.sharedManager().getObject("keyFace-user",""),true);
			dialogBox.addField(Translator.toHeadUpperCase(Translator.map("emotion")),300,SharedObjectManager.sharedManager().getObject("keyEmotion-user",""),true);
			dialogBox.addField(Translator.toHeadUpperCase(Translator.map("text")),300,SharedObjectManager.sharedManager().getObject("keyOCR-user",""),true);
			//dialogBox.addField("声纹识别",300,SharedObjectManager.sharedManager().getObject("keySpeaker",""),true);
			dialogBox.addField(Translator.toHeadUpperCase(Translator.map("speech")),300,SharedObjectManager.sharedManager().getObject("keySpeech-user",""),true);
			dialogBox.addText("<a href='https://www.microsoft.com/cognitive-services' style='color:#0000ff'>https://www.microsoft.com/cognitive-services</a>");
			dialogBox.addText(Translator.map("For More Information"));
			dialogBox.addAcceptCancelButtons('OK');
			dialogBox.showOnStage(stage);
			MBlock.app.track("/OxfordAi/setting/open");
		}
		// -----------------------------
		// Project Reverting
		//------------------------------
	
		protected var originalProj:ByteArray;
		private var revertUndo:ByteArray;
	
		public function saveForRevert(projData:ByteArray, isNew:Boolean, onServer:Boolean = false):void {
			originalProj = projData;
			revertUndo = null;
		}
	
		protected function doRevert():void {
			runtime.installProjectFromData(originalProj, false);
		}
		
		private function preDoRevert():void {
			revertUndo = new ProjectIO(MBlock.app).encodeProjectAsZipFile(stagePane);
			doRevert();
		}
	
		public function revertToOriginalProject():void {
			if (!originalProj) return;
			DialogBox.confirm('Throw away all changes since opening this project?', stage, preDoRevert);
		}
	
		public function undoRevert():void {
			if (!revertUndo) return;
			runtime.installProjectFromData(revertUndo, false);
			revertUndo = null;
		}
	
		public function canRevert():Boolean { return originalProj != null }
		public function canUndoRevert():Boolean { return revertUndo != null }
		private function clearRevertUndo():void { revertUndo = null }
	
		public function addNewSprite(spr:ScratchSprite, showImages:Boolean = false, atMouse:Boolean = false):void {
			var c:ScratchCostume, byteCount:int;
			for each (c in spr.costumes) byteCount + c.baseLayerData.length;
//			if (!okayToAdd(byteCount)) return; // not enough room
			spr.objName = stagePane.unusedSpriteName(spr.objName);
			spr.indexInLibrary = 1000000; // add at end of library
			spr.setScratchXY(int(50 * Math.random() - 25), int(50 * Math.random() - 25));
			if (atMouse) spr.setScratchXY(stagePane.scratchMouseX(), stagePane.scratchMouseY());
			stagePane.addChild(spr);
			selectSprite(spr);
			setTab(showImages ? 'images' : 'scripts');
			if(stagePane.numChildren>4)
				setSaveNeeded(true);
			
			libraryPart.refresh();
			for each (c in spr.costumes) {
				if (ScratchCostume.isSVGData(c.baseLayerData)) c.setSVGData(c.baseLayerData, false);
			}
		}
		public function addSound(snd:ScratchSound, targetObj:ScratchObj = null):void {
//			if (snd.soundData && !okayToAdd(snd.soundData.length)) return; // not enough room
			if (!targetObj) targetObj = viewedObj();
			snd.soundName = targetObj.unusedSoundName(snd.soundName);
			targetObj.sounds.push(snd);
			setSaveNeeded(true);
			if (targetObj == viewedObj()) {
				soundsPart.selectSound(snd);
				setTab('sounds');
			}
		}
	
		public function addCostume(c:ScratchCostume, targetObj:ScratchObj = null):void {
			if (!c.baseLayerData) c.prepareToSave();
//			if (!okayToAdd(c.baseLayerData.length)) return; // not enough room
			if (!targetObj) targetObj = viewedObj();
			c.costumeName = targetObj.unusedCostumeName(c.costumeName);
			targetObj.costumes.push(c);
			targetObj.showCostumeNamed(c.costumeName);
			setSaveNeeded(true);
			if (targetObj == viewedObj()) setTab('images');
		}
	
		// -----------------------------
		// Flash sprite (helps connect a sprite on thestage with a sprite library entry)
		//------------------------------
	
		public function flashSprite(spr:ScratchSprite):void {
			new FlashSprite().flash(spr);
		}
	
		// -----------------------------
		// Download Progress
		//------------------------------
	
		public function addLoadProgressBox(title:String):void {
			removeLoadProgressBox();
			lp = new LoadProgress();
			lp.setTitle(title);
			stage.addChild(lp);
			fixLoadProgressLayout();
		}
	
		public function removeLoadProgressBox():void {
			if (lp && lp.parent) lp.parent.removeChild(lp);
			lp = null;
		}
	
		private function fixLoadProgressLayout():void {
			if (!lp) return;
			var p:Point = stagePane.localToGlobal(new Point(0, 0));
			lp.scaleX = stagePane.scaleX;
			lp.scaleY = stagePane.scaleY;
			lp.x = int(p.x + ((stagePane.width - lp.width) / 2));
			lp.y = int(p.y + ((stagePane.height - lp.height) / 2));
		}
	
		// -----------------------------
		// Camera Dialog
		//------------------------------
	
		public function openCameraDialog(savePhoto:Function):void {
			closeCameraDialog();
			cameraDialog = new CameraDialog(savePhoto);
			cameraDialog.fixLayout();
			cameraDialog.x = (stage.stageWidth - cameraDialog.width) / 2;
			cameraDialog.y = (stage.stageHeight - cameraDialog.height) / 2;;
			addChild(cameraDialog);
		}
	
		public function closeCameraDialog():void {
			if (cameraDialog) {
				cameraDialog.closeDialog();
				cameraDialog = null;
			}
		}
	
		// Misc.
		public function createMediaInfo(obj:*, owningObj:ScratchObj = null):MediaInfo {
			return new MediaInfo(obj, owningObj);
		}
	}
}
