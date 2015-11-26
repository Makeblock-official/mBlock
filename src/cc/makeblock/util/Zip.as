package cc.makeblock.util
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	final public class Zip
	{
		static private const file:ZipFile = new ZipFile();
		
		static public function Parse(zipBytes:ByteArray, filenameEncoding:String="utf-8"):Object
		{
			zipBytes.endian = Endian.LITTLE_ENDIAN;
			
			var result:Object = {};
			
			while(zipBytes.bytesAvailable > 0){
				if(zipBytes.readUnsignedInt() != 0x04034b50){
					break;
				}
				file.filenameEncoding = filenameEncoding;
				file.read(zipBytes);
				result[file.getName()] = file.getData();
			}
			
			return result;
		}
	}
}