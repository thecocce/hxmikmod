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
import hxmikmod.Mem;


class MODULE {

        /* general module information */
	public var songname:String;
	public var modtype:String;
	public var comment:String;

	public var flags:UWORD;
	public var numchn:UBYTE;
	public var numvoices:UBYTE;
	public var numpos:UWORD;
	public var numpat:UWORD;
	public var numins:UWORD;
	public var numsmp:UWORD;
	public var instruments:Array<INSTRUMENT>;
	public var samples:Array<SAMPLE>;
	public var realchn:UBYTE;
	public var totalchn:UBYTE;

        /* playback settings */
	public var reppos:UWORD;
	public var initspeed:UBYTE;
	public var inittempo:UWORD;
	public var initvolume:UBYTE;
	public var panning:Array<UWORD>;
	public var chanvol:Array<UBYTE>;
	public var bpm:UWORD;
	public var sngspd:UWORD;
	public var volume:SWORD;

	public var extspd:Bool;
	public var panflag:Bool;
	public var wrap:Bool;
	public var loop:Bool;
	public var fadeout:Bool;

	public var patpos:UWORD;
	public var sngpos:SWORD;
	public var sngtime:ULONG;
	public var audiobufferstart:ULONG;

	public var relspd:SWORD;


        /* internal module representation */
	public var numtrk:UWORD;
	public var tracks:Array<MEMPTR>;
	public var patterns:Array<UWORD>;
	public var pattrows:Array<UWORD>;
	public var positions:Array<UWORD>;

	public var forbid:Bool;
	public var numrow:UWORD;
	public var vbtick:UWORD;
	public var sngremainder:UWORD;

	public var control:Array<MP_CONTROL>;
	public var voice:Array<MP_VOICE>;

	public var globalslide:UBYTE;
	public var pat_repcrazy:UBYTE;
	public var patbrk:UWORD;
	public var patdly:UBYTE;
	public var patdly2:UBYTE;
	public var posjmp:SWORD;
	public var bpmlimit:UWORD;



	public function new() {
	   chanvol=new Array<UBYTE>();
	   panning=new Array<UWORD>();
	}

}

