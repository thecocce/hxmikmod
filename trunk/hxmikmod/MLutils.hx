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


class FILTER {
   public var filter:UBYTE;
   public var inf:UBYTE;
}


class MLutils {

   /*========== Shared loader variables */

   public static var remap=new Array<SBYTE>(); 		//[UF_MAXCHAN];   /* for removing empty channels */
   public static var poslookup; 	/* lookup table for pattern jumps after blank pattern removal */
   public static var poslookupcnt:UBYTE;
   public static var origpositions;

   public static var filters:Bool;              	/* resonant filters in use */
   public static var activemacro:UBYTE;            	/* active midi macro number for Sxx,xx<80h */
   public static var filtermacros:Array<UBYTE>;		//[UF_MAXMACRO];    /* midi macro settings */
   public static var filtersettings:Array<FILTER>;	//[UF_MAXFILTER]; /* computed filter settings */

   /* Generic effect writing routine */
   public static function UniEffect(eff:UWORD,dat:UWORD):Void {
        if((eff==0)||(eff>=Defs.UNI_LAST)) return;
        MUnitrk.UniWriteByte(eff);
        if(MUnitrk.unioperands[eff]==2)
                MUnitrk.UniWriteWord(dat);
        else
                MUnitrk.UniWriteByte(dat);
   }

   /*  Appends UNI_PTEFFECTX opcode to the unitrk stream. */
   public static function UniPTEffect(eff:UBYTE,dat:UBYTE):Void {
        if((eff!=0)||(dat!=0)||(MLoader.of.flags&Defs.UF_ARPMEM)!=0) UniEffect(Defs.UNI_PTEFFECT0+eff,dat);
   }

   /* Appends UNI_VOLEFFECT + effect/dat to unistream. */
   public static function UniVolEffect(eff:UWORD,dat:UBYTE):Void {
        if((eff!=0)||(dat!=0)) { /* don't write empty effect */
                MUnitrk.UniWriteByte(Defs.UNI_VOLEFFECTS);
                MUnitrk.UniWriteByte(eff);MUnitrk.UniWriteByte(dat);
        }
   }

   public static function UniInstrument(x:UWORD):Void {
	UniEffect(Defs.UNI_INSTRUMENT,x);
   }

   public static function UniNote(x:UWORD):Void {
	UniEffect(Defs.UNI_NOTE,x);
   }


   /*========== Order stuff */

   /* handles S3M and IT orders */
   public static function S3MIT_CreateOrders(curious:Bool) {
	MLoader.of.numpos = 0;
	for (i in 0 ... poslookupcnt) MLoader.of.positions[i]=0;
        //memset(of.positions,0,poslookupcnt*sizeof(UWORD));
	for (i in 0 ... 256) poslookup[i]=-1;
	//memset(poslookup,-1,256);
        for(t in 0 ... poslookupcnt) {
                var order=origpositions[t];
                if(order==255) order=Defs.LAST_PATTERN;
                MLoader.of.positions[MLoader.of.numpos]=order;
                poslookup[t]=MLoader.of.numpos; /* bug fix for freaky S3Ms / ITs */
                if(origpositions[t]<254) MLoader.of.numpos++;
                else
                        /* end of song special order */
                        if((order==Defs.LAST_PATTERN)&&(!(curious=!curious))) break;
        }
   }


   static inline function toSBYTE(b:Int) {
	b=b&255;
	if (b>=128) b-=256;
	return b;
   }

   /*========== Effect stuff */

   /* handles S3M and IT effects */
   public static function S3MIT_ProcessCmd(cmd:UBYTE,inf:UBYTE,flags:Int /*unsigned*/):Void {
	var hi:UBYTE;
	var lo:UBYTE;

        lo=inf&0xf;
        hi=inf>>4;

        /* process S3M / IT specific command structure */

        if(cmd!=255) {
                switch(cmd) {
                        case 1: /* Axx set speed to xx */
                                UniEffect(Defs.UNI_S3MEFFECTA,inf);
                                //break;
                        case 2: /* Bxx position jump */
                                if (inf<poslookupcnt) {
                                        /* switch to curious mode if necessary, for example
                                           sympex.it, deep joy.it */
                                        if((toSBYTE(poslookup[inf])<0)&&(origpositions[inf]!=255))
                                                S3MIT_CreateOrders(true);

                                        if(!(toSBYTE(poslookup[inf])<0))
                                                UniPTEffect(0xb,poslookup[inf]);
                                }
                                //break;
                        case 3: /* Cxx patternbreak to row xx */
                                if ((flags & Defs.S3MIT_OLDSTYLE!=0) && (flags & Defs.S3MIT_IT)==0)
                                        UniPTEffect(0xd,(inf>>4)*10+(inf&0xf));
                                else
                                        UniPTEffect(0xd,inf);
                                //break;
                        case 4: /* Dxy volumeslide */
                                UniEffect(Defs.UNI_S3MEFFECTD,inf);
                                //break;
                        case 5: /* Exy toneslide down */
                                UniEffect(Defs.UNI_S3MEFFECTE,inf);
                                //break;
                        case 6: /* Fxy toneslide up */
                                UniEffect(Defs.UNI_S3MEFFECTF,inf);
                                //break;
                        case 7: /* Gxx Tone portamento, speed xx */
                                if (flags & Defs.S3MIT_OLDSTYLE!=0)
                                        UniPTEffect(0x3,inf);
                                else
                                        UniEffect(Defs.UNI_ITEFFECTG,inf);
                                //break;
                        case 8: /* Hxy vibrato */
                                if (flags & Defs.S3MIT_OLDSTYLE!=0)
                                        UniPTEffect(0x4,inf);
                                else
                                        UniEffect(Defs.UNI_ITEFFECTH,inf);
                                //break;
                        case 9: /* Ixy tremor, ontime x, offtime y */
                                if (flags & Defs.S3MIT_OLDSTYLE!=0)
                                        UniEffect(Defs.UNI_S3MEFFECTI,inf);
                                else                     
                                        UniEffect(Defs.UNI_ITEFFECTI,inf);
                                //break;
                        case 0xa: /* Jxy arpeggio */
                                UniPTEffect(0x0,inf);
                                //break;
                        case 0xb: /* Kxy Dual command H00 & Dxy */
                                if (flags & Defs.S3MIT_OLDSTYLE!=0)
                                        UniPTEffect(0x4,0);    
                                else
                                        UniEffect(Defs.UNI_ITEFFECTH,0);
                                UniEffect(Defs.UNI_S3MEFFECTD,inf);
                                //break;
                        case 0xc: /* Lxy Dual command G00 & Dxy */
                                if (flags & Defs.S3MIT_OLDSTYLE!=0)
                                        UniPTEffect(0x3,0);
                                else
                                        UniEffect(Defs.UNI_ITEFFECTG,0);
                                UniEffect(Defs.UNI_S3MEFFECTD,inf);
                                //break;
                        case 0xd: /* Mxx Set Channel Volume */
                                UniEffect(Defs.UNI_ITEFFECTM,inf);
                                //break;       
                        case 0xe: /* Nxy Slide Channel Volume */
                                UniEffect(Defs.UNI_ITEFFECTN,inf);
                                //break;
                        case 0xf: /* Oxx set sampleoffset xx00h */
                                UniPTEffect(0x9,inf);
                                //break;
                        case 0x10: /* Pxy Slide Panning Commands */
                                UniEffect(Defs.UNI_ITEFFECTP,inf);
                                //break;
                        case 0x11: /* Qxy Retrig (+volumeslide) */
                                MUnitrk.UniWriteByte(Defs.UNI_S3MEFFECTQ);
                                if(inf!=0 && lo==0 && (flags & Defs.S3MIT_OLDSTYLE)==0)
                                        MUnitrk.UniWriteByte(1);
                                else
                                        MUnitrk.UniWriteByte(inf); 
                                //break;
                        case 0x12: /* Rxy tremolo speed x, depth y */
                                UniEffect(Defs.UNI_S3MEFFECTR,inf);
                                //break;
                        case 0x13: /* Sxx special commands */
                                if (inf>=0xf0) {
                                        /* change resonant filter settings if necessary */
                                        if((filters)&&((inf&0xf)!=activemacro)) {
                                                activemacro=inf&0xf;
                                                for(inf in 0 ... 0x80)
                                                        filtersettings[inf].filter=filtermacros[activemacro];
                                        }
                                } else {
                                        /* Scream Tracker does not have samples larger than
                                           64 Kb, thus doesn't need the SAx effect */
                                        if (!((flags & Defs.S3MIT_SCREAM)!=0 && ((inf & 0xf0) == 0xa0)))
                                                //break;

                                        UniEffect(Defs.UNI_ITEFFECTS0,inf);
                                }
                                //break;
                        case 0x14: /* Txx tempo */
                                if(inf>=0x20)
                                        UniEffect(Defs.UNI_S3MEFFECTT,inf);
                                else {
                                        if((flags & Defs.S3MIT_OLDSTYLE)==0)
                                                /* IT Tempo slide */
                                                UniEffect(Defs.UNI_ITEFFECTT,inf);
                                }
                                //break;
                        case 0x15: /* Uxy Fine Vibrato speed x, depth y */
                                if(flags & Defs.S3MIT_OLDSTYLE!=0)
                                        UniEffect(Defs.UNI_S3MEFFECTU,inf);
                                else
                                        UniEffect(Defs.UNI_ITEFFECTU,inf);
                                //break;
                        case 0x16: /* Vxx Set Global Volume */
                                UniEffect(Defs.UNI_XMEFFECTG,inf);
                                //break;
                        case 0x17: /* Wxy Global Volume Slide */
                                UniEffect(Defs.UNI_ITEFFECTW,inf);
                                //break;
                        case 0x18: /* Xxx amiga command 8xx */
                                if(flags & Defs.S3MIT_OLDSTYLE!=0) {
                                        if(inf>128)
                                                UniEffect(Defs.UNI_ITEFFECTS0,0x91); /* surround */
                                        else
                                                UniPTEffect(0x8,(inf==128)?255:(inf<<1));
                                } else
                                        UniPTEffect(0x8,inf);
                                //break;
                        case 0x19: /* Yxy Panbrello  speed x, depth y */
                                UniEffect(Defs.UNI_ITEFFECTY,inf);
                                //break;
                        case 0x1a: /* Zxx midi/resonant filters */
                                if(filtersettings[inf].filter!=0) {
                                        MUnitrk.UniWriteByte(Defs.UNI_ITEFFECTZ);
                                        MUnitrk.UniWriteByte(filtersettings[inf].filter);
                                        MUnitrk.UniWriteByte(filtersettings[inf].inf);
                                }
                                //break;
                }
        }
   }


   /*========== Linear periods stuff */

   public static var noteindex:Array<Int>=null;
   static var noteindexcount=0;

   public static function AllocLinear():Array<Int> {
        if(MLoader.of.numsmp>noteindexcount) {
                noteindexcount=MLoader.of.numsmp;
		if (noteindex==null) noteindex=new Array();
                //noteindex=realloc(noteindex,noteindexcount*sizeof(int));
        }
        return noteindex;
   }


   public static function FreeLinear():Void {
	noteindex=null;
        noteindexcount=0;
   }


   public static function speed_to_finetune(speed:ULONG,sample:Int):Int {
    	var ctmp=0;
    	var tmp:Int;
    	var note=1;
    	var finetune=0;

    	speed>>=1;
    	while((tmp=MPlayer.getfrequency(MLoader.of.flags,MPlayer.getlinearperiod(note<<1,0)))<speed) {
           ctmp=tmp;
           note++;
    	}

    	if(tmp!=speed) {
           if((tmp-speed)<(speed-ctmp))
              while(tmp>speed)
                tmp=MPlayer.getfrequency(MLoader.of.flags,MPlayer.getlinearperiod(note<<1,--finetune));
           else {
              note--;
              while(ctmp<speed)
                ctmp=MPlayer.getfrequency(MLoader.of.flags,MPlayer.getlinearperiod(note<<1,++finetune));
           }
    	}

    	noteindex[sample]=note-4*Defs.OCTAVE;
    	return finetune;
   }



}
