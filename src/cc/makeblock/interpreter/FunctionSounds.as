package cc.makeblock.interpreter
{
	import flash.events.Event;
	import flash.utils.setTimeout;
	
	import blockly.runtime.FunctionProvider;
	import blockly.runtime.Thread;
	
	import scratch.ScratchObj;
	import scratch.ScratchSound;
	
	import sound.NotePlayer;
	import sound.ScratchSoundPlayer;
	import sound.SoundBank;

	internal class FunctionSounds
	{
		static public function Init(provider:FunctionProvider):void
		{
			provider.register("playSound:", playSound);
			provider.register("doPlaySoundAndWait", doPlaySoundAndWait);
			provider.register("stopAllSounds", stopAllSounds);
			
			provider.register("drum:duration:elapsed:from:", playDrumMidi);
			provider.register("playDrum", playDrum);
			provider.register("rest:elapsed:from:", playDrumRest);
			
			provider.register("noteOn:duration:elapsed:from:", playNote);
			provider.register("midiInstrument:", setInstrumentMidi);
			provider.register("instrument:", setInstrument);
			
			provider.register("changeVolumeBy:", changeVolumeBy);
			provider.register("setVolumeTo:", setVolumeTo);
			provider.register("volume", getVolume);
			
			provider.register("changeTempoBy:", changeTempoBy);
			provider.register("setTempoTo:", setTempoTo);
			provider.register("tempo", getTempo);
		}
		
		static private function changeTempoBy(thread:Thread, argList:Array):void
		{
			MBlock.app.stagePane.setTempo(MBlock.app.stagePane.tempoBPM + argList[0]);
		}
		
		static private function setTempoTo(thread:Thread, argList:Array):void
		{
			MBlock.app.stagePane.setTempo(argList[0]);
		}
		
		static private function getTempo(thread:Thread, argList:Array):void
		{
			thread.push(MBlock.app.stagePane.tempoBPM);
		}
		
		static private function changeVolumeBy(thread:Thread, argList:Array):void
		{
			var obj:ScratchObj = thread.userData;
			if(null == obj){
				return;
			}
			obj.setVolume(obj.volume + argList[0]);
		}
		
		static private function setVolumeTo(thread:Thread, argList:Array):void
		{
			var obj:ScratchObj = thread.userData;
			if(null == obj){
				return;
			}
			obj.setVolume(argList[0]);
		}
		
		static private function getVolume(thread:Thread, argList:Array):void
		{
			var obj:ScratchObj = thread.userData;
			thread.push(obj ? obj.volume : 0);
		}
		
		static private function setInstrumentImpl(thread:Thread, argList:Array, isMidi:Boolean):void
		{
			var obj:ScratchObj = thread.userData;
			if(null == obj){
				return;
			}
			var instr:int = argList[0] - 1;
			if (isMidi) {
				// map old to new instrument number
				instr = instrumentMap[instr] - 1; // maps to -1 if out of range
			}
			instr = Math.max(0, Math.min(instr, SoundBank.instrumentNames.length - 1));
			obj.instrument = instr;
		}
		
		static private function setInstrumentMidi(thread:Thread, argList:Array):void
		{
			setInstrumentImpl(thread, argList, true);
		}
		
		static private function setInstrument(thread:Thread, argList:Array):void
		{
			setInstrumentImpl(thread, argList, false);
		}
		
		static private function playNote(thread:Thread, argList:Array):void
		{
			var obj:ScratchObj = thread.userData;
			if(null == obj){
				return;
			}
			var key:Number = argList[0];
			var secs:Number = beatsToSeconds(argList[1]);
			_playNote(obj.instrument, key, secs, obj); // always play entire drum sample
			thread.suspend();
			setTimeout(thread.resume, secs * 1000);
		}
		
		static private function playSound(thread:Thread, argList:Array):void
		{
			var obj:ScratchObj = thread.userData;
			var snd:ScratchSound = obj.findSound(argList[0]);
			if (snd == null) return;
			_playSound(snd, obj);
		}
		
		static private function doPlaySoundAndWait(thread:Thread, argList:Array):void
		{
			var obj:ScratchObj = thread.userData;
			var snd:ScratchSound = obj.findSound(argList[0]);
			if (snd == null) return;
			thread.suspend();
			var player:ScratchSoundPlayer = _playSound(snd, obj, function(evt:Event):void{
				thread.resume();
			});
		}
		
		static private function stopAllSounds(thread:Thread, argList:Array):void
		{
			ScratchSoundPlayer.stopAllSounds();
		}
		static private function playDrum(thread:Thread, argList:Array):void
		{
			playDrumImpl(thread, argList, false);
		}
		static private function playDrumMidi(thread:Thread, argList:Array):void
		{
			playDrumImpl(thread, argList, true);
		}
		static private function playDrumRest(thread:Thread, argList:Array):void
		{
			var obj:ScratchObj = thread.userData;
			if(null == obj){
				return;
			}
			var secs:Number = beatsToSeconds(argList[0]);
			thread.suspend();
			setTimeout(thread.resume, secs * 1000);
		}
		
		static private function playDrumImpl(thread:Thread, argList:Array, isMidi:Boolean):void
		{
			var obj:ScratchObj = thread.userData;
			if(null == obj){
				return;
			}
			var drum:int = Math.round(argList[0]);
			var secs:Number = beatsToSeconds(argList[1]);
			_playDrum(drum, isMidi, 10, obj); // always play entire drum sample
			thread.suspend();
			setTimeout(thread.resume, secs * 1000);
		}
		
		static private function _playSound(s:ScratchSound, client:ScratchObj, callback:Function=null):ScratchSoundPlayer
		{
			var player:ScratchSoundPlayer = s.sndplayer();
			player.client = client;
			player.startPlaying(callback);
			return player;
		}
		
		static private function _playDrum(drum:int, isMIDI:Boolean, secs:Number, client:ScratchObj):ScratchSoundPlayer {
			var player:NotePlayer = SoundBank.getDrumPlayer(drum, isMIDI, secs);
			if (player == null) return null;
			player.client = client;
			player.setDuration(secs);
			player.startPlaying();
			return player;
		}
		
		static private function beatsToSeconds(beats:Number):Number {
			return (beats * 60) / MBlock.app.stagePane.tempoBPM;
		}
		
		static private function _playNote(instrument:int, midiKey:Number, secs:Number, client:ScratchObj):ScratchSoundPlayer {
			var player:NotePlayer = SoundBank.getNotePlayer(instrument, midiKey);
			if (player == null) return null;
			player.client = client;
			player.setNoteAndDuration(midiKey, secs);
			player.startPlaying();
			return player;
		}
		
		// Map from a Scratch 1.4 (i.e. MIDI) instrument number to the closest Scratch 2.0 equivalent.
		static private const instrumentMap:Array = [
			// Acoustic Grand, Bright Acoustic, Electric Grand, Honky-Tonk
			1, 1, 1, 1,
			// Electric Piano 1, Electric Piano 2, Harpsichord, Clavinet
			2, 2, 4, 4,	
			// Celesta, Glockenspiel, Music Box, Vibraphone
			17, 17, 17, 16,
			// Marimba, Xylophone, Tubular Bells, Dulcimer
			19, 16, 17, 17,
			// Drawbar Organ, Percussive Organ, Rock Organ, Church Organ
			3, 3, 3, 3,
			// Reed Organ, Accordion, Harmonica, Tango Accordion
			3, 3, 3, 3,
			// Nylon String Guitar, Steel String Guitar, Electric Jazz Guitar, Electric Clean Guitar
			4, 4, 5, 5,
			// Electric Muted Guitar, Overdriven Guitar,Distortion Guitar, Guitar Harmonics
			5, 5, 5, 5,
			// Acoustic Bass, Electric Bass (finger), Electric Bass (pick), Fretless Bass
			6, 6, 6, 6,
			// Slap Bass 1, Slap Bass 2, Synth Bass 1, Synth Bass 2
			6, 6, 6, 6, 
			// Violin, Viola, Cello, Contrabass
			8, 8, 8, 8,
			// Tremolo Strings, Pizzicato Strings, Orchestral Strings, Timpani
			8, 7, 8, 19,
			// String Ensemble 1, String Ensemble 2, SynthStrings 1, SynthStrings 2
			8, 8, 8, 8,
			// Choir Aahs, Voice Oohs, Synth Voice, Orchestra Hit
			15, 15, 15, 19,
			// Trumpet, Trombone, Tuba, Muted Trumpet
			9, 9, 9, 9,
			// French Horn, Brass Section, SynthBrass 1, SynthBrass 2
			9, 9, 9, 9, 
			// Soprano Sax, Alto Sax, Tenor Sax, Baritone Sax
			11, 11, 11, 11,
			// Oboe, English Horn, Bassoon, Clarinet
			14, 14, 14, 10,
			// Piccolo, Flute, Recorder, Pan Flute
			12, 12, 13, 13,
			// Blown Bottle, Shakuhachi, Whistle, Ocarina
			13, 13, 12, 12,
			// Lead 1 (square), Lead 2 (sawtooth), Lead 3 (calliope), Lead 4 (chiff)
			20, 20, 20, 20,
			// Lead 5 (charang), Lead 6 (voice), Lead 7 (fifths), Lead 8 (bass+lead)
			20, 20, 20, 20, 
			// Pad 1 (new age), Pad 2 (warm), Pad 3 (polysynth), Pad 4 (choir)
			21, 21, 21, 21,
			// Pad 5 (bowed), Pad 6 (metallic), Pad 7 (halo), Pad 8 (sweep)
			21, 21, 21, 21,
			// FX 1 (rain), FX 2 (soundtrack), FX 3 (crystal), FX 4 (atmosphere)
			21, 21, 21, 21,
			// FX 5 (brightness), FX 6 (goblins), FX 7 (echoes), FX 8 (sci-fi)
			21, 21, 21, 21,
			// Sitar, Banjo, Shamisen, Koto
			4, 4, 4, 4,
			// Kalimba, Bagpipe, Fiddle, Shanai
			17, 14, 8, 10,
			// Tinkle Bell, Agogo, Steel Drums, Woodblock
			17, 17, 18, 19,
			// Taiko Drum, Melodic Tom, Synth Drum, Reverse Cymbal
			1, 1, 1, 1,
			// Guitar Fret Noise, Breath Noise, Seashore, Bird Tweet
			21, 21, 21, 21,
			// Telephone Ring, Helicopter, Applause, Gunshot
			21, 21, 21, 21
		];		
	}
}