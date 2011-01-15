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

class ENVPT {
	public var pos:SWORD;
	public var val:SWORD;
	public function new() { }
}


class Envelope {
        public var flg:UBYTE;           /* bit 0: on 1: sustain 2: loop */
        public var pts:UBYTE;
        public var susbeg:UBYTE;
        public var susend:UBYTE;
        public var beg:UBYTE;
        public var end:UBYTE;
        public var env:Array<ENVPT>;   // x ENVPOINTS
	public function new() {
	   env=new Array();
	   for (i in 0 ... Defs.ENVPOINTS) env[i]=new ENVPT();
	}
}



class INSTRUMENT {
        public var insname:String;

        public var flags:UBYTE;
        public var samplenumber:Array<UWORD>; // x INSTNOTES
        public var samplenote:Array<UBYTE>;   // x INSTNOTES

        public var nnatype:UBYTE;
        public var dca:UBYTE;              /* duplicate check action */
        public var dct:UBYTE;              /* duplicate check type */
        public var globvol:UBYTE;
        public var volfade:UWORD;
        public var panning:UWORD;          /* instrument-based panning var */

        public var pitpansep:UBYTE;        /* pitch pan separation (0 to 255) */
        public var pitpancenter:UBYTE;     /* pitch pan center (0 to 119) */
        public var rvolvar:UBYTE;          /* random volume varations (0 - 100%) */
        public var rpanvar:UBYTE;          /* random panning varations (0 - 100%) */



        /* volume envelope */
	public var vol_env:Envelope;
        /* panning envelope */
	public var pan_env:Envelope;
        /* pitch envelope */
	public var pit_env:Envelope;

	public function new() {
	   vol_env=new Envelope();
	   pan_env=new Envelope();
	   pit_env=new Envelope();
	   samplenumber=new Array();
	   samplenote=new Array();
	}
}


