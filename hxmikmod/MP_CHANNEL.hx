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


class MP_CHANNEL {
	public var i:INSTRUMENT;
	public var s:SAMPLE;

	public var sample:UBYTE;
	public var note:UBYTE;
	public var outvolume:SWORD;
	public var chanvol:SBYTE;
	public var fadevol:UWORD;
	public var panning:SWORD;
	public var kick:UBYTE;
	public var kick_flag:Bool;
	public var period:UWORD;
	public var nna:UBYTE;

	public var volflg:UBYTE;
	public var panflg:UBYTE;
	public var pitflg:UBYTE;

	public var keyoff:Int;
	public var handle:SWORD;
	public var notedelay:UBYTE;
	public var start:SLONG;
	public function new() {
	}

	public function clone():MP_CHANNEL {
	   var ret=new MP_CHANNEL();
	   ret.i=i; ret.s=s; ret.sample=sample; ret.note=note; ret.outvolume=outvolume; ret.chanvol=chanvol;
	   ret.fadevol=fadevol; ret.panning=panning; ret.kick=kick; ret.kick_flag=kick_flag;
	   ret.period=period; ret.nna=nna; ret.volflg=volflg; ret.panflg=panflg; ret.pitflg=pitflg;
	   ret.keyoff=keyoff; ret.handle=handle; ret.notedelay=notedelay; ret.start=start;
	   return ret;
	}

}

