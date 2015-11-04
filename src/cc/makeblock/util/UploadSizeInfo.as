package cc.makeblock.util
{
	public class UploadSizeInfo
	{
		static private const begin:RegExp = /writing flash \((\d+) bytes\):/;
		static private const regExp1:RegExp = /(Recv|Send: U).+\r/g;
		static private const regExp2:RegExp = /Send: d/g;
		static private const regExp3:RegExp = /\[\w+\]/g;
		
		private var beginIndex:int;
		private var bytesTotal:int;
		
		public function UploadSizeInfo()
		{
		}
		
		public function reset():void
		{
			bytesTotal = 0;
		}
		
		public function update(msg:String):int
		{
			if(bytesTotal > 0){
				msg = msg.slice(beginIndex).replace(regExp1, "");
				var a:Array = msg.match(regExp2);
				var b:Array = msg.match(regExp3);
				var bytesLoad:int =  b.length - a.length * 5 - 2;
				return 100 * bytesLoad / bytesTotal;
			}else{
				var result:Object = begin.exec(msg);
				if(result != null){
					bytesTotal = parseInt(result[1]);
					beginIndex = result.index + result[0].length;
				}
			}
			return 0;
		}
	}
}