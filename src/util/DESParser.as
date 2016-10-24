package util
{
	import com.hurlant.crypto.symmetric.DESKey;
	import com.hurlant.util.Base64;
	
	import flash.utils.ByteArray;

	public class DESParser
	{
		public function DESParser()
		{
		}
		public static function encryptDES(keyStr:String, encryptStr:String):String 
		{ 
			var key:ByteArray = new ByteArray(); 
			key.writeUTFBytes(keyStr);   
			var des:DESKey = new DESKey(key); 
			var encryptArr:ByteArray = new ByteArray(); 
			encryptArr.writeUTFBytes(encryptStr); 
			des.encrypt(encryptArr, 0); 
			var outStr:String = Base64.encodeByteArray(encryptArr); 
			return outStr; 
		} 
		
		public static function decryptDES(keyStr:String, decryptStr:String):String 
		{ 
			var key:ByteArray = new ByteArray(); 
			key.writeUTFBytes(keyStr); 
			var des:DESKey = new DESKey(key); 
			
			var decryptArr:ByteArray = Base64.decodeToByteArray(decryptStr); 
			des.decrypt(decryptArr, 0); 
			var outStr:String = decryptArr.readUTFBytes(decryptArr.length); 
			return outStr; 
		} 
	}
}