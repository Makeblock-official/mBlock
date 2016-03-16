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
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.geom.Matrix;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.utils.ByteArray;

import cc.makeblock.util.CsvReader;
import cc.makeblock.util.Excel;
import cc.makeblock.util.FileUtil;


public class Server {
	// -----------------------------
	// Asset API
	//------------------------------
	static public function fetchAsset(url:String, whenDone:Function):URLLoader
	{
		// Make a GET or POST request to the given URL (do a POST if the data is not null).
		// The whenDone() function is called when the request is done, either with the
		// data returned by the server or with a null argument if the request failed.
//*
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
		loader.load(request);
		return loader;
	}

	public function getAsset(md5:String, whenDone:Function):URLLoader
	{
		return fetchAsset("media/" + md5, whenDone);
	}

	public function getMediaLibrary(whenDone:Function):URLLoader
	{
		return fetchAsset('media/mediaLibrary.json', whenDone);
	}

	public function getThumbnail(md5:String, w:int, h:int, whenDone:Function):URLLoader {
		function imageLoaded(e:Event):void {
			whenDone(makeThumbnail(e.target.content.bitmapData));
		}
		var ext:String = md5.slice(-3);
		if (['gif', 'png', 'jpg'].indexOf(ext) > -1) {
			getAsset(md5, function(data:ByteArray):void{
				if (data) {
					var loader:Loader = new Loader();
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded);
					try { loader.loadBytes(data) } catch (e:*) {}
				}
			});
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

	public function getLanguageList():Array
	{
		var obj:Object = getLangObj();
		var result:Array = []
		for(var key:String in obj){
			result.push([key, obj[key]["Language-Name"]]);
		}
		result.sortOn("0", Array.DESCENDING);
		result.unshift(['en', 'English']);
		return result;
	}

	public function getPOFile(lang:String):Object
	{
		var obj:Object = getLangObj();
		return obj[lang];
		/*
		var file:File = ApplicationManager.sharedManager().documents.resolvePath("mBlock/locale");
		var bytes:ByteArray;
		if(file.exists){
			bytes = fetchAsset(file.url+"/"+  lang +'.po');
		}else{
			bytes = fetchAsset('locale/' + lang + '.po');
		}
		return bytes;
		*/
	}
	
	[Embed(source="/locale/locale.xlsx", mimeType="application/octet-stream")]
	static private const LANG_CLS:Class;
	
	static private function getLangObj():Object
	{
		var bytes:ByteArray = new LANG_CLS();
		var list:Array = Excel.Parse(bytes);
		return CsvReader.ReadDict(list[0]);
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
