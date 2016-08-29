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

// ProjectIO.as
// John Maloney, September 2010
//
// Support for project saving/loading, either to the local file system or a server.
// Three types of projects are supported: old Scratch projects (.sb), new Scratch
// projects stored as a JSON project file and a collection of media files packed
// in a single ZIP file, and new Scratch projects stored on a server as a collection
// of separate elements.

package util {
import flash.display.BitmapData;
import flash.display.Loader;
import flash.events.Event;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.utils.ByteArray;
import flash.utils.Dictionary;
import flash.utils.setTimeout;

import extensions.DeviceManager;

import scratch.ScratchCostume;
import scratch.ScratchObj;
import scratch.ScratchSound;
import scratch.ScratchSprite;
import scratch.ScratchStage;

import sound.WAVFile;
import sound.mp3.MP3Loader;

import svgutils.SVGElement;
import svgutils.SVGImporter;

import translation.Translator;

import uiwidgets.DialogBox;

public class ProjectIO {

	protected var app:MBlock;
	protected var images:Array = [];
	protected var sounds:Array = [];

	public function ProjectIO(app:MBlock):void {
		this.app = app;
	}

	public static function strings():Array {
		return [];
	}

	//----------------------------
	// Encode a project or sprite as a ByteArray (a 'one-file' project)
	//----------------------------

	public function encodeProjectAsZipFile(proj:ScratchStage):ByteArray {
		// Encode a project into a ByteArray. The format is a ZIP file containing
		// the JSON project data and all images and sounds as files.
		delete proj.info.penTrails; // remove the penTrails bitmap saved in some old projects' info
		proj.savePenLayer();
		proj.updateInfo();
		recordImagesAndSounds(proj.allObjects(), false, proj);
		var zip:ZipIO = new ZipIO();
		zip.startWrite();
		addJSONData('project.json', proj, zip);
		addImagesAndSounds(zip);
		proj.clearPenLayer();
		return zip.endWrite();
	}

	public function encodeSpriteAsZipFile(spr:ScratchSprite):ByteArray {
		// Encode a sprite into a ByteArray. The format is a ZIP file containing
		// the JSON sprite data and all images and sounds as files.
		recordImagesAndSounds([spr], false);
		var zip:ZipIO = new ZipIO();
		zip.startWrite();
		addJSONData('sprite.json', spr, zip);
		addImagesAndSounds(zip);
		return zip.endWrite();
	}

	private function addJSONData(fileName:String, obj:*, zip:ZipIO):void {
		var jsonData:ByteArray = new ByteArray();
		jsonData.writeUTFBytes(util.JSON.stringify(obj));
		zip.write(fileName, jsonData, true);
	}

	private function addImagesAndSounds(zip:ZipIO):void {
		var i:int, ext:String;
		for (i = 0; i < images.length; i++) {
			var imgData:ByteArray = images[i][1];
			ext = ScratchCostume.fileExtension(imgData);
			zip.write(i + ext, imgData);
		}
		for (i = 0; i < sounds.length; i++) {
			var sndData:ByteArray = sounds[i][1];
			ext = ScratchSound.isWAV(sndData) ? '.wav' : '.mp3';
			zip.write(i + ext, sndData);
		}
	}

	//----------------------------
	// Decode a project or sprite from a ByteArray containing ZIP data
	//----------------------------

	public function decodeProjectFromZipFile(zipData:ByteArray):ScratchStage {
		return decodeFromZipFile(zipData) as ScratchStage;
	}

	public function decodeSpriteFromZipFile(zipData:ByteArray, whenDone:Function):void {
		function imagesDecoded():void {
			spr.showCostume(spr.currentCostumeIndex);
			whenDone(spr);
		}
		var spr:ScratchSprite = decodeFromZipFile(zipData) as ScratchSprite;
		if (spr) decodeAllImages([spr], imagesDecoded);
	}

	private function decodeFromZipFile(zipData:ByteArray):ScratchObj {
		var jsonData:String;
		images = [];
		sounds = [];
		try {
			var files:Array = new ZipIO().read(zipData);
		} catch (e:*) {
			app.log('Bad zip file; attempting to recover');
			try {
				files = new ZipIO().recover(zipData);
			} catch (e:*) {
				return null; // couldn't recover
			}
		}
		for each (var f:Array in files) {
			var fName:String = f[0];
			if (fName.indexOf('__MACOSX') > -1) continue; // skip MacOS meta info in zip file
			var fIndex:int = int(integerName(fName));
			var contents:ByteArray = f[1];
			if (fName.slice(-4) == '.gif') images[fIndex] = contents;
			if (fName.slice(-4) == '.jpg') images[fIndex] = contents;
			if (fName.slice(-4) == '.png') images[fIndex] = contents;
			if (fName.slice(-4) == '.svg') images[fIndex] = contents;
			if (fName.slice(-4) == '.wav') sounds[fIndex] = contents;
			if (fName.slice(-4) == '.mp3') sounds[fIndex] = contents;
			if (fName.slice(-5) == '.json') jsonData = contents.readUTFBytes(contents.length);
		}
		if (jsonData == null) return null;
		jsonData = fixForNewExtension(jsonData);
		if(jsonData.indexOf("PicoBoard")>-1){
			DeviceManager.sharedManager().onSelectBoard("picoboard_unknown");
		}else if(jsonData.indexOf("Makeblock")>-1){
			if(!MBlock.app.extensionManager.checkExtensionSelected("Makeblock")){
				MBlock.app.extensionManager.onSelectExtension("Makeblock");
			}
		}else if(jsonData.indexOf("Arduino.")>-1){
			if(!MBlock.app.extensionManager.checkExtensionSelected("Arduino")){
				MBlock.app.extensionManager.onSelectExtension("Arduino");
			}
		}
		var jsonObj:Object = util.JSON.parse(jsonData);
		//先处理兼容性问题
		fixManager(jsonObj);
		if(jsonObj['info']){
			if(jsonObj['info']['boardVersion']){
				DeviceManager.sharedManager().onSelectBoard(jsonObj['info']['boardVersion']);
			}else{
				DeviceManager.sharedManager().onSelectBoard("mbot_uno");
			}
		}
		if (jsonObj['children']) { // project JSON
			
			var proj:ScratchStage = new ScratchStage();
			proj.readJSON(jsonObj);
			if (proj.penLayerID >= 0) proj.penLayerPNG = images[proj.penLayerID]
			else if (proj.penLayerMD5) proj.penLayerPNG = images[0];
			installImagesAndSounds(proj.allObjects());
			return proj;
		}
		if (jsonObj['direction'] != null) { // sprite JSON
			var sprite:ScratchSprite = new ScratchSprite();
			sprite.readJSON(jsonObj);
			sprite.instantiateFromJSON(app.stagePane)
			installImagesAndSounds([sprite]);
			return sprite;
		}
		return null;
	}
	private function fixManager(obj:Object):void
	{
		try
		{
			var board:String = obj.info.boardVersion;
			trace("board="+board);
		}
		catch(err:Error)
		{
			board = "";
		}
		
		var childs:Array = obj["children"];
		if(!childs)return;
		for each(var sc:Object in childs)
		{
			var script:Array = sc["scripts"];
			if(!script)
			{
				continue;
			}
			for(var i:int=0;i<script.length;i++)
			{
				var blocks:Array = script[i][2];
				if(!blocks)continue;
				/*'??'指的是原来什么值就什么值，不作对比和修改
				* +表示插入+号后面的项，比如arr1=[1,2,3],arr2=[4,"+",8]，转换后得 arr1=[4,8,2,3];
				*- 表示要删除该项，比如arr1=[1,2,3],arr2=["-","??","??"]，转换后得 arr1=[2,3];
				* T 表示交换位置，比如第1个和第2个参数交换位置，arr1=[1,2,3],arr2=["T1","T1","??"],转换后arr1=[2,1,3];这里T是成对出现的，多对要交换用T加序号来实现
				* "Port1|Port2|Port3|Port4" 竖线隔开表示满足其中任意一个都算匹配上了。
				* "1:led right|2:led left" 替代的项，1:led right 表示如果值为1，则替换成led right
				*/
				
				if(board=="mbot_uno")
				{
					//fix mBot 
					fixCategoryRecursion(blocks,["mBot.runLed", "Port1|Port2|Port3|Port4", "??", "??", "??", "??"],["mBot.runLedExternal"]);
					fixCategoryRecursion(blocks,["mBot.runLed", "led on board", "??", "??", "??", "??"],["mBot.runLed","-","1:led right|2:led left"]);
				}
				else if(board=="me/auriga_mega2560")
				{
					//fix auriga
					//兼容V3.3.2 auriga和megapi的getEncoderValue，将改语句块拆分成了速度和位置两块，所以要兼容旧版本，旧版本转为速度快（旧版本只实现了读取速度功能）
					fixCategoryRecursion(blocks,["Auriga.getEncoderValue", "??", "position"],["Auriga.getEncoderPosValue","??","-"]);
					fixCategoryRecursion(blocks,["Auriga.getEncoderValue", "??", "speed"],["Auriga.getEncoderSpeedValue","??","-"]);
					/*由于Auriga和Megapi同一语句块参数不一样，所以切换板的时候有问题，因此这里修改了Auriga的语句块名字，并且兼容，调换角度与速度的位置*/
					fixCategoryRecursion(blocks,["Auriga.runEncoderMotor", "??", "??", "??", "??"],["Auriga.runEncoderMotorRpm","??","??","T1","T1"]);
				}
				else if(board=="me/mega_pi_mega2560")
				{
					fixCategoryRecursion(blocks,["MegaPi.getEncoderValue", "??", "position"],["MegaPi.getEncoderPosValue","??","-"]);
					fixCategoryRecursion(blocks,["MegaPi.getEncoderValue", "??", "speed"],["MegaPi.getEncoderSpeedValue","??","-"]);
				}
				
			}
			
		}
	}
	
	/**
	 * 功能：在blocks中查找与originalArr匹配的项，然后替换成targetArr。用在兼容旧版本的地方
	 * @param blocks 数据对象
	 * @param originalArr 要匹配的项
	 * @param targetArr  要替换的项
	 * 
	 */	
	private function fixCategoryRecursion(blocks:Array,originalArr:Array,targetArr:Array):void
	{
			
		if(blocks.length==originalArr.length)
		{
			for(var j:int=0;j<originalArr.length;j++)
			{
				if(originalArr[j]=="??" || originalArr[j]==blocks[j] || originalArr[j].indexOf(blocks[j])>=0)
				{
					continue;
				}
				else
				{
					j--;
					break;
				}
			}
			//全等，准备替换
			if(j==originalArr.length)
			{
				var tmpArr:Array = targetArr.slice();
				for(var k:int=0;k<tmpArr.length;k++)
				{
					if(tmpArr[k] is String && tmpArr[k].charAt(0)=="T")
					{
						var key:String = tmpArr[k];
						var ind1:int = k;
						var ind2:int = tmpArr.lastIndexOf(key);
						if(ind2>=0)
						{
							var tmpStr:String = blocks[ind1];
							blocks[ind1] = blocks[ind2];
							blocks[ind2] = tmpStr;
						}
					}
					else if(tmpArr[k]=="+")
					{
						tmpArr.splice(k,1);
						blocks.splice(k,0,tmpArr[k]);
					}
					else if(tmpArr[k]=="-")
					{
						blocks.splice(k,1);
						tmpArr.splice(k,1);
						k--;
					}
					else if(tmpArr[k]!="??")
					{
						if(tmpArr[k].indexOf("|")>=0)
						{
							var valueArr:Array = tmpArr[k].split("|");
							for each(var value:String in valueArr)
							{
								var arr:Array = value.split(":");
								if(blocks[k]==arr[0])
								{
									blocks[k] = arr[1];
									break;
								}
							}
						}
						else
						{
							blocks[k] = tmpArr[k];
						}
						
					}
				}
			}
			else
			{
				for(var t:int=0;t<blocks.length;t++)
				{
					if(blocks[t] is Array)
					{
						fixCategoryRecursion(blocks[t],originalArr,targetArr);
					}
				}
			}
		}
		else
		{
			for(t=0;t<blocks.length;t++)
			{
				if(blocks[t] is Array)
				{
					fixCategoryRecursion(blocks[t],originalArr,targetArr);
				}
			}
		}
			
		
	}
	
	private var fixList:Array = [
		["arduino\\/main","runArduino"],
		["Robots.","Makeblock."],
		["MBot.","mBot."],
		["get\\/timer","getTimer"],
		["run\\/timer","resetTimer"],
		["get\\/digital","getDigital"],
		["get\\/analog","getAnalog"],
		["run\\/servo_pin","runServo"],
		["run\\/tone","runTone"],
		["run\\/digital","runDigital"],
		["run\\/pwm","runPwm"],
		["run\\/motor","runMotor"],
		["run\\/servo","runServo"],
		["run\\/steppermotor","runStepperMotor"],
		["run\\/encodermotor","runEncoderMotor"],
		["run\\/sevseg","runSevseg"],
		["run\\/led","runLed"],
		["run\\/lightsensor","runLightSensor"],
		["run\\/shutter","runShutter"],
		["get\\/button_inner","getButtonOnBoard"],
		["get\\/ultrasonic","getUltrasonic"],
		["get\\/linefollower","getLinefollower"],
		["get\\/lightsensor","getLightSensor"],
		["get\\/joystick","getJoystick"],
		["get\\/potentiometer","getPotentiometer"],
		["get\\/soundsensor","getSoundSensor"],
		["get\\/infrared","getInfrared"],
		["get\\/limitswitch","getLimitswitch"],
		["get\\/pirmotion","getPirmotion"],
		["get\\/temperature","getTemperature"],
		["get\\/gyro","getGyro"],
		["run\\/buzzer","runBuzzer"],
		["stop\\/buzzer","stopBuzzer"],
		["get\\/irremote","getIrRemote"],
		["run\\/ir","runIR"],
		["get\\/ir","getIR"],
		['["mBot.getButtonOnBoard"]', '["mBot.getButtonOnBoard", "pressed"]'],
		["mBot.get\\/analog","mBot.getLightOnBoard"],
		["mBot.getAnalog","mBot.getLightOnBoard"],
		['["mBot.getLightOnBoard"]','["mBot.getLightSensor", "light sensor on board"]'],
		['Communication.serial\\/received','Communication.whenReceived'],
		['Communication.serial\\/read\\/available','Communication.isAvailable'],
		['Communication.serial\\/read\\/equal','Communication.isEqual'],
		['Communication.serial\\/read\\/line','Communication.readLine'],
		['Communication.serial\\/write\\/line','Communication.writeLine'],
		['Communication.serial\\/write\\/command','Communication.writeCommand'],
		['Communication.serial\\/read\\/command','Communication.readCommand'],
		['Communication.serial\\/clear','Communication.clearBuffer'],
		['"Quater"','"Quarter"']
		/*,
		['["mBot.runLed", "all",','["mBot.runLed", "led on board","all",']*/
	];
	private function fixForNewExtension(json:String):String{
		trace(json);
		for(var i:uint=0;i<fixList.length;i++){
			json = json.split(fixList[i][0]).join(fixList[i][1]);
		}
		trace(json);
		return json.split("arduino\\/main").join("runArduino");
	}
	private function integerName(s:String):String {
		// Return the substring of digits preceding the last '.' in the given string.
		// For example integerName('123.jpg') -> '123'.
		const digits:String = '1234567890';
		var end:int = s.lastIndexOf('.');
		if (end < 0) end = s.length;
		var start:int = end - 1;
		if (start < 0) return s;
		while ((start >= 0) && (digits.indexOf(s.charAt(start)) >= 0)) start--;
		return s.slice(start + 1, end);
	}

	private function installImagesAndSounds(objList:Array):void {
		// Install the images and sounds for the given list of ScratchObj objects.
		for each (var obj:ScratchObj in objList) {
			for each (var c:ScratchCostume in obj.costumes) {
				if (images[c.baseLayerID] != undefined) c.baseLayerData = images[c.baseLayerID];
				if (images[c.textLayerID] != undefined) c.textLayerData = images[c.textLayerID];
			}
			for each (var snd:ScratchSound in obj.sounds) {
				var sndData:* = sounds[snd.soundID];
				if (sndData) {
					snd.soundData = sndData;
					snd.convertMP3IfNeeded();
				}
			}
		}
	}

	public function decodeAllImages(objList:Array, whenDone:Function):void {
		// Load all images in all costumes from their image data, then call whenDone.
		function imageDecoded():void {
			for each (var o:* in imageDict) {
				if (o == 'loading...') return; // not yet finished loading
			}
			allImagesLoaded();
		}
		function allImagesLoaded():void {
			for each (c in allCostumes) {
				if ((c.baseLayerData != null) && (c.baseLayerBitmap == null)) {
					var img:* = imageDict[c.baseLayerData];
					if (img is BitmapData) c.baseLayerBitmap = img;
					if (img is SVGElement) c.setSVGRoot(img, false);
				}
				if ((c.textLayerData != null) && (c.textLayerBitmap == null)) c.textLayerBitmap = imageDict[c.textLayerData];
			}
			for each (c in allCostumes) c.generateOrFindComposite(allCostumes);
			whenDone();
		}

		var c:ScratchCostume;
		var allCostumes:Array = [];
		for each (var o:ScratchObj in objList) {
			for each (c in o.costumes) allCostumes.push(c);
		}
		var imageDict:Dictionary = new Dictionary(); // maps image data to BitmapData
		for each (c in allCostumes) {
			if ((c.baseLayerData != null) && (c.baseLayerBitmap == null)) {
				if (ScratchCostume.isSVGData(c.baseLayerData)) decodeSVG(c.baseLayerData, imageDict, imageDecoded);
				else decodeImage(c.baseLayerData, imageDict, imageDecoded);
			}
			if ((c.textLayerData != null) && (c.textLayerBitmap == null)) decodeImage(c.textLayerData, imageDict, imageDecoded);
		}
		imageDecoded(); // handles case when there were no images to load
	}

	private function decodeImage(imageData:ByteArray, imageDict:Dictionary, doneFunction:Function):void {
		function loadDone(e:Event):void {
			loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, loadDone);
			imageDict[imageData] = e.target.content.bitmapData;
			doneFunction();
		}
		if (imageDict[imageData] != null) return; // already loading or loaded
		imageDict[imageData] = 'loading...';
		var loader:Loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadDone);
		loader.loadBytes(imageData);
	}

	private function decodeSVG(svgData:ByteArray, imageDict:Dictionary, doneFunction:Function):void {
		function loadDone(svgRoot:SVGElement):void {
			imageDict[svgData] = svgRoot;
			doneFunction();
		}
		if (imageDict[svgData] != null) return; // already loading or loaded
		var importer:SVGImporter = new SVGImporter(XML(svgData));
		if (importer.hasUnloadedImages()) {
			imageDict[svgData] = 'loading...';
			importer.loadAllImages(loadDone);
		} else {
			imageDict[svgData] = importer.root;
		}
	}

	public function downloadProjectAssets(projectData:ByteArray):void {
		function assetReceived(md5:String, data:ByteArray):void {
			assetDict[md5] = data;
			assetCount++;
			if (!data) {
				app.log('missing asset: ' + md5);
			}
			if (app.lp) {
				app.lp.setProgress(assetCount / assetsToFetch.length);
				app.lp.setInfo(
						assetCount + ' ' +
								Translator.map('of') + ' ' + assetsToFetch.length + ' ' +
								Translator.map('assets loaded'));
			}
			if (assetCount == assetsToFetch.length) {
				installAssets(proj.allObjects(), assetDict);
				app.runtime.decodeImagesAndInstall(proj);
			}
		}
		projectData.position = 0;
		var projObject:Object = util.JSON.parse(projectData.readUTFBytes(projectData.length));
		var proj:ScratchStage = new ScratchStage();
		proj.readJSON(projObject);
		var assetsToFetch:Array = collectAssetsToFetch(proj.allObjects());
		var assetDict:Object = new Object();
		var assetCount:int = 0;
		for each (var md5:String in assetsToFetch) fetchAsset(md5, assetReceived);
	}

	//----------------------------
	// Fetch a costume or sound from the server
	//----------------------------

	public function fetchImage(id:String, costumeName:String, whenDone:Function):URLLoader {
		// Fetch an image asset from the server and call whenDone with the resulting ScratchCostume.
		var c:ScratchCostume;
		function gotCostumeData(data:ByteArray):void {
			if (!data) {
				app.log('Image not found on server: ' + id);
				return;
			}
			if (ScratchCostume.isSVGData(data)) {
				c = new ScratchCostume(costumeName, data);
				c.baseLayerMD5 = id;
				whenDone(c);
			} else {
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded);
				loader.loadBytes(data);
			}
		}
		function imageLoaded(e:Event):void {
			c = new ScratchCostume(costumeName, e.target.content.bitmapData);
			c.baseLayerMD5 = id;
			whenDone(c);
		}
		gotCostumeData(app.server.getAsset(id));
		return null;
	}

	public function fetchSound(id:String, sndName:String, whenDone:Function):void {
		// Fetch a sound asset from the server and call whenDone with the resulting ScratchSound.
		var sndData:ByteArray = app.server.getAsset(id);
		if (!sndData) {
			app.log('Sound not found on server: ' + id);
			return;
		}
		var snd:ScratchSound;
		try {
			snd = new ScratchSound(sndName, sndData); // try reading data as WAV file
		} catch (e:*) { }
		if (snd && (snd.sampleCount > 0)) { // WAV data
			snd.md5 = id;
			whenDone(snd);
		} else { // try to read data as an MP3 file
			MP3Loader.convertToScratchSound(sndName, sndData, whenDone);
		}
		
	}

	//----------------------------
	// Download a sprite from the server
	//----------------------------

	public function fetchSprite(md5AndExt:String, whenDone:Function):void {
		// Fetch a sprite with the md5 hash.
		function assetsReceived(assetDict:Object):void {
			installAssets([spr], assetDict);
			decodeAllImages([spr], done);
		}
		function done():void {
			spr.showCostume(spr.currentCostumeIndex);
			spr.setDirection(spr.direction);
			whenDone(spr);
		}
		var spr:ScratchSprite = new ScratchSprite();
		var data:ByteArray = app.server.getAsset(md5AndExt);
		if (!data) return;
		spr.readJSON(util.JSON.parse(data.readUTFBytes(data.length)));
		spr.instantiateFromJSON(app.stagePane);
		fetchSpriteAssets([spr], assetsReceived);
	}

	private function fetchSpriteAssets(objList:Array, whenDone:Function):void {
		// Download all media for the given list of ScratchObj objects.
		function assetReceived(md5:String, data:ByteArray):void {
			if (!data) {
				app.log('missing sprite asset: ' + md5);
			}
			assetDict[md5] = data;
			assetCount++;
			if (assetCount == assetsToFetch.length) whenDone(assetDict);
		}
		var assetDict:Object = new Object();
		var assetCount:int = 0;
		var assetsToFetch:Array = collectAssetsToFetch(objList);
		for each (var md5:String in assetsToFetch) fetchAsset(md5, assetReceived);
	}

	private function collectAssetsToFetch(objList:Array):Array {
		// Return list of MD5's for all project assets.
		var list:Array = new Array();
		for each (var obj:ScratchObj in objList) {
			for each (var c:ScratchCostume in obj.costumes) {
				if (list.indexOf(c.baseLayerMD5) < 0) list.push(c.baseLayerMD5);
				if (c.textLayerMD5) {
					if (list.indexOf(c.textLayerMD5) < 0) list.push(c.textLayerMD5);
				}
			}
			for each (var snd:ScratchSound in obj.sounds) {
				if (list.indexOf(snd.md5) < 0) list.push(snd.md5);
			}
		}
		return list;
	}

	private function installAssets(objList:Array, assetDict:Object):void {
		var data:ByteArray;
		for each (var obj:ScratchObj in objList) {
			for each (var c:ScratchCostume in obj.costumes) {
				data = assetDict[c.baseLayerMD5];
				if (data) c.baseLayerData = data;
				else c.baseLayerData = ScratchCostume.emptySVG(); // missing asset data; use empty costume
				if (c.textLayerMD5) c.textLayerData = assetDict[c.textLayerMD5];
			}
			for each (var snd:ScratchSound in obj.sounds) {
				data = assetDict[snd.md5];
				if (data) {
					snd.soundData = data;
					snd.convertMP3IfNeeded();
				} else {
					snd.soundData = WAVFile.empty();
				}
			}
		}
	}

	public function fetchAsset(md5:String, whenDone:Function):void {
		var data:ByteArray = app.server.getAsset(md5);
		whenDone(md5, data);
	}

	//----------------------------
	// Record unique images and sounds
	//----------------------------

	protected function recordImagesAndSounds(objList:Array, uploading:Boolean, proj:ScratchStage = null):void {
		var recordedAssets:Object = {};
		images = [];
		sounds = [];

		app.clearCachedBitmaps();
		if (!uploading && proj) proj.penLayerID = recordImage(proj.penLayerPNG, proj.penLayerMD5, recordedAssets, uploading);

		for each (var obj:ScratchObj in objList) {
			for each (var c:ScratchCostume in obj.costumes) {
				c.prepareToSave(); // encodes image and computes md5 if necessary
				c.baseLayerID = recordImage(c.baseLayerData, c.baseLayerMD5, recordedAssets, uploading);
				if (c.textLayerBitmap) {
					c.textLayerID = recordImage(c.textLayerData, c.textLayerMD5, recordedAssets, uploading);
				}
			}
			for each (var snd:ScratchSound in obj.sounds) {
				snd.prepareToSave(); // compute md5 if necessary
				snd.soundID = recordSound(snd, snd.md5, recordedAssets, uploading);
			}
		}
	}

	public function convertSqueakSounds(scratchObj:ScratchObj, done:Function):void {
		// Pre-convert any Squeak sounds (asynch, with a progress bar) before saving a project.
		// Note: If this is not called before recordImagesAndSounds(), sounds will
		// be converted synchronously, but there may be a long delay without any feedback.
		function convertASound():void {
			if (i < soundsToConvert.length) {
				var sndToConvert:ScratchSound = soundsToConvert[i++] as ScratchSound;
				sndToConvert.prepareToSave();
				app.lp.setProgress(i / soundsToConvert.length);
				app.lp.setInfo(sndToConvert.soundName);
				setTimeout(convertASound, 50);
			} else {
				app.removeLoadProgressBox();
				// Note: Must get user click in order to proceed with saving...
				DialogBox.notify('', 'Sounds converted', app.stage, false, soundsConverted);
			}
		}
		function soundsConverted(ignore:*):void { done(this) }
		var soundsToConvert:Array = [];
		for each (var obj:ScratchObj in scratchObj.allObjects()) {
			for each (var snd:ScratchSound in obj.sounds) {
				if ('squeak' == snd.format) soundsToConvert.push(snd);
			}
		}
		var i:int;
		if (soundsToConvert.length > 0) {
			app.addLoadProgressBox('Converting sounds...');
			setTimeout(convertASound, 50);
		} else done(this);
	}

	private function recordImage(img:*, md5:String, recordedAssets:Object, uploading:Boolean):int {
		var id:int = recordedAssetID(md5, recordedAssets, uploading);
		if (id > -2) return id; // image was already added
		images.push([md5, img]);
		id = images.length - 1;
		recordedAssets[md5] = id;
		return id;
	}

	protected function recordedAssetID(md5:String, recordedAssets:Object, uploading:Boolean):int {
		var id:* = recordedAssets[md5];
		return id != undefined ? id : -2;
	}

	private function recordSound(snd:ScratchSound, md5:String, recordedAssets:Object, uploading:Boolean):int {
		var id:int = recordedAssetID(md5, recordedAssets, uploading);
		if (id > -2) return id; // image was already added
		sounds.push([md5, snd.soundData]);
		id = sounds.length - 1;
		recordedAssets[md5] = id;
		return id;
	}
}}
