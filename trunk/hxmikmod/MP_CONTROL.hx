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

import hxmikmod.Types;

class MP_CONTROL {
	public var main:MP_CHANNEL;
	public var slave:MP_VOICE;

	public var slavechn:UBYTE;
	public var muted:Bool;
	public var ultoffset:UWORD;
	public var anote:UBYTE;
	public var oldnote:UBYTE;
	public var ownper:SWORD;
	public var ownvol:SWORD;
	public var dca:UBYTE;
	public var dct:UBYTE;
	public var rowdata:Array<UBYTE>;
	public var row:Int;		// index of rowdata
	public var retrig:SBYTE;
	public var speed:ULONG;
	public var volume:SWORD;

	public var tmpvolume:SWORD;
	public var tmpperiod:UWORD;
	public var wantedperiod:UWORD;

	public var arpmem:UBYTE;
	public var pansspd:UBYTE;
	public var slidespeed:UWORD;
	public var portspeed:UWORD;

	public var s3mtremor:UBYTE;
	public var s3mtronof:UBYTE;
	public var s3mvolslide:UBYTE;
	public var sliding:Bool;
	public var s3mrtgspeed:UBYTE;
	public var s3mrtgslide:UBYTE;

	public var glissando:UBYTE;
	public var wavecontrol:UBYTE;

	public var vibpos:SBYTE;
	public var vibspd:UBYTE;
	public var vibdepth:UBYTE;

	public var trmpos:SBYTE;
	public var trmspd:UBYTE;
	public var trmdepth:UBYTE;

	public var fslideupspd:UBYTE;
	public var fslidednspd:UBYTE;
	public var fportupspd:UBYTE;
	public var fportdnspd:UBYTE;
	public var ffportupspd:UBYTE;
	public var ffportdnspd:UBYTE;	

	public var hioffset:ULONG;
	public var soffset:UWORD;

	public var sseffect:UBYTE;
	public var ssdata:UBYTE;
	public var chanvolslide:UBYTE;

	public var panbwave:UBYTE;
	public var panbpos:UBYTE;
	public var panbspd:SBYTE;
	public var panbdepth:UBYTE;

	public var newsamp:UWORD;
	public var voleffect:UBYTE;
	public var voldata:UBYTE;

	public var pat_reppos:SWORD;
	public var pat_repcnt:UWORD;

	public function new() {
		main=new MP_CHANNEL();
	}

}

