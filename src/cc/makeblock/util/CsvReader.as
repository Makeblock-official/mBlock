package cc.makeblock.util
{
	public class CsvReader
	{
		static public function ReadDict(list:Array):Object
		{
			return ForEach(list, _ReadDict);
		}
		
		static private function _ReadDict(column:Object, key:String, value:String):void
		{
			if(Boolean(value)){
				column[key] = value;
			}
		}
		
		static public function PrintRepeatLines(list:Array, keyModifier:Function=null):void
		{
			ForEach(list, function(column:Object, key:String, value:String):void{
				var newKey:String = (keyModifier != null) ? keyModifier(key) : key;
				if(newKey in column){
					trace(key);
				}else{
					column[newKey] = true;
				}
			});
		}
		
		static private function ForEach(list:Array, handler:Function):Object
		{
			var result:Object = {};
			for(var i:int=1, n:int=list.length; i<n; ++i){
				var line:Array = list[i];
				var key:String = line[0];
				if(!Boolean(key)){
					continue;
				}
				for(var j:int=1, m:int=line.length; j<m; ++j){
					var column:String = list[0][j];
					if(!Boolean(column)){
						continue;
					}
					if(null == result[column]){
						result[column] = {};
					}
					handler(result[column], key, line[j]);
				}
			}
			return result;
		}
	}
}