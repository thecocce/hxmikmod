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
   public var pos:Int;
   public var increment:Float;
   inline public static var TYPE="TrackerSamplePosEvent";

   public function new(voice:Int, pos:Int, increment:Float) {
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


class TrackerAudioBufferEvent extends TrackerEvent {
   inline public static var TYPE="TrackerAudioBufferEvent";
   public var buffer:ByteArray;

   public function new(buffer:ByteArray) {
	super(TYPE);
	this.buffer=buffer;
   }
}
