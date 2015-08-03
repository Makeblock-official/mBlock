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
	}
}