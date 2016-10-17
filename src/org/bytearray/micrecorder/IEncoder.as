package org.bytearray.micrecorder
{
	import flash.utils.ByteArray;

	public interface IEncoder
	{
		function encode(samples:ByteArray, channels:int=2, bits:int=16, rate:int=44100):ByteArray;
	}
}