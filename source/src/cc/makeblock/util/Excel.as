package cc.makeblock.util
{
	import flash.utils.ByteArray;

	final public class Excel
	{
		/** 返回一个三维数组(表,行,列) */
		static public function Parse(excelBytes:ByteArray):Array
		{
			var excel:Array = [];
			var fileDict:Object = Zip.Parse(excelBytes);
			var fileList:Array = GetFileList(XML(fileDict["xl/workbook.xml"]));
			XML.ignoreWhitespace = false;
			var strList:Array = GetStrList(XML(fileDict["xl/sharedStrings.xml"]));
			XML.ignoreWhitespace = true;
			
			for(var i:int=0; i<fileList.length; ++i)
			{
				var tableUrl:String = "xl/worksheets/sheet" + (i+1) + ".xml";
				var table:Array = ReadTable(XML(fileDict[tableUrl]), strList);
				excel[fileList[i]] = table;
				excel[i] = table;
			}
			
			return excel;
		}
		
		static private function GetFileList(workbook:XML):Array
		{
			var fileList:Array = [];
			var ns:Namespace = workbook.namespace();
			for each(var sheet:XML in workbook.ns::sheets.ns::sheet){
				var index:int = parseInt(sheet.@sheetId) - 1;
				fileList[index] = String(sheet.@name);
			}
			return fileList;
		}
		
		static private function GetStrList(sharedStrings:XML):Array
		{
			var strList:Array = [];
			var ns:Namespace = sharedStrings.namespace();
			for each(var si:XML in sharedStrings.ns::si){
				var text:String = "";
				for each(var t:XML in si..ns::t){
					text += t.toString();
				}
				strList.push(text);
			}
			return strList;
		}
		
		static private function ReadTable(table:XML, strList:Array):Array
		{
			var ns:Namespace = table.namespace();
			var rowList:Array = [];
			for each(var row:XML in table.ns::sheetData.ns::row){
				var colList:Array = [];
				for each(var col:XML in row.ns::c){
					var colIndex:int = GetColIndex(col.@r);
					var v:String = col.ns::v[0];
					colList[colIndex] = (String(col.@t) == "s") ? strList[v] : v;
				}
				rowList.push(colList);
			}
			return rowList;
		}
		
		static private function GetColIndex(colStr:String):int
		{
			colStr = colStr.replace(/\d/g, "");
			var result:int = 0;
			for(var i:int=0, n:int=colStr.length; i<n; ++i){
				result *= 26;
				result += colStr.charCodeAt(i) - 65;
			}
			return result;
		}
	}
}