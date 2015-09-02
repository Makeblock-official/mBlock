package cc.makeblock.util
{
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	final public class MemUtil
	{
		static private var _Mem:ByteArray;
		static public function get Mem():ByteArray
		{
			if(null == _Mem){
				_Mem = new ByteArray();
				_Mem.length = ApplicationDomain.MIN_DOMAIN_MEMORY_LENGTH;
				_Mem.endian = Endian.LITTLE_ENDIAN;
				ApplicationDomain.currentDomain.domainMemory = _Mem;
			}
			return _Mem;
		}
	}
}