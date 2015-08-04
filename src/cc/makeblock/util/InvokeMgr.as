package cc.makeblock.util
{
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.desktop.ClipboardTransferMode;
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeDragActions;
	import flash.desktop.NativeDragManager;
	import flash.display.InteractiveObject;
	import flash.events.InvokeEvent;
	import flash.events.NativeDragEvent;
	import flash.filesystem.File;

	public class InvokeMgr
	{
		public function InvokeMgr()
		{
			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, __onInvoked);
			
			MBlock.app.stage.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, __onDragEnter);
			MBlock.app.stage.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, __onDragDrop);
		}
		
		private function __onDragEnter(evt:NativeDragEvent):void
		{
			NativeDragManager.dropAction = NativeDragActions.LINK;
			NativeDragManager.acceptDragDrop(evt.currentTarget as InteractiveObject);
		}
		
		private function __onDragDrop(evt:NativeDragEvent):void
		{
			var file:File = evt.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT)[0];
			if(file.extension != "sb2"){
				return;
			}
			MBlock.app.runtime.selectedProjectFile(file);
		}
		
		private function __onInvoked(evt:InvokeEvent):void
		{
			if(evt.arguments.length <= 0){
				return;
			}
			var arg:String = evt.arguments[0];
			if(Boolean(arg)){
				MBlock.app.runtime.selectedProjectFile(new File(arg));
			}
		}
	}
}