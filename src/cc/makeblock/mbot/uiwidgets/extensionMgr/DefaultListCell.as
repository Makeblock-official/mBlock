package cc.makeblock.mbot.uiwidgets.extensionMgr
{
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.TextEvent;
	import flash.filesystem.File;
	import flash.filters.GlowFilter;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.utils.ByteArray;
	
	import cc.makeblock.mbot.util.PopupUtil;
	
	import org.aswing.ASColor;
	import org.aswing.AbstractListCell;
	import org.aswing.AsWingConstants;
	import org.aswing.BorderLayout;
	import org.aswing.BoxLayout;
	import org.aswing.Component;
	import org.aswing.FlowLayout;
	import org.aswing.Insets;
	import org.aswing.JButton;
	import org.aswing.JLabel;
	import org.aswing.JPanel;
	import org.aswing.JSharedToolTip;
	import org.aswing.border.EmptyBorder;
	import org.aswing.border.SideLineBorder;
	import org.aswing.event.AWEvent;
	import org.aswing.event.ResizedEvent;
	import org.aswing.geom.IntPoint;
	
	import translation.Translator;
	
	import util.ApplicationManager;
	
	/**
	 * Default list cell, render item value.toString() text.
	 * @author iiley
	 */
	public class DefaultListCell extends AbstractListCell{
		
		private var jlabel:DefaultLabel;
		private var downloadBtn:JButton;
		private var delBtn:JButton;
		private var updataBtn:JButton;
		private var wrapper:JPanel;
		private var btnPanel:JPanel;
		private static var sharedToolTip:JSharedToolTip;
		public function DefaultListCell(){
			super();
			if(sharedToolTip == null){
				sharedToolTip = new JSharedToolTip();
				sharedToolTip.setOffsetsRelatedToMouse(false);
				sharedToolTip.setOffsets(new IntPoint(0, 0));
			}
		}
		 private var dataObj:Object = new Object();
		private var updataObj:Object;
		private var canUpdata:Boolean;
		override public function setCellValue(valueObj:*) : void {
			super.setCellValue(valueObj);
			canUpdata = false;
			if(ExtensionUtil.currExtArr.indexOf(valueObj)<0)
			{
				ExtensionUtil.currExtArr.push(valueObj);
			}
			
			dataObj = valueObj;
			if(ExtensionUtil.showType==0)
			{
				updataObj = valueObj;
			}
			else
			{
				for each(var obj:Object in ExtensionUtil.getAvailableList())
				{
					if(valueObj.name==obj.name)
					{
						updataObj = obj;
						break;
					}
				}
			}
			getJLabel().clearText();
			var valu:String = '<p><FONT FACE="Arial" SIZE="15" COLOR="#000000" LETTERSPACING="0" KERNING="0"><b>'+valueObj.name+'<b></FONT></p>'
			getJLabel().setLabel(valu);
			valu = '<a href="http://'+valueObj.authorLink+'"><FONT FACE="Arial" SIZE="12" COLOR="#0292FD" LETTERSPACING="0" KERNING="0">'+valueObj.author+'</FONT></a>'
			getJLabel().setLabel(valu);
			valu = '<p><FONT FACE="Arial" SIZE="10" COLOR="#666666" LETTERSPACING="0" KERNING="0">'+valueObj.version+'</FONT></p>'
			getJLabel().setLabel(valu);
			
			getSummaryLabel().clearText();
			valu = '<p><FONT FACE="Arial" SIZE="12" COLOR="#444444" LETTERSPACING="0" KERNING="0">'+valueObj.description+'</FONT></p>'
			getSummaryLabel().setLabel(valu);
			
			if(ExtensionUtil.showType==1)
			{
				if(valueObj.homepage && valueObj.homepage!="")
				{
					if(valueObj.homepage.indexOf("http")>-1)
					{
						valu = '<a href="'+valueObj.homepage+'"><FONT FACE="Times New Roman" SIZE="12" COLOR="#0292FD">'+Translator.map("More Info")+'</FONT>&nbsp;&nbsp;&nbsp;<a href=\"event:00\"><FONT FACE="Times New Roman" SIZE="12" COLOR="#0292FD">'+Translator.map("View Source")+'</FONT></a></a>';
					}
					else
					{
						valu = '<a href="http://'+valueObj.homepage+'"><FONT FACE="Times New Roman" SIZE="12" COLOR="#0292FD">'+Translator.map("More Info")+'</FONT>&nbsp;&nbsp;&nbsp;<a href=\"event:00\"><FONT FACE="Times New Roman" SIZE="12" COLOR="#0292FD">'+Translator.map("View Source")+'</FONT></a></a>';
					}
					
				}
				else
				{
					valu = '<a href=\"event:00\"><FONT FACE="Times New Roman" SIZE="12" COLOR="#0292FD">'+Translator.map("View Source")+'</FONT></a></a>';
				}
				
				getSummaryLabel().setLabel(valu);
				getSummaryLabel().htmlText.addEventListener(TextEvent.LINK, linkHandler);
				
			}
			else
			{
				if(valueObj.homepage && valueObj.homepage!="")
				{
					if(valueObj.homepage.indexOf("http")>-1)
					{
						valu = '<a href="'+valueObj.homepage+'"><FONT FACE="Times New Roman" SIZE="12" COLOR="#0292FD">'+Translator.map("More Info")+'</FONT></a>';
					}
					else
					{
						valu = '<a href="http://'+valueObj.homepage+'"><FONT FACE="Times New Roman" SIZE="12" COLOR="#0292FD">'+Translator.map("More Info")+'</FONT></a>';
					}
					getSummaryLabel().setLabel(valu);
				}
				
			}
			updataBtnStatus();
			__resized(null);
		}
		
		private function linkHandler(e:TextEvent):void
		{
			//trace("查看源代码")
			__onViewSource();
		}
		/**
		 * Override this if you need other value->string translator
		 */
		
		override public function getCellComponent() : Component {
			if(null == wrapper){
				wrapper = new JPanel(new BoxLayout(0,0));
				
				wrapper.append(getJLabel());
				wrapper.append(getSummaryLabel(),BorderLayout.CENTER);
				
				downloadBtn = new JButton();
				downloadBtn.addEventListener(MouseEvent.CLICK,downloadHandler);
				downloadBtn.setX(200);
				
				downloadBtn.setBorder(new EmptyBorder(null, new Insets(0, 0, 0, 6)));
				
				
				delBtn = new JButton();
				delBtn.setText(Translator.map("Remove"));
				delBtn.addEventListener(MouseEvent.CLICK,removeHandler);
				
				updataBtn = new JButton();
				updataBtn.setText(Translator.map("Update"));
				updataBtn.addEventListener(MouseEvent.CLICK,downloadHandler);
				
			
				
				wrapper.setBorder(new SideLineBorder(null, SideLineBorder.SOUTH, new ASColor(0xf5f5f5)));
				wrapper.setHeight(100);
				wrapper.setOpaque(true);
				if(!btnPanel)
				{
					btnPanel = new JPanel(new FlowLayout(AsWingConstants.RIGHT,0));
				}
				
				wrapper.append(btnPanel,BorderLayout.EAST);
			}
			btnPanel.removeAll();
			
			if(ExtensionUtil.showType==0)
			{
				btnPanel.append(downloadBtn);
				
			}
			else if(ExtensionUtil.showType==1)
			{
				if(canUpdata)
				{
					btnPanel.append(updataBtn);
				}
				if(!dataObj.isMakeBlockBoard)
				{
					btnPanel.append(delBtn);
				}
				
			}
			
			return wrapper;
		}
		private function updataBtnStatus():void
		{
			if(ExtensionUtil.showType==0)
			{
				switch(hasDownloaded(dataObj,MBlock.app.extensionManager.extensionList))
				{
					case -1:
						//no download
						downloadBtn.setText(Translator.map("Download"));
						downloadBtn.setEnabled(true);
						break;
					case 0:
					case 1:
						//has downloaded
						downloadBtn.setText(Translator.map("Downloaded"));
						downloadBtn.setEnabled(false);
						break;
					case 2:
						//has a new version
						downloadBtn.setText(Translator.map("Update"));
						downloadBtn.setEnabled(true);
						break;
					default:
				}
			}
			else if(ExtensionUtil.showType==1)
			{
				if(hasDownloaded(dataObj,ExtensionUtil.getAvailableList())==1)
				{
					canUpdata = true;
				}
				else
				{
					canUpdata = false;
					btnPanel.remove(updataBtn);	
				}
				if(dataObj.isMakeBlockBoard && delBtn.parent)
				{
					btnPanel.remove(delBtn);
				}
			}
			delBtn.setText(Translator.map("Remove"));
			updataBtn.setText(Translator.map("Update"));
		}
		private function hasDownloaded(targetObj:Object,sourceArr:Array):int
		{
			for each(var ext:Object in sourceArr){
				if(ext.extensionName==targetObj.name || ext.name==targetObj.name)
				{
					if(convertVersion(ext.version)<convertVersion(targetObj.version))
					{
						return 2;
					}
					else if(convertVersion(ext.version)>convertVersion(targetObj.version))
					{
						return 1;
					}
					else
					{
						return 0;
					}
				}
			}
			//this is a new extension
			return -1;
		}
		private  function convertVersion(str:String):Number
		{
			var arr:Array = str.split(".");
			var count:Number=Number("0."+str.replace(/\./g,""));
			return count;
		}
		private function removeHandler(evt:MouseEvent):void
		{
			trace("delete？")
			ExtensionUtil.dispatcher.dispatchEvent(new Event("removeItem"));
		}
		private function downloadHandler(evt:MouseEvent):void
		{
			function onErrorHandler(e:IOErrorEvent):void
			{
				PopupUtil.showAlert(Translator.map("Connection timeout"));
				loader.removeEventListener(IOErrorEvent.IO_ERROR,onErrorHandler);
				loader.removeEventListener(ProgressEvent.PROGRESS, onDownloadProgress);
				loader.removeEventListener(Event.COMPLETE, onDownloadComplete);
				evt.target.setEnabled(true);
			}
			evt.target.setEnabled(false);
			var loader:URLLoader = new URLLoader();
			var urlRequest:URLRequest = new URLRequest("http://www.mblock.cc/extensions/uploads/"+updataObj.download);
			trace("urlRequest="+urlRequest.url,updataObj.name);
			urlRequest.method = URLRequestMethod.GET;
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.load(urlRequest);
			loader.addEventListener(Event.COMPLETE, onDownloadComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR,onErrorHandler);
			loader.addEventListener(ProgressEvent.PROGRESS, onDownloadProgress);
			
		}
		private function onDownloadProgress(e:ProgressEvent):void
		{
			var percent:Number = e.bytesLoaded/e.bytesTotal;
			
			trace(percent*100,"%")
		}
		private function onDownloadComplete(e:Event):void
		{
			ExtensionUtil.parseZip(ByteArray(e.target.data));
			canUpdata = false;
			btnPanel.remove(updataBtn);	
			ExtensionUtil.dispatcher.dispatchEvent(new Event("updateList"));
			//MBlock.app.stage.removeChild(progressSp);
			trace("保存完成")
		}
		private function __onViewSource(evt:AWEvent=null):void
		{
			var extName:String = dataObj.name.toLowerCase();
			extName = extName.replace(/^\s+|\s+$/g,"");
			/*if(extName == "communication"){
				extName = "serial";
			}*/
			/*var file:File = ApplicationManager.sharedManager().documents.resolvePath("mBlock/libraries");
			for each(var item:File in file.getDirectoryListing()){
				if(item.name.toLowerCase() == extName){
					item.openWithDefaultApplication();
				}
			}*/
			//由于主板文件夹名和s2e文件描述的名字不一样，导致查看源码找不到路径，现在是通过对比s2e里面的extensionName来确定路径  by tql 20160810
			for each(var obj:Object in MBlock.app.extensionManager.extensionList)
			{
				if(obj.extensionName.toLowerCase()==extName)
				{
					var path:String = decodeURI(obj.srcPath);
					var _arr:Array = path.split("/");
					path = _arr[_arr.length-2];
					break;
				}
			}
			var file:File = ApplicationManager.sharedManager().documents.resolvePath("mBlock/libraries/"+path);
			if(file.exists){
				file.openWithDefaultApplication();
			}
		}
		
		protected function getJLabel():DefaultLabel{
			if(jlabel==null)
			{
				jlabel = new DefaultLabel(true,true);
			}
			return jlabel;
		}
		
		
		private var summaryLabel:DefaultLabel;
		protected function getSummaryLabel():DefaultLabel{
			if(summaryLabel == null){
				summaryLabel = new DefaultLabel(true,true);
			}
			return summaryLabel;
		}
		private var moreInfoLabel:JLabel;
		protected function getMoreInfoLabel():JLabel{
			if(moreInfoLabel == null){
				moreInfoLabel = new JLabel();
				moreInfoLabel.setBorder(new EmptyBorder(null, new Insets(0, 6, 0, 0)));
				//initJLabel(moreInfoLabel);
				
				moreInfoLabel.setTextFilters([new GlowFilter(0x0292df,0.5,6,6,2,1.5,true)]);
			}
			return moreInfoLabel;
		}
		
		protected function initJLabel(jlabel:JLabel):void{
			jlabel.setHorizontalAlignment(JLabel.LEFT);
//			jlabel.setOpaque(true);
			jlabel.setFocusable(false);
			jlabel.addEventListener(ResizedEvent.RESIZED, __resized);
		}
		
		protected function __resized(e:ResizedEvent):void{
			if(getJLabel().getWidth() < getJLabel().getPreferredWidth()){
				getJLabel().setToolTipText(value.toString());
				JSharedToolTip.getSharedInstance().unregisterComponent(getJLabel());
				sharedToolTip.registerComponent(getJLabel());
			}else{
				getJLabel().setToolTipText(null);
				sharedToolTip.unregisterComponent(getJLabel());
			}
		}
	}
}

