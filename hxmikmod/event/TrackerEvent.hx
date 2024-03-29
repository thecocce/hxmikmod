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

package hxmikmod.event;

import hxmikmod.Types;
import hxmikmod.MODULE;
import flash.events.Event;
import flash.utils.ByteArray;


class TrackerEvent extends Event {

}

class TrackerVoiceEvent extends TrackerEvent {
   public var voice:UBYTE;
   public var handle:SWORD;
   public var start:ULONG;
   public var size:ULONG;
   public var reppos:ULONG;
   public var repend:ULONG;
   public var flags:UWORD;
   inline public static var TYPE="TrackerVoiceEvent";

   public function new(voice:UBYTE,handle:SWORD,start:ULONG,size:ULONG,reppos:ULONG,repend:ULONG,flags:UWORD) {
	super(TYPE);
	this.voice=voice; this.handle=handle; this.start=start; this.size=size;
	this.reppos=reppos; this.repend=repend; this.flags=flags;
   }
}



class TrackerSamplePosEvent extends TrackerEvent {
   public var voice:Int;
   public var pos:Float;
   public var increment:Float;
   inline public static var TYPE="TrackerSamplePosEvent";

   public function new(voice:Int, pos:Float, increment:Float) {
	super(TYPE);
	this.voice=voice; this.pos=pos; this.increment=increment;
   }
}

class TrackerLoadingEvent extends TrackerEvent {
   public var state:Int;
   public var message:String;
   public var progress:Float;
   public var module:MODULE;
   inline public static var TYPE="TrackerLoadingEvent";
   // states
   inline public static var LOADING=0;
   inline public static var LOADED=1;
   inline public static var FAILED=2;

   public function new(state:Int,message:String,?progress:Float=1,?module=null) {
	super(TYPE);
	this.state=state;
	this.message=message;
	this.progress=progress;
	this.module=module;
   }
}


class TrackerNoteEvent extends TrackerEvent {
   inline public static var TYPE="TrackerNoteEvent";
   public var channel:hxmikmod.MP_CHANNEL;

   public function new(channel:hxmikmod.MP_CHANNEL) {
	super(TYPE);
	this.channel=channel;
   }
}


// This is called when a block of data is sent to the audio output device.
// It is not guaranteed to be size complete SampleEvent buffer.
// "addr" is a byte index to the Mem.buf bytebuffer,
// "samples" is the count of stereo samples (dual-Floats) written,
// "pos" is how many stereo samples was written before this block
// "audiobufsize" is the total size of the SampleEvent.data buffer (constant)


class TrackerAudioBufferEvent extends TrackerEvent {
   inline public static var TYPE="TrackerAudioBufferEvent";
   public var addr:ByteArray;
   public var startpos:Int;
   public var endpos:Int;
   public var audiobufsize:Int;

   public function new(addr:ByteArray,startpos:Int,endpos:Int,audiobufsize:Int) {
	super(TYPE);
	this.addr=addr;
	this.startpos=startpos;
	this.endpos=endpos;
	this.audiobufsize=audiobufsize;
   }
}


class TrackerPlayPosEvent extends TrackerEvent {
   inline public static var TYPE="TrackerPlayPosEvent";
   public var pos:Int;
   public var max:Int;
   public var finished:Bool;

   public function new(pos:Int,max:Int,finished:Bool) {
	super(TYPE);
	this.pos=pos; this.max=max; this.finished=finished;
   }

}
