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

// ServerOffline.as
// John Maloney, June 2013
//
// Interface to the Scratch website API's for Offline Editor.
//
// Note: All operations call the whenDone function with the result
// if the operation succeeded or null if it failed.

package util {
import flash.display.BitmapData;
import flash.display.Loader;
import flash.events.Event;
import flash.filesystem.File;
import flash.geom.Matrix;
import flash.net.URLLoader;
import flash.utils.ByteArray;

import cc.makeblock.util.FileUtil;

public class Server {
	// -----------------------------
	// Asset API
	//------------------------------
	private function fetchAsset(url:String):ByteArray
	{
		// Make a GET or POST request to the given URL (do a POST if the data is not null).
		// The whenDone() function is called when the request is done, either with the
		// data returned by the server or with a null argument if the request failed.
/*
		function completeHandler(e:Event):void {
			loader.removeEventListener(Event.COMPLETE, completeHandler);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			whenDone(loader.data);
		}
		function errorHandler(err:ErrorEvent):void {
			loader.removeEventListener(Event.COMPLETE, completeHandler);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			MBlock.app.logMessage('Failed server request for '+url);
			whenDone(null);
		}

		var loader:URLLoader = new URLLoader();
		loader.dataFormat = URLLoaderDataFormat.BINARY;
		loader.addEventListener(Event.COMPLETE, completeHandler);
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
		loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
		var request:URLRequest = new URLRequest(url);
	*/	
		
		var file:File;
		if(url.indexOf("://") > -1||url.indexOf("app-storage:/") > -1){
			file = new File(url);
		}else{
			file = File.applicationDirectory.resolvePath(url);
		}
		if(file.exists){
			return FileUtil.ReadBytes(file);
		}
		return null;
		/*
		try {
			loader.load(request);
		} catch(e:*){
			// Local sandbox exception?
			trace(e);
			whenDone(null);
		}
		return loader;
		*/
	}

	public function getAsset(md5:String):ByteArray
	{
//		if (BackpackPart.localAssets[md5] && BackpackPart.localAssets[md5].length > 0) {
//			whenDone(BackpackPart.localAssets[md5]);
//			return null;
//		}
		return fetchAsset('media/' + md5);
	}

	public function getMediaLibrary():String
	{
		return fetchAsset('media/mediaLibrary.json').toString();
	}

	public function getThumbnail(md5:String, w:int, h:int, whenDone:Function):URLLoader {
		function imageLoaded(e:Event):void {
			whenDone(makeThumbnail(e.target.content.bitmapData));
		}
		var ext:String = md5.slice(-3);
		if (['gif', 'png', 'jpg'].indexOf(ext) > -1) {
			var data:ByteArray = getAsset(md5);
			if (data) {
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded);
				try { loader.loadBytes(data) } catch (e:*) {}
			}
		}
		return null;
	}

	private function makeThumbnail(bm:BitmapData):BitmapData {
		const tnWidth:int = 120;
		const tnHeight:int = 90;
		var result:BitmapData = new BitmapData(tnWidth, tnHeight, true, 0);
		if ((bm.width == 0) || (bm.height == 0)) return result;
		var scale:Number = Math.min(tnWidth/ bm.width, tnHeight / bm.height);
		var m:Matrix = new Matrix();
		m.scale(scale, scale);
		m.translate((tnWidth - (scale * bm.width)) / 2, (tnHeight - (scale * bm.height)) / 2);
		result.draw(bm, m);
		return result;
	}

	// -----------------------------
	// Translation Support
	//------------------------------

	public function getLanguageList():String
	{
		var file:File = ApplicationManager.sharedManager().documents.resolvePath("mBlock/locale");
		var bytes:ByteArray;
		if(file.exists){
			bytes = fetchAsset(file.url+'/lang_list.txt');
		}else{
			bytes = fetchAsset('locale/lang_list.txt');
		}
		return bytes.toString();
	}

	public function getPOFile(lang:String):ByteArray
	{
		var file:File = ApplicationManager.sharedManager().documents.resolvePath("mBlock/locale");
		var bytes:ByteArray;
		if(file.exists){
			bytes = fetchAsset(file.url+"/"+  lang +'.po');
		}else{
			bytes = fetchAsset('locale/' + lang + '.po');
		}
		return bytes;
	}

	public function getSelectedLang(whenDone:Function):void {
		// Get the language setting.
		if (SharedObjectManager.sharedManager().available("lang")){
			whenDone(SharedObjectManager.sharedManager().getObject("lang"));
		}
	}

	public function setSelectedLang(lang:String):void {
		// Record the language setting.
		if (!Boolean(lang)){
			lang = 'en';
		}
		SharedObjectManager.sharedManager().setObject("lang", lang);
	}
}}
