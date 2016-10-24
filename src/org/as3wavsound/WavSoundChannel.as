package org.as3wavsound {
	import flash.events.EventDispatcher;
	import flash.media.SoundChannel;
	import flash.events.Event;
	import flash.media.SoundTransform;
	import org.as3wavsound.sazameki.core.AudioSamples;
	import org.as3wavsound.WavSound;

	/**
	 * Used to keep track of open channels during playback. Each channel represents
	 * an 'instance' of a sound and so each channel is responsible for its own mixing.
	 * 
	 * Also see buffer().
	 * 
	 * @author b.bottema [Codemonkey]
	 */
	public class WavSoundChannel extends EventDispatcher {
		
		/*
		 * creation-time information 
		 */
		
		// the player to delegate play() stop() requests to
		private var player:WavSoundPlayer;
		
		// a WavSound currently playing back on one or several channels
		private var _wavSound:WavSound;
		
		// works the same as SoundChannel.soundTransform
		private var _soundTransform:SoundTransform = new SoundTransform();
		
		/*
		 * play-time information *per WavSound*
		 */
		
		// starting phase if not at the beginning, made global to avoid recalculating all the time
		private var startPhase:Number; 
		// current phase of the sound, basically matches a single current sample frame for each WavSound
		private var phase:Number = 0;
		// the current avarage volume of samples buffered to the left audiochannel
		private var _leftPeak:Number = 0;
		// the current avarage volume of samples buffered to the right audiochannel
		private var _rightPeak:Number = 0;
		// how many loops we need to buffer
		private var loopsLeft:Number;
		// indicates if the phase has reached total sample count and no loops are left
		private var finished:Boolean;
		
		/**
		 * Constructor: pre-calculates starting phase (and performs some validation for this).
		 */
		public function WavSoundChannel(player:WavSoundPlayer, wavSound:WavSound, startTime:Number, loops:int, soundTransform:SoundTransform) {
			this.player = player;
			this._wavSound = wavSound;
			if (soundTransform != null) {
				this._soundTransform = soundTransform;
			}
			init(startTime, loops);
		}
		
		/**
		 * Calculates and validates the starting time. Starting time in milliseconds is converted into 
		 * sample position and then marked as starting phase.
		 */
		internal function init(startTime:Number, loops:int):void {
			var startPositionInMillis:Number = Math.floor(startTime);
			var maxPositionInMillis:Number = Math.floor(_wavSound.length);
			if (startPositionInMillis > maxPositionInMillis) {
				throw new Error("startTime greater than sound's length, max startTime is " + maxPositionInMillis);
			}
			phase = startPhase = Math.floor(startPositionInMillis * _wavSound.samples.length / _wavSound.length);
			finished = false;
			loopsLeft = loops;
		}
		
		public function stop():void {
			player.stop(this);
		}
		
		/**
		 * Fills a target samplebuffer with optionally transformed samples from the current 
		 * WavSound instance (which is the current channel).
		 * 
		 * Keeps filling the buffer for each loop the sound should be mixed in the target buffer.
		 * When the buffer is full, phase and loopsLeft keep track of how which and many samples 
		 * still need to be buffered in the next buffering cycle (when this method is called again).
		 * 
		 * @param	sampleBuffer The target buffer to mix in the current (transformed) samples.
		 * @param	soundTransform The soundtransform that belongs to a single channel being played 
		 * 			(containing volume, panning etc.).
		 */	
		internal function buffer(sampleBuffer:AudioSamples):void {
			// calculate volume and panning
			var volume: Number = (_soundTransform.volume / 1);
			var volumeLeft: Number = volume * (1 - _soundTransform.pan) / 2;
			var volumeRight: Number = volume * (1 + _soundTransform.pan) / 2;
			// channel settings
			var needRightChannel:Boolean = _wavSound.playbackSettings.channels == 2;
			var hasRightChannel:Boolean = _wavSound.samples.setting.channels == 2;
			
			// extra references to avoid excessive getter calls in the following 
			// for-loop (it appeares CPU is being hogged otherwise)
			var samplesLength:Number = _wavSound.samples.length;
			var samplesLeft:Vector.<Number> = _wavSound.samples.left;
			var samplesRight:Vector.<Number> = _wavSound.samples.right;
			var sampleBufferLength:Number = sampleBuffer.length;
			var sampleBufferLeft:Vector.<Number> = sampleBuffer.left;
			var sampleBufferRight:Vector.<Number> = sampleBuffer.right;
			
			var leftPeakRecord:Number = 0;
			var rightPeakRecord:Number = 0;
			
			// finally, mix the samples in the master sample buffer
			if (!finished) {
				for (var i:int = 0; i < sampleBufferLength; i++) {
					if (!finished) {					
						// write (transformed) samples to buffer
						var sampleLeft:Number = samplesLeft[phase] * volumeLeft;
						sampleBufferLeft[i] += sampleLeft;
						leftPeakRecord += sampleLeft;
						var channelValue:Number = ((needRightChannel && hasRightChannel) ? samplesRight[phase] : samplesLeft[phase]);
						var sampleRight:Number = channelValue * volumeRight;
						sampleBufferRight[i] += sampleRight;
						rightPeakRecord += sampleRight;
						
						// check playing and looping state
						if (++phase >= samplesLength) {
							phase = startPhase;
							finished = loopsLeft-- == 0;
						}
					}
				}
			
				if (finished) {
					dispatchEvent(new Event(Event.SOUND_COMPLETE));
				}
			}
			
			_leftPeak = leftPeakRecord / sampleBufferLength;
			_rightPeak = rightPeakRecord / sampleBufferLength
		}
		
		internal function get wavSound():WavSound {
			return _wavSound
		}
		
		public function get leftPeak(): Number {
			return _leftPeak;
		}
		
 	 	public function get rightPeak(): Number {
			return _rightPeak;
		}
		
 	 	public function get position(): Number {
			return phase * _wavSound.length / _wavSound.samples.length;
		}
		
		public function get soundTransform():SoundTransform {
			return _soundTransform;
		}
	}
}