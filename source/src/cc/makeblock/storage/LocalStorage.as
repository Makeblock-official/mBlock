package cc.makeblock.storage
{
	import flash.data.EncryptedLocalStore;
	import flash.utils.ByteArray;

	final public class LocalStorage
	{
		static public function hasItem(key:String):Boolean
		{
			return EncryptedLocalStore.getItem(key) != null;
		}
		
		static public function getItem(key:String):ByteArray
		{
			return EncryptedLocalStore.getItem(key);
		}
		
		static public function removeItem(key:String):void
		{
			EncryptedLocalStore.removeItem(key);
		}
		
		static public function setItem(key:String, value:*):void
		{
			if(value is ByteArray){
				EncryptedLocalStore.setItem(key, value);
				return;
			}
			
			var data:ByteArray = getItem(key);
			
			if(data != null){
				data.clear();
			}else{
				data = new ByteArray();
			}
			
			if(value is String){
				data.writeUTFBytes(value);
			}else if(value is Boolean){
				data.writeBoolean(value);
			}else if(typeof value == "number"){
				if(value is int){
					data.writeInt(value);
				}else{
					data.writeDouble(value);
				}
			}else{
				data.writeObject(value);
			}
			
			EncryptedLocalStore.setItem(key, data);
		}
		
		static public function getInt(key:String):int
		{
			var value:ByteArray = getItem(key);
			if(value != null && value.length > 4){
				value.position = 0;
				return value.readInt();
			}
			return 0;
		}
		
		static public function getNumber(key:String):Number
		{
			var value:ByteArray = getItem(key);
			if(value != null && value.length > 8){
				value.position = 0;
				return value.readDouble();
			}
			return 0;
		}
		
		static public function getBoolean(key:String):Boolean
		{
			var value:ByteArray = getItem(key);
			if(value != null && value.length > 1){
				value.position = 0;
				return value.readBoolean();
			}
			return false;
		}
		
		static public function getString(key:String):String
		{
			var value:ByteArray = getItem(key);
			if(value != null){
				value.position = 0;
				return value.readUTFBytes(value.length);
			}
			return null;
		}
		
		static public function getObject(key:String):Object
		{
			var value:ByteArray = getItem(key);
			if(value != null){
				value.position = 0;
				return value.readObject();
			}
			return null;
		}
	}
}