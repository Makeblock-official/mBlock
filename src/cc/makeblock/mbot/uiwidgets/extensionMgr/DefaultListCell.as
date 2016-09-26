package cc.makeblock.mbot.uiwidgets.extensionMgr
{
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filters.GlowFilter;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.utils.ByteArray;
	
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
		
		override public function setCellValue(valueObj:*) : void {
			super.setCellValue(valueObj);
			dataObj = valueObj;
			getJLabel().clearText();
			var valu:String = '<p><FONT FACE="Times New Roman" SIZE="15" COLOR="#000000" LETTERSPACING="0" KERNING="0"><b>'+valueObj.name+'<b></FONT></p>'
			getJLabel().setLabel(valu);
			valu = '<a href="'+valueObj.authorLink+'"><FONT FACE="Times New Roman" SIZE="12" COLOR="#0292FD" LETTERSPACING="0" KERNING="0">'+valueObj.author+'</FONT></a>'
			getJLabel().setLabel(valu);
			valu = '<p><FONT FACE="Times New Roman" SIZE="10" COLOR="#666666" LETTERSPACING="0" KERNING="0">'+valueObj.version+'</FONT></p>'
			getJLabel().setLabel(valu);
			
			getSummaryLabel().clearText();
			valu = '<p><FONT FACE="Times New Roman" SIZE="12" COLOR="#444444" LETTERSPACING="0" KERNING="0">'+valueObj.description+'</FONT></p>'
			getSummaryLabel().setLabel(valu);
			valu = '<a href="http://www.mblock.cc/extensions/"><FONT FACE="Times New Roman" SIZE="12" COLOR="#0292FD" LETTERSPACING="0" KERNING="0">更多信息</FONT></a>'
			getSummaryLabel().setLabel(valu);
			if(ExtensionUtil.showType==0)
			{
				updataBtnStatus();
			}
			__resized(null);
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
				if(!delBtn)
				{
					delBtn = new JButton();
					delBtn.setText(Translator.map("delete"));
					delBtn.addEventListener(MouseEvent.CLICK,removeHandler);
				}
				btnPanel.append(delBtn);
			}
			
			return wrapper;
		}
		private function updataBtnStatus():void
		{
			switch(hasDownloaded(dataObj,MBlock.app.extensionManager.extensionList))
			{
				case 0:
					//no download
					downloadBtn.setText(Translator.map("download"));
					downloadBtn.setEnabled(true);
					break;
				case 1:
					//has downloaded
					downloadBtn.setText(Translator.map("downloaded"));
					downloadBtn.setEnabled(false);
					break;
				case 2:
					//has a new version
					downloadBtn.setText(Translator.map("updata"));
					downloadBtn.setEnabled(true);
					break;
				default:
			}
		}
		private function hasDownloaded(targetObj:Object,sourceArr:Array):uint
		{
			for each(var ext:Object in sourceArr){
				if(ext.extensionName==targetObj.name)
				{
					//if local has a file
					trace(ext.extensionName,"ext.version="+ext.version,"targetObj.version="+targetObj.version)
					if(convertVersion(ext.version)<convertVersion(targetObj.version))
					{
						//there is a new version from network.
						return 2;
					}
					else
					{
						return 1;
					}
				}
			}
			return 0;
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
			var loader:URLLoader = new URLLoader();
			var urlRequest:URLRequest = new URLRequest("http://www.mblock.cc/extensions/uploads/"+dataObj.download);
			trace("urlRequest="+urlRequest.url);
			urlRequest.method = URLRequestMethod.GET;
			var fileName:String = dataObj.download;
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.load(urlRequest);
			loader.addEventListener(Event.COMPLETE, onDownloadComplete);
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
			trace("保存完成")
		}
		private function __onViewSource(evt:AWEvent):void
		{
			var extName:String = getJLabel().getText().toLowerCase();
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

