package cc.makeblock.util
{
	import flash.utils.ByteArray;

	public class HexUtil
	{
		static public function bytesToString(bytes:ByteArray):String
		{
			var n:int = bytes.length;
			var list:Array = [];
			for(var i:int=0; i<n; ++i){
				var str:String = bytes[i].toString(16);
				while(str.length < 2){
					str = "0" + str;
				}
				list.push(str);
			}
			return list.join(" ");
		}
		
		static private const blankExp:RegExp = /\s+/;
		
		public static function stringToBytes(str:String):ByteArray
		{
			var result:ByteArray = new ByteArray();
			var list:Array = str.split(blankExp);
			for each(var item:String in list){
				if(!Boolean(item)){
					continue;
				}
				while(item.length > 2){
					result.writeByte(parseInt(item.slice(0, 2),16));
					item = item.slice(2);
				}
				if(item.length > 0){
					result.writeByte(parseInt(item,16));
				}
			}
			result.position = 0;
			return result;
		}
	}
}