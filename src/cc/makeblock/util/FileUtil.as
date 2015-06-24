package cc.makeblock.util
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;

	public class FileUtil
	{
		static public function LoadFile(path:String):String
		{
			var ba:ByteArray = new ByteArray();
			var fs:FileStream = new FileStream();
			fs.open(File.applicationDirectory.resolvePath(path), FileMode.READ);
			fs.readBytes(ba);
			fs.close();
			return ba.readUTFBytes(ba.bytesAvailable);
		}
	}
}