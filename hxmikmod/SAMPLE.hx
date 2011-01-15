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
import hxmikmod.MMio;

class SAMPLE {
        public var panning:SWORD;     /* panning (0-255 or PAN_SURROUND) */
        public var speed:ULONG;       /* Base playing speed/frequency of note */
        public var volume:UBYTE;      /* volume 0-64 */
        public var inflags:UWORD;         /* sample format on disk */
        public var flags:UWORD;       /* sample format in memory */
        public var length:ULONG;      /* length of sample (in samples!) */
        public var loopstart:ULONG;   /* repeat position (relative to start, in samples) */
        public var loopend:ULONG;     /* repeat end */
        public var susbegin:ULONG;    /* sustain loop begin (in samples) \  Not Supported */
        public var susend:ULONG;      /* sustain loop end                /      Yet! */

        /* Variables used by the module player only! (ignored for sound effects) */
        public var globvol:UBYTE;     /* global volume */
        public var vibflags:UBYTE;    /* autovibrato flag stuffs */
        public var vibtype:UBYTE;     /* Vibratos moved from INSTRUMENT to SAMPLE */
        public var vibsweep:UBYTE;
        public var vibdepth:UBYTE;
        public var vibrate:UBYTE;
        public var samplename:String;  /* name of the sample */

        /* Values used internally only */
        public var avibpos:UWORD;     /* autovibrato pos [player use] */
        public var divfactor:UBYTE;   /* for sample scaling, maintains proper period slides */
        public var seekpos:ULONG;     /* seek position in file */
        public var handle:SWORD;      /* sample handle used by individual drivers */

	public function new() {
	}
}



/*========== Samples */

/* This is a handle of sorts attached to any sample registered with
   SL_RegisterSample.  Generally, this only need be used or changed by the
   loaders and drivers of mikmod. */

class SAMPLOAD {
	public var next:SAMPLOAD;
        public var length:ULONG;       /* length of sample (in samples!) */
        public var loopstart:ULONG;    /* repeat position (relative to start, in samples) */
        public var loopend:ULONG;      /* repeat end */
        public var infmt:UWORD;
	public var outfmt:UWORD;
        public var scalefactor:Int;
        public var sample:SAMPLE;	// ptr
        public var reader:MREADER;	// ptr
	public function new() {
	}
}


