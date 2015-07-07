package cc.makeblock.util
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;

	public class FileUtil
	{
		static private const fs:FileStream = new FileStream();
		
		static public function LoadFile(path:String):String
		{
			return ReadString(File.applicationDirectory.resolvePath(path));
		}
		
		static public function ReadBytes(file:File):ByteArray
		{
			var result:ByteArray = new ByteArray();
			fs.open(file, FileMode.READ);
			fs.readBytes(result);
			fs.close();
			return result;
		}
		
		static public function ReadString(file:File):String
		{
			fs.open(file, FileMode.READ);
			var result:String = fs.readUTFBytes(fs.bytesAvailable);
			fs.close();
			return result;
		}
		
		static public function WriteString(file:File, str:String):void
		{
			fs.open(file, FileMode.WRITE);
			fs.writeUTFBytes(str);
			fs.close();
		}
		
		static public function WriteBytes(file:File, bytes:ByteArray):void
		{
			fs.open(file, FileMode.WRITE);
			fs.writeBytes(bytes);
			fs.close();
		}
	}
}