package cc.makeblock.mbot.util
{
	public class PathUtil
	{
		static public function GetPath(source:String, relativePath:String):String
		{
			var index:int = source.lastIndexOf("/");
			if(index < 0){
				return relativePath;
			}
			return source.slice(0, index+1) + relativePath;
		}
		
		static public function GetDirName(fullPath:String):String
		{
			var index:int = fullPath.lastIndexOf("/");
			if(index < 0){
				return "";
			}
			return fullPath.slice(0, index+1);
		}
		
		static public function GetFileName(fullPath:String):String
		{
			var index:int = fullPath.lastIndexOf("/");
			if(index < 0){
				return fullPath;
			}
			return fullPath.slice(index+1);
		}
	}
}