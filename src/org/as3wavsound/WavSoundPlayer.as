package org.as3wavsound {
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import org.as3wavsound.sazameki.core.AudioSamples;
	import org.as3wavsound.sazameki.core.AudioSetting;
	import org.as3wavsound.WavSoundChannel;
	
	/* 
	 * --------------------------------------
	 * b.bottema [Codemonkey] -- WavSound Sound adaption
	 * http://blog.projectnibble.org/
	 * --------------------------------------
	 * sazameki -- audio manipulating library
	 * http://sazameki.org/
	 * --------------------------------------
	 * 
	 * - developed by:
	 * 						Benny Bottema (Codemonkey)
	 * 						blog.projectnibble.org
	 *   hosted by: 
	 *  					Google Code (code.google.com)
	 * 						code.google.com/p/as3wavsound/
	 * 
	 * - audio library in its original state developed by:
	 * 						Takaaki Yamazaki
	 * 						www.zkdesign.jp
	 *   hosted by: 
	 *  					Spark project (www.libspark.org)
	 * 						www.libspark.org/svn/as3/sazameki/branches/fp10/
	 */
	
	/*
	 * Licensed under the MIT License
	 * 
	 * Copyright (c) 2008 Takaaki Yamazaki
	 * 
	 * Permission is hereby granted, free of charge, to any person obtaining a copy
	 * of this software and associated documentation files (the "Software"), to deal
	 * in the Software without restriction, including without limitation the rights
	 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	 * copies of the Software, and to permit persons to whom the Software is
	 * furnished to do so, subject to the following conditions:
	 * 
	 * The above copyright notice and this permission notice shall be included in
	 * all copies or substantial portions of the Software.
	 * 
	 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	 * THE SOFTWARE.
	 */
	
	/**
	 * Playback utility class contains a singular Sound for playback 
	 * and sample mixing.
	 * 
	 * 
	 * @author b.bottema [Codemonkey]
	 */
	internal class WavSoundPlayer {
		public static var MAX_BUFFERSIZE:Number = 8192;

		// the master samples buffer in which all seperate Wavsounds are mixed into, always stereo at 44100Hz and bitrate 16
		private const sampleBuffer:AudioSamples = new AudioSamples(new AudioSetting(), MAX_BUFFERSIZE);
		// a list of all WavSound currenctly in playing mode
		private const playingWavSounds:Vector.<WavSoundChannel> = new Vector.<WavSoundChannel>();
		// the singular playback SOund with which all other WavSounds are played back
		private const player:Sound = configurePlayer();
		
		/**
		 * Static initializer: creates, configures and run the singular sound player. 
		 * Until play() has been called on a WavSound, nothing is audible.
		 */
		private function configurePlayer():Sound {
			var player:Sound = new Sound();
			player.addEventListener(SampleDataEvent.SAMPLE_DATA, onSamplesCallback);
			player.play();
			return player;
		}
		
		/**
		 * Creates WavSoundChannel and adds this to the list of playing currently playing (should be included in the master buffering process).
		 * Also returns this instance for sound manipulation by the end-user (just like the traditional SoundChannel).
		 */
		internal function play(sound:WavSound, startTime:Number, loops:int, sndTransform:SoundTransform):WavSoundChannel {
			var channel:WavSoundChannel = new WavSoundChannel(this, sound, startTime, loops, sndTransform);
			playingWavSounds.push(channel);
			return channel;
		}
		
		/**
		 * Remove a spific currently playing channel.
		 */
		internal function stop(channel:WavSoundChannel):void {
			for each (var playingWavSound:WavSoundChannel in playingWavSounds) {
				if (playingWavSound == channel) {
					playingWavSounds.splice(playingWavSounds.lastIndexOf(playingWavSound), 1);
				}
			}
		}
		
		/**
		 * The heartbeat of the WavSound approach.
		 * Invoked by the player appointed Sound object.
		 * 
		 * Together with this callback all WavSound instances stored in the list
		 * playingWavSounds are mixed together and then written to the outputstream 
		 * 
		 * @param	event Contains the outputstream to mix sound samples into.
		 */
		private function onSamplesCallback(event:SampleDataEvent):void {
			// clear the buffer
			sampleBuffer.clearSamples();
			// have all channels mix their into the master sample buffer
			for each (var playingWavSound:WavSoundChannel in playingWavSounds) {
				playingWavSound.buffer(sampleBuffer);
			}
			
			// extra references to avoid excessive getter calls in the following 
			// for-loop (it appeares CPU is being hogged otherwise)
			var outputStream:ByteArray = event.data;
			var samplesLength:Number = sampleBuffer.length;
			var samplesLeft:Vector.<Number> = sampleBuffer.left;
			var samplesRight:Vector.<Number> = sampleBuffer.right;
			
			// write all mixed samples to the sound's outputstream
			for (var i:int = 0; i < samplesLength; i++) {
				outputStream.writeFloat(samplesLeft[i]);
				outputStream.writeFloat(samplesRight[i]);
			}
		}
		
		private function onSamplesMirrorCallback(event:SampleDataEvent):void {
			// write all mixed samples to the sound's outputstream
			var outputStream:ByteArray = event.data;
			for (var i:int = 0; i < 2048; i++) {
				outputStream.writeFloat(0);
				outputStream.writeFloat(0);
			}
		}
		
		public function getChannels():Vector.<WavSoundChannel>
		{
			return playingWavSounds;
		}
	}
}