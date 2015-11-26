package cc.makeblock.util
{
	import flash.utils.ByteArray;

	internal class ZipFile
	{
		private var _compressionMethod:uint;
		private var _sizeCompressed:uint;
		
		private var _encrypted:Boolean;
		private var _hasDataDescriptor:Boolean;
		public var filenameEncoding:String;
		
		private var _isCompressed:Boolean;
		private var _fileName:String;
		private var _data:ByteArray;
		
		public function ZipFile()
		{
		}
		
		public function getName():String
		{
			return _fileName;
		}
		
		public function getData():ByteArray
		{
			if(_isCompressed){
				uncompressData();
				_isCompressed = false;
			}
			return _data;
		}
		
		public function toString():String
		{
			return getData().toString();
		}
		
		public function read(ba:ByteArray):void
		{
			readHead(ba);
			readBody(ba);
		}
		
		private function findDataDescriptor(stream:ByteArray):void
		{
			var sign:uint = 0;
			while(stream.bytesAvailable > 0)
			{
				var char:uint = stream.readUnsignedByte();
				sign = (sign >>> 8) | (char << 24);
				if(sign == 0x08074b50){
					_data.length -= 3;
					validateDataDescriptor(stream);
					return;
				}
				_data.writeByte(char);
			}
		}
		
		private function validateDataDescriptor(stream:ByteArray):void
		{
			if(stream.bytesAvailable < 12){
				return;
			}
			
			stream.position += 4;		//crc32
			const sizeCompressed:uint = stream.readUnsignedInt();
			stream.position += 4;		//sizeUncompressed
			
			if(_data.length == sizeCompressed){
				_data.position = 0;
				_sizeCompressed = sizeCompressed;
			}else{
				_data.writeBytes(stream, stream.position-12, 12);
				findDataDescriptor(stream);
			}
		}
		
		private function readBody(ba:ByteArray):void
		{
			_data = new ByteArray();
			
			if(_hasDataDescriptor){
				findDataDescriptor(ba);
			}else if(_sizeCompressed > 0){
				ba.readBytes(_data, 0, _sizeCompressed);
			}//else no file
		}
		
		private function uncompressData():void
		{
			switch(_compressionMethod)
			{
				case 8:						//COMPRESSION_DEFLATED
					_data.inflate();
					break;
				case 0:						//COMPRESSION_NONE
					break;
				case 14:					//LZMA
					_data.uncompress("lzma");
					break;
				default:
					trace("Compression method " + _compressionMethod + " is not supported.");
			}
		}
		
		private function readHead(ba:ByteArray):void
		{
			ba.position += 2;			//version
			
			const flag:uint = ba.readUnsignedShort();
			_compressionMethod = ba.readUnsignedShort();
			
			_isCompressed = _compressionMethod > 0;
			
			_encrypted = (flag & 0x01) !== 0;
			_hasDataDescriptor = (flag & 0x08) !== 0;
			
			if((flag & 800) !== 0){
				filenameEncoding = "utf-8";
			}
			
			ba.position += 4;			//last modified time and date
			ba.position += 4;			//crc32
			_sizeCompressed = ba.readUnsignedInt();
			ba.position += 4;			//sizeUncompressed
			
			const sizeFilename:uint = ba.readUnsignedShort();
			const sizeExtra:uint = ba.readUnsignedShort();
			
			_fileName = ba.readUTFBytes(sizeFilename);
			ba.position += sizeExtra;
		}
	}
}