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
import hxmikmod.INSTRUMENT;

class MP_VOICE {
	public var main:MP_CHANNEL;

	public var venv:ENVPR;
	public var penv:ENVPR;
	public var cenv:ENVPR;

	public var avibpos:UWORD;
	public var aswppos:UWORD;

	public var totalvol:ULONG;

	public var mflag:Bool;
	public var masterchn:SWORD;
	public var masterperiod:UWORD;

	public var master:MP_CONTROL;	// ptr

	public function new() {
		main=new MP_CHANNEL();
		venv=new ENVPR();
		penv=new ENVPR();
		cenv=new ENVPR();
	}
}


class ENVPR {
        public var flg:UBYTE;          /* envelope flag */
        public var pts:UBYTE;          /* number of envelope points */
        public var susbeg:UBYTE;       /* envelope sustain index begin */
        public var susend:UBYTE;       /* envelope sustain index end */
        public var beg:UBYTE;          /* envelope loop begin */
        public var end:UBYTE;          /* envelope loop end */
        public var p:SWORD;            /* current envelope counter */
        public var a:UWORD;            /* envelope index a */
        public var b:UWORD;            /* envelope index b */
        public var env:Array<ENVPT>;          /* envelope points */

	public function new() {
	}
}


