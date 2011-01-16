/**
 *
 * hxMikMod sound library
 * Copyright (C) 2011 Jouko Pynnönen <jouko@iki.fi>
 *             
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

package hxmikmod;

import flash.events.SampleDataEvent;
import flash.media.SoundChannel;
import flash.media.Sound;
import hxmikmod.Types;
import hxmikmod.SAMPLE;
import hxmikmod.event.TrackerEvent;
import hxmikmod.event.TrackerEventDispatcher;


class FlashDriver extends MDriver {
	var sound:Sound;
	var channel:SoundChannel;

	public function new(params:Hash<Dynamic>) {
	   Name="FlashDriver for hxMikMod (c) jouko@iki.fi";
	   Version=Name;
	   HardVoiceLimit=1;
	   SoftVoiceLimit=32;
	   Virtch.buffer_size=4096;
	   if (params!=null) try {
	      if (params.exists("buffer_size")) Virtch.buffer_size=cast(params.get("buffer_size"));
	   } catch(e:Dynamic) { trace(e); }
	}



	function onSampleData(event:SampleDataEvent):Void {
           try {
		//if (channel!=null)
		//   TrackerEventDispatcher.setLatency(event.position/44.1-channel.position);
                Virtch.WriteSamples(event.data);
           } catch(e:Dynamic) { trace(e); }
	}



        override public function IsPresent():Bool {
          return true;
        }

        override public function SampleLoad(s:SAMPLOAD,a:Int):SWORD {
          return Virtch.VC_SampleLoad(s,a);
        }

        override public function FreeSampleSpace(a:Int):ULONG {
           return Virtch.VC_SampleSpace(a);
        }

        override public function RealSampleLength(a:Int,s:SAMPLE):ULONG {
           return Virtch.VC_SampleLength(a,s);
        }

        override public function Init():Bool {
          return Virtch.VC_Init();
        }

        override public function Exit() {
          trace("Exit");
        }

        override public function Reset():Bool {
	  Virtch.VC_Reset();
          return true;
        }

        override public function SetNumVoices():Bool {
          return Virtch.VC_SetNumVoices();
        }

        override public function PlayStart():Bool {
          if (sound==null) {
		sound=new Sound();
        	sound.addEventListener(SampleDataEvent.SAMPLE_DATA,onSampleData);
        	channel=sound.play();
	  }
          return Virtch.VC_PlayStart();
        }

        override public function PlayStop():Void {
        	if (sound!=null) {
        	   sound.removeEventListener(SampleDataEvent.SAMPLE_DATA,onSampleData);
        	   sound=null;
		   channel=null;
		}
        }


        override public function Pause():Void {
          trace("Pause");
        }

        override public function VoiceSetVolume(a:UBYTE,b:UWORD):Void {
           Virtch.VC_VoiceSetVolume(a,b);
        }

        override public function VoiceGetVolume(a:UBYTE):UWORD {
           return Virtch.VC_VoiceGetVolume(a);
        }

        override public function VoiceSetFrequency(a:UBYTE,b:ULONG):Void {
           Virtch.VC_VoiceSetFrequency(a,b);
        }

        override public function VoiceGetFrequency(a:UBYTE):ULONG {
          trace("VoiceGetFrequency");
          return 0;
        }

        override public function VoiceSetPanning(a:UBYTE,b:ULONG):Void {
           Virtch.VC_VoiceSetPanning(a,b);
        }

        override public function VoiceGetPanning(a:UBYTE):ULONG {
          trace("VoiceGetPanning");
          return 0;
        }

        override public function VoicePlay(a:UBYTE,b:SWORD,c:ULONG,d:ULONG,e:ULONG,f:ULONG,g:UWORD):Void {
           Virtch.VC_VoicePlay(a,b,c,d,e,f,g);
        }

        override public function VoiceStop(a:UBYTE):Void {
           Virtch.VC_VoiceStop(a);
	}

        override public function VoiceStopped(a:UBYTE):Bool {
            return Virtch.VC_VoiceStopped(a);
        }

        override public function VoiceGetPosition(a:UBYTE):SLONG {
           return Virtch.VC_VoiceGetPosition(a);
        }

        override public function VoiceRealVolume(a:UBYTE):ULONG {
          trace("VoiceRealVolume");
          return 0;
        }


}
