package org.as3wavsound.sazameki.format.wav {
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import org.as3wavsound.sazameki.core.AudioSamples;
	import org.as3wavsound.sazameki.core.AudioSetting;
	import org.as3wavsound.sazameki.format.riff.Chunk;
	import org.as3wavsound.sazameki.format.riff.RIFF;
	import org.as3wavsound.sazameki.format.wav.chunk.WavdataChunk;
	import org.as3wavsound.sazameki.format.wav.chunk.WavfmtChunk;
	
	/**
	 * The WAVE decoder used for playing back wav files.
	 * 
	 * @author Takaaki Yamazaki(zk design), modified by b.bottema [Codemonkey]
	 */
	public class Wav extends RIFF {

		public function Wav() {
			super('WAVE');
		}
		
		public function encode(samples:AudioSamples):ByteArray {
			var fmt:WavfmtChunk = new WavfmtChunk();
			var data:WavdataChunk = new WavdataChunk();

			_chunks = new Vector.<Chunk>;
			_chunks.push(fmt);
			_chunks.push(data);

			data.setAudioData(samples);
			fmt.setSetting(samples.setting);
			
			return toByteArray();
		}
		
		public function decode(wavData:ByteArray):AudioSamples {
			var obj:Object = splitList(wavData);
			if (obj['fmt '] && obj['data']) {
				var setting:AudioSetting = new WavfmtChunk().decodeData(obj['fmt '] as ByteArray);
				var data:AudioSamples = new WavdataChunk().decodeData(obj['data'] as ByteArray, setting);
				return data;
			} else {
				throw new Error('invalid wav file');
			}
		}
	}
}