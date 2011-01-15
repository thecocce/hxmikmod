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


class MUnitrk {

   /* Unibuffer chunk size */
   inline public static var BUFPAGE=128;

   public static var unioperands=[
        0, /* not used */
        1, /* UNI_NOTE */
        1, /* UNI_INSTRUMENT */
        1, /* UNI_PTEFFECT0 */
        1, /* UNI_PTEFFECT1 */
        1, /* UNI_PTEFFECT2 */
        1, /* UNI_PTEFFECT3 */
        1, /* UNI_PTEFFECT4 */
        1, /* UNI_PTEFFECT5 */
        1, /* UNI_PTEFFECT6 */
        1, /* UNI_PTEFFECT7 */
        1, /* UNI_PTEFFECT8 */
        1, /* UNI_PTEFFECT9 */
        1, /* UNI_PTEFFECTA */
        1, /* UNI_PTEFFECTB */
        1, /* UNI_PTEFFECTC */
        1, /* UNI_PTEFFECTD */
        1, /* UNI_PTEFFECTE */
        1, /* UNI_PTEFFECTF */
        1, /* UNI_S3MEFFECTA */
        1, /* UNI_S3MEFFECTD */
        1, /* UNI_S3MEFFECTE */
        1, /* UNI_S3MEFFECTF */
        1, /* UNI_S3MEFFECTI */
        1, /* UNI_S3MEFFECTQ */
        1, /* UNI_S3MEFFECTR */
        1, /* UNI_S3MEFFECTT */
        1, /* UNI_S3MEFFECTU */
        0, /* UNI_KEYOFF */
        1, /* UNI_KEYFADE */
        2, /* UNI_VOLEFFECTS */
        1, /* UNI_XMEFFECT4 */
        1, /* UNI_XMEFFECT6 */
        1, /* UNI_XMEFFECTA */
        1, /* UNI_XMEFFECTE1 */
        1, /* UNI_XMEFFECTE2 */
        1, /* UNI_XMEFFECTEA */
        1, /* UNI_XMEFFECTEB */
        1, /* UNI_XMEFFECTG */
        1, /* UNI_XMEFFECTH */
        1, /* UNI_XMEFFECTL */
        1, /* UNI_XMEFFECTP */
        1, /* UNI_XMEFFECTX1 */
        1, /* UNI_XMEFFECTX2 */
        1, /* UNI_ITEFFECTG */
        1, /* UNI_ITEFFECTH */
        1, /* UNI_ITEFFECTI */
        1, /* UNI_ITEFFECTM */
        1, /* UNI_ITEFFECTN */
        1, /* UNI_ITEFFECTP */
        1, /* UNI_ITEFFECTT */
        1, /* UNI_ITEFFECTU */
        1, /* UNI_ITEFFECTW */
        1, /* UNI_ITEFFECTY */
        2, /* UNI_ITEFFECTZ */
        1, /* UNI_ITEFFECTS0 */
        2, /* UNI_ULTEFFECT9 */
        2, /* UNI_MEDSPEED */
        0, /* UNI_MEDEFFECTF1 */
        0, /* UNI_MEDEFFECTF2 */
        0, /* UNI_MEDEFFECTF3 */
        2, /* UNI_OKTARP */
   ];



/*========== Reading routines */

   public static var rowstart:Int;
   public static var rowend:Int;
   public static var rowpc:Int;
   public static var lastbyte:UBYTE;
   public static var rowdata:Array<UBYTE>;


   // pointers -> indices. NULL -> -1

   public static function UniSetRow(rd:Array<UBYTE>,t:Int) {
	rowdata=rd;
        rowstart = t;
        rowpc    = rowstart;
        rowend   = (t!=-1)?rowstart+(rowdata[rowpc++]&0x1f):t;
   }

   public static function UniGetByte():UBYTE {
        return lastbyte = ((rowpc<rowend)?rowdata[rowpc++]:0)&255;
   }

   public static function UniGetWord():UWORD {
        return (UniGetByte()<<8)|UniGetByte();
   }


   public static function UniSkipOpcode():Void {
        if (lastbyte < Defs.UNI_LAST) {
                var t=unioperands[lastbyte];
                while (t--!=0)
                        UniGetByte();
        }
   }



   /* Finds the address of row number 'row' in the UniMod(tm) stream 't' returns
      NULL if the row can't be found. */

   public static function UniFindRow(t:Array<UBYTE>,row:UWORD):Int {
        var c:UBYTE;
	var l:UBYTE;
	var ti=0;

        if (t!=null)
                while(true) {
                        c = t[ti];             /* get rep/len byte */
                        if (c==0) return -1; /* zero ? -> end of track.. */
                        l = (c>>5)+1;       /* extract repeat value */
                        if (l>row) break;    /* reached wanted row? -> return pointer */
                        row -= l;           /* haven't reached row yet.. update row */
                        ti += (c&0x1f);        /* point t to the next row */
                }
        return t==null?-1:ti;
   }



/*========== Writing routines */

   public static var unibuf:Array<UBYTE>;  /* pointer to the temporary unitrk buffer */
   //public static var unimax:UWORD;  /* buffer size */

   public static var unipc:UWORD;   /* buffer cursor */
   public static var unitt:UWORD;   /* current row index */
   public static var lastp:UWORD;   /* previous row index */

   /* Resets index-pointers to create a new track. */
   public static function UniReset():Void {
        unitt     = 0;   /* reset index to rep/len byte */
        unipc     = 1;   /* first opcode will be written to index 1 */
        lastp     = 0;   /* no previous row yet */
        unibuf[0] = 0;   /* clear rep/len byte */
   }



   /* Expands the buffer */
   public static function UniExpand(wanted:Int):Bool {
	/*
        if ((unipc+wanted)>=unimax) {
		var newbuf:Array<UBYTE>;

                // Expand the buffer by BUFPAGE bytes
                newbuf=(UBYTE*)realloc(unibuf,(unimax+BUFPAGE)*sizeof(UBYTE));

                // Check if realloc succeeded
                if(newbuf) {
                        unibuf = newbuf;
                        unimax+=BUFPAGE;
                        return 1;
                } else 
                        return 0;
        }
        return 1;
	*/
	return true;
   }


   /* Appends one byte of data to the current row of a track. */
   public static function UniWriteByte(data:UBYTE):Void {
	unibuf[unipc++]=data;
   }


   public static function UniWriteWord(data:UWORD):Void {
                unibuf[unipc++]=(data>>8)&0xff;
                unibuf[unipc++]=data&0xff;
   }


   public static function MyCmp(a:Array<UBYTE>,ai:Int,b:Array<UBYTE>,bi:Int,l:UWORD):Bool {
        var t:UWORD;
        for (t in 0 ... l)
                if (a[t+ai]!=b[t+bi]) return false;
        return true;
   }


   /* Closes the current row of a unitrk stream (updates the rep/len byte) and sets
      pointers to start a new row. */
   public static function UniNewline():Void {
	var n:UWORD;
	var l:UWORD;
	var len:UWORD;

        n = (unibuf[lastp]>>5)+1;     /* repeat of previous row */
        l = (unibuf[lastp]&0x1f);     /* length of previous row */

        len = unipc-unitt;            /* length of current row */

        /* Now, check if the previous and the current row are identical.. when they
           are, just increase the repeat field of the previous row */
        if(n<8 && len==l && MyCmp(unibuf,lastp+1,unibuf,unitt+1,len-1)) {
                unibuf[lastp]+=0x20;
                unipc = unitt+1;
        } else {
                        /* current and previous row aren't equal... update the pointers */
                        unibuf[unitt] = len;
                        lastp = unitt;
                        unitt = unipc++;
        }
   }


   static function memcpy(dst:Array<UBYTE>,src:Array<UBYTE>,len:Int) {
	var i;
	for (i in 0 ... len) dst[i]=src[i];
   }



/* Terminates the current unitrk stream and returns a pointer to a copy of the
   stream. */
   public static function UniDup():Array<UBYTE> {
        var d:Array<UBYTE>;

        unibuf[unitt] = 0;

	if ((d=new Array())==null) return null;
        memcpy(d,unibuf,unipc);

        return d;
   }

   public static function UniInit():Bool {
        //unimax = BUFPAGE;
	unibuf=new Array();
	//var i:Int;
	//for (i in 0 ... unimax) unibuf[i]=0;
	return (unibuf!=null);
   }

   public static function UniCleanup() {
	unibuf=null;
   }





}

