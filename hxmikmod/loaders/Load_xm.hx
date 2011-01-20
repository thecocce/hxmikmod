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

package hxmikmod.loaders;

import flash.utils.ByteArray;
import hxmikmod.Types;
import hxmikmod.INSTRUMENT;
import hxmikmod.MLoader;
import hxmikmod.MMio;
import hxmikmod.MUnitrk;
import hxmikmod.MLutils;
import hxmikmod.Defs;
import hxmikmod.SAMPLE;
import hxmikmod.MODULE;
import hxmikmod.Mem;


class XMHEADER {
        public var id:String; //ByteArray; 		//[17];          /* ID text: 'Extended module: ' */
        public var songname:String; //ByteArray; 	//[21];    /* Module name */
        public var trackername:String; //ByteArray;	//[20]; /* Tracker name */
        public var version:UWORD;         /* Version number */
        public var headersize:ULONG;      /* Header size */
        public var songlength:UWORD;      /* Song length (in patten order table) */
        public var restart:UWORD;         /* Restart position */
        public var numchn:UWORD;          /* Number of channels (2,4,6,8,10,...,32) */
        public var numpat:UWORD;          /* Number of patterns (max 256) */
        public var numins:UWORD;          /* Number of instruments (max 128) */
        public var flags:UWORD;       
        public var tempo:UWORD;           /* Default tempo */
        public var bpm:UWORD;             /* Default BPM */
        public var orders:Array<UBYTE>;    //[256];     /* Pattern order table  */

	public function new() {
	   orders=new Array();
	}
}


class XMINSTHEADER {
        public var size:ULONG;     /* Instrument size */
        public var name:String;   //[22]; /* Instrument name */
        public var type:UBYTE;     /* Instrument type (always 0) */
        public var numsmp:UWORD;   /* Number of samples in instrument */
        public var ssize:ULONG;

	public function new() {
	}
}



class XMPATCHHEADER {
        public var what:Array<UBYTE>;		//[XMNOTECNT];  /*  Sample number for all notes */
        public var volenv:Array<UWORD>;	//[XMENVCNT]; /*  Points for volume envelope */
        public var panenv:Array<UWORD>;	//[XMENVCNT]; /*  Points for panning envelope */
	public var vol_env:Envelope;
	public var pan_env:Envelope;
        //public var volpts:UBYTE;      /*  Number of volume points */
        //public var panpts:UBYTE;      /*  Number of panning points */
        //public var volsus:UBYTE;      /*  Volume sustain point */
        //public var volbeg:UBYTE;      /*  Volume loop start point */
        //public var volend:UBYTE;      /*  Volume loop end point */
        //public var pansus:UBYTE;      /*  Panning sustain point */
        //public var panbeg:UBYTE;      /*  Panning loop start point */
        //public var panend:UBYTE;      /*  Panning loop end point */
        //public var volflg:UBYTE;      /*  Volume type: bit 0: On; 1: Sustain; 2: Loop */
        //public var panflg:UBYTE;      /*  Panning type: bit 0: On; 1: Sustain; 2: Loop */
        public var vibflg:UBYTE;      /*  Vibrato type */
        public var vibsweep:UBYTE;    /*  Vibrato sweep */
        public var vibdepth:UBYTE;    /*  Vibrato depth */
        public var vibrate:UBYTE;     /*  Vibrato rate */
        public var volfade:UWORD;     /*  Volume fadeout */

	public function new() {
	   what=new Array();
	   volenv=new Array();
	   panenv=new Array();
	   vol_env=new Envelope();
	   pan_env=new Envelope();
	}
}


class XMWAVHEADER {
        public var length:ULONG;         /* Sample length */
        public var loopstart:ULONG;      /* Sample loop start */
        public var looplength:ULONG;     /* Sample loop length */
        public var volume:UBYTE;         /* Volume  */
        public var finetune:SBYTE;       /* Finetune (signed byte -128..+127) */
        public var type:UBYTE;           /* Loop type */
        public var panning:UBYTE;        /* Panning (0-255) */
        public var relnote:SBYTE;        /* Relative note number (signed byte) */
        public var reserved:UBYTE;
        public var samplename:String; 	//[22]; /* Sample name */
        public var vibtype:UBYTE;        /* Vibrato type */
        public var vibsweep:UBYTE;       /* Vibrato sweep */
        public var vibdepth:UBYTE;       /* Vibrato depth */
        public var vibrate:UBYTE;        /* Vibrato rate */
	public function new() {
	}
}


class XMPATHEADER {
        public var size:ULONG;     /* Pattern header length  */
        public var packing:UBYTE;  /* Packing type (always 0) */
        public var numrows:UWORD;  /* Number of rows in pattern (1..256) */
        public var packsize:SWORD; /* Packed patterndata size */

	public function new() {
	}
}


class XMNOTE {
        public var note:UBYTE;
	public var ins:UBYTE;
	public var vol:UBYTE;
	public var eff:UBYTE;
	public var dat:UBYTE;

	public function clear() {
	   note=ins=vol=eff=dat=0;
	}
	public function new() {
	}
}

class Load_xm extends MLoader {

   public static var XMENVCNT=(12*2);
   public static var XMNOTECNT=(8*Defs.OCTAVE);


   /*========== Loader variables */

   static  var xmpat:Array<XMNOTE>=null;

   static  var mh:XMHEADER=null;

   /* increment unit for sample array reallocation */
   static var XM_SMPINCR=64;
   static var nextwav:Array<ULONG>;
   static var wh:Array<XMWAVHEADER>;
   //static var s:XMWAVHEADER=null;
   static var si:Int=0;

   /*========== Loader code */

   override public function Test():Bool {
	var id:ByteArray; // 38

        if((id=MMio._mm_read_ByteArray(38,MLoader.modreader))==null) return false;
	var prevpos=id.position;
	if (id.readUTFBytes(17)!="Extended Module: ") return false;
	id.position=prevpos;
        if(id[37]==0x1a) return true;
        return false;
   }

   override public function Init():Bool {
	mh=new XMHEADER();
	return (mh!=null);
   }




   override public function Cleanup():Void {
	mh=null;
   }

   static function XM_ReadNote(n:XMNOTE):Int {
	var cmp:UBYTE;
	var result:UBYTE=1;

	n.clear();
        cmp=MMio._mm_read_UBYTE(MLoader.modreader);

        if(cmp&0x80!=0) {
                if(cmp&1!=0)  { result++;n.note = MMio._mm_read_UBYTE(MLoader.modreader); }
                if(cmp&2!=0)  { result++;n.ins  = MMio._mm_read_UBYTE(MLoader.modreader); }
                if(cmp&4!=0)  { result++;n.vol  = MMio._mm_read_UBYTE(MLoader.modreader); }
                if(cmp&8!=0)  { result++;n.eff  = MMio._mm_read_UBYTE(MLoader.modreader); }
                if(cmp&16!=0) { result++;n.dat  = MMio._mm_read_UBYTE(MLoader.modreader); }
        } else {
                n.note = cmp;
                n.ins  = MMio._mm_read_UBYTE(MLoader.modreader);
                n.vol  = MMio._mm_read_UBYTE(MLoader.modreader);
                n.eff  = MMio._mm_read_UBYTE(MLoader.modreader);
                n.dat  = MMio._mm_read_UBYTE(MLoader.modreader);
                result += 4;
        }
        return result;
   }




   static function XM_Convert(xmtracka:Array<XMNOTE>,xmtracki:Int,rows:UWORD):MEMPTR {
	var t:Int;
	var note:UBYTE;
	var ins:UBYTE;
	var vol:UBYTE;
	var eff:UBYTE;
	var dat:UBYTE;

        MUnitrk.UniReset();
        for(t in 0 ... rows) {
		var xmtrack=xmtracka[xmtracki];
                note = xmtrack.note;
                ins  = xmtrack.ins;
                vol  = xmtrack.vol;
                eff  = xmtrack.eff;
                dat  = xmtrack.dat;

                if(note!=0) {
                        if(note>XMNOTECNT)
                                MLutils.UniEffect(Defs.UNI_KEYFADE,0);
                        else
                                MLutils.UniNote(note-1);
                }
                if(ins!=0) MLutils.UniInstrument(ins-1);

                switch(vol>>4) {
                        case 0x6: /* volslide down */
                                if(vol&0xf!=0) MLutils.UniEffect(Defs.UNI_XMEFFECTA,vol&0xf);
                                //break;
                        case 0x7: /* volslide up */
                                if(vol&0xf!=0) MLutils.UniEffect(Defs.UNI_XMEFFECTA,vol<<4);
                                //break;

                                /* volume-row fine volume slide is compatible with protracker
                                   EBx and EAx effects i.e. a zero nibble means DO NOT SLIDE, as
                                   opposed to 'take the last sliding value'. */
                        case 0x8: /* finevol down */
                                MLutils.UniPTEffect(0xe,0xb0|(vol&0xf));
                                //break;
                        case 0x9: /* finevol up */
                                MLutils.UniPTEffect(0xe,0xa0|(vol&0xf));
                                //break;
                        case 0xa: /* set vibrato speed */
                                MLutils.UniEffect(Defs.UNI_XMEFFECT4,vol<<4);
                                //break;
                        case 0xb: /* vibrato */
                                MLutils.UniEffect(Defs.UNI_XMEFFECT4,vol&0xf);
                                //break;
                        case 0xc: /* set panning */
                                MLutils.UniPTEffect(0x8,vol<<4);
                                //break;
                        case 0xd: /* panning slide left (only slide when data not zero) */
                                if(vol&0xf!=0) MLutils.UniEffect(Defs.UNI_XMEFFECTP,vol&0xf);
                                //break;
                        case 0xe: /* panning slide right (only slide when data not zero) */
                                if(vol&0xf!=0) MLutils.UniEffect(Defs.UNI_XMEFFECTP,vol<<4);
                                //break;
                        case 0xf: /* tone porta */
                                MLutils.UniPTEffect(0x3,vol<<4);
                                //break;
                        default:
                                if((vol>=0x10)&&(vol<=0x50))
                                        MLutils.UniPTEffect(0xc,vol-0x10);
                }

                switch(eff) {
                        case 0x4:
                                MLutils.UniEffect(Defs.UNI_XMEFFECT4,dat);
                                //break;
                        case 0x6:
                                MLutils.UniEffect(Defs.UNI_XMEFFECT6,dat);
                                //break;
                        case 0xa:
                                MLutils.UniEffect(Defs.UNI_XMEFFECTA,dat);
                                //break;
                        case 0xe: /* Extended effects */
                                switch(dat>>4) {
                                        case 0x1: /* XM fine porta up */
                                                MLutils.UniEffect(Defs.UNI_XMEFFECTE1,dat&0xf);
                                                //break;
                                        case 0x2: /* XM fine porta down */
                                                MLutils.UniEffect(Defs.UNI_XMEFFECTE2,dat&0xf);
                                                //break;
                                        case 0xa: /* XM fine volume up */
                                                MLutils.UniEffect(Defs.UNI_XMEFFECTEA,dat&0xf);
                                                //break;
                                        case 0xb: /* XM fine volume down */
                                                MLutils.UniEffect(Defs.UNI_XMEFFECTEB,dat&0xf);
                                                //break;
                                        default:
                                                MLutils.UniPTEffect(eff,dat);
                                }
                                //break;
                        case 16: //'G'-55: /* G - set global volume */
                                MLutils.UniEffect(Defs.UNI_XMEFFECTG,dat>64?128:dat<<1);
                                //break;
                        case 17: //'H'-55: /* H - global volume slide */
                                MLutils.UniEffect(Defs.UNI_XMEFFECTH,dat);
                                //break;
                        case 20: //'K'-55: /* K - keyOff and KeyFade */
                                MLutils.UniEffect(Defs.UNI_KEYFADE,dat);
                                //break;
                        case 21: //'L'-55: /* L - set envelope position */
                                MLutils.UniEffect(Defs.UNI_XMEFFECTL,dat);
                                //break;
                        case 25: //'P'-55: /* P - panning slide */
                                MLutils.UniEffect(Defs.UNI_XMEFFECTP,dat);
                                //break;
                        case 27: //'R'-55: /* R - multi retrig note */
                                MLutils.UniEffect(Defs.UNI_S3MEFFECTQ,dat);
                                //break;
                        case 29: //'T'-55: /* T - Tremor */
                                MLutils.UniEffect(Defs.UNI_S3MEFFECTI,dat);
                                //break;
                        case 33: // 'X'-55:
                                switch(dat>>4) {
                                        case 1: /* X1 - Extra Fine Porta up */
                                                MLutils.UniEffect(Defs.UNI_XMEFFECTX1,dat&0xf);
                                                //break;
                                        case 2: /* X2 - Extra Fine Porta down */
                                                MLutils.UniEffect(Defs.UNI_XMEFFECTX2,dat&0xf);
                                                //break;
                                }
                                //break;
                        default:
                                if(eff<=0xf) {
                                        /* the pattern jump destination is written in decimal,
                                           but it seems some poor tracker software writes them
                                           in hexadecimal... (sigh) */
                                        if (eff==0xd)
                                                /* don't change anything if we're sure it's in hexa */
                                                if ((((dat&0xf0)>>4)<=9)&&((dat&0xf)<=9))
                                                        /* otherwise, convert from dec to hex */
                                                        dat=(((dat&0xf0)>>4)*10)+(dat&0xf);
                                        MLutils.UniPTEffect(eff,dat);
                                }
                                //break;
                }
                MUnitrk.UniNewline();
                xmtracki++;
        }
        return MUnitrk.UniDup();
   }




   static function LoadPatterns(dummypat:Bool):Bool {
	var t:Int;
	var u:Int;
	var v:Int;
	var numtrk:Int;

        if(!MLoader.AllocTracks()) return false;
        if(!MLoader.AllocPatterns()) return false;

        numtrk=0;
        for(t in 0 ... mh.numpat) {
                var ph=new XMPATHEADER();

                ph.size     =MMio._mm_read_I_ULONG(MLoader.modreader);
                if (ph.size<(mh.version==0x0102?8:9)) {
                        MMio._mm_errno=Defs.MMERR_LOADING_PATTERN;
                        return false;
                }
                ph.packing  =MMio._mm_read_UBYTE(MLoader.modreader);
                if(ph.packing!=0) {
                        MMio._mm_errno=Defs.MMERR_LOADING_PATTERN;
                        return false;
                }
                if(mh.version==0x0102)
                        ph.numrows  =MMio._mm_read_UBYTE(MLoader.modreader)+1;
                else
                        ph.numrows  =MMio._mm_read_I_UWORD(MLoader.modreader);
                ph.packsize =MMio._mm_read_I_UWORD(MLoader.modreader);

                ph.size-=(mh.version==0x0102?8:9);
                if(ph.size!=0)
                        MMio._mm_fseek(MLoader.modreader,ph.size,MMio.SEEK_CUR);

                MLoader.of.pattrows[t]=ph.numrows;
                if(ph.numrows!=0) {
			xmpat=new Array<XMNOTE>();
			for (pati in 0 ... ph.numrows*MLoader.of.numchn) xmpat[pati]=new XMNOTE();
			if (xmpat==null) return false;
                        //if(!(xmpat=(XMNOTE*)_mm_calloc(ph.numrows*MLoader.of.numchn,sizeof(XMNOTE))))
                        //        return 0;

                        /* when packsize is 0, don't try to load a pattern.. it's empty. */
                        if(ph.packsize!=0) 
                                for(u in 0 ... ph.numrows) 
                                        for(v in 0 ... MLoader.of.numchn) {
                                                if(ph.packsize==0) break;	// ???

                                                ph.packsize-=XM_ReadNote(xmpat[(v*ph.numrows)+u]);
                                                if(ph.packsize<0) {
                                                        xmpat=null;
                                                        MMio._mm_errno=Defs.MMERR_LOADING_PATTERN;
                                                        return false;
                                                }
                                        }

                        if(ph.packsize!=0) {
                                MMio._mm_fseek(MLoader.modreader,ph.packsize,MMio.SEEK_CUR);
                        }

                        if(MMio._mm_eof(MLoader.modreader)) {
				xmpat=null;
                                MMio._mm_errno=Defs.MMERR_LOADING_PATTERN;
                                return false;
                        }

                        for(v in 0 ... MLoader.of.numchn)
                                MLoader.of.tracks[numtrk++]=XM_Convert(xmpat,v*ph.numrows,ph.numrows);

			xmpat=null;
                } else {
                        for(v in 0 ... MLoader.of.numchn)
                                MLoader.of.tracks[numtrk++]=XM_Convert(null,0,ph.numrows);
                }
        }
	t=mh.numpat;

        if(dummypat) {
                MLoader.of.pattrows[t]=64;
		xmpat=new Array<XMNOTE>();
		if (xmpat==null) return false;
                //if(!(xmpat=(XMNOTE*)_mm_calloc(64*MLoader.of.numchn,sizeof(XMNOTE)))) return 0;
                for(v in 0 ... MLoader.of.numchn)
                        MLoader.of.tracks[numtrk++]=XM_Convert(xmpat,v*64,64);
		xmpat=null;
        }

        return true;
   }




   static function FixEnvelope(e:Envelope):Void {
		var u:Int;
		var old:Int;
		var tmp:Int;
		//var prev:ENVPT;
		var cur=0;
		var prev:Int;
		var arr=e.env;
		var pts=e.pts;

                /* Some broken XM editing program will only save the low byte
                   of the position value. Try to compensate by adding the
                   missing high byte. */

                prev = cur++;
                old = arr[prev].pos;

		for (u in 1 ... pts) {	// for: prev++, cur++
                        if (arr[cur].pos < arr[prev].pos) {
                                if (arr[cur].pos < 0x100) {
                                        if (arr[cur].pos > old)     /* same hex century */
                                                        tmp = arr[cur].pos + (arr[prev].pos - old);
                                        else
                                                        tmp = arr[cur].pos | ((arr[prev].pos + 0x100) & 0xff00);
                                        old = arr[cur].pos;
                                        arr[cur].pos = tmp;
                                } else {
                                        old = arr[cur].pos;
                                }
                        } else
                                old = arr[cur].pos;
		// for loop:
		prev++; cur++;
                }
   }



   static function XM_ProcessEnvelope(e:Envelope,pthe:Envelope,envarr:Array<UWORD>) {
                                for (u in 0 ... (XMENVCNT >> 1)) {
                                        e.env[u].pos = envarr[u << 1];
                                        e.env[u].val = envarr[(u << 1)+ 1];		// ???
                                }

                                if (pthe.flg&1!=0) e.flg|=Defs.EF_ON;
                                if (pthe.flg&2!=0) e.flg|=Defs.EF_SUSTAIN;
                                if (pthe.flg&4!=0) e.flg|=Defs.EF_LOOP;
				//e.susbeg=e.susend=pthe.sus;	???
				e.beg=pthe.beg;
				e.end=pthe.end;
				e.pts=pthe.pts;

                                /* scale envelope */
                                for (p in 0 ... Std.int(XMENVCNT/2))
                                        e.env[p].val<<=2;

                                if ((e.flg&Defs.EF_ON)!=0&&(e.pts<2))
                                        e.flg&=~Defs.EF_ON;

   }




   static function LoadInstruments():Bool {
	var t:Int;
	var u:Int;
	//var d:INSTRUMENT;
	var next:ULONG=0;
	var wavcnt:UWORD=0;
	var di=0;

        if(!MLoader.AllocInstruments()) return false;
        //d=MLoader.of.instruments;
        for(t in 0 ... MLoader.of.numins) {	// for: d++
                var ih=new XMINSTHEADER();
                var headend:Int;	// long
		var d=MLoader.of.instruments[di];

                //memset(d->samplenumber,0xff,INSTNOTES*sizeof(UWORD));
		for (di in 0 ... Defs.INSTNOTES) d.samplenumber[di]=0xffff;

                /* read instrument header */
                headend     = MMio._mm_ftell(MLoader.modreader);
                ih.size     = MMio._mm_read_I_ULONG(MLoader.modreader);
                headend    += ih.size;
                ih.name=MMio._mm_read_string(22, MLoader.modreader);
                ih.type     = MMio._mm_read_UBYTE(MLoader.modreader);
                ih.numsmp   = MMio._mm_read_I_UWORD(MLoader.modreader);

                d.insname  = MLoader.DupStr(ih.name,22,true);

                if(ih.size>29) {
                        ih.ssize    = MMio._mm_read_I_ULONG(MLoader.modreader);
                        if((/*(SWORD)*/ ih.numsmp>0)&&(ih.numsmp<=XMNOTECNT)) {
                                var pth=new XMPATCHHEADER();
                                var p:Int;
				pth.what=MMio._mm_read_UBYTES(XMNOTECNT,MLoader.modreader);
                                pth.volenv=MMio._mm_read_I_UWORDS (XMENVCNT, MLoader.modreader);
                                pth.panenv=MMio._mm_read_I_UWORDS (XMENVCNT, MLoader.modreader);
                                pth.vol_env.pts      =  MMio._mm_read_UBYTE(MLoader.modreader);
                                pth.pan_env.pts      =  MMio._mm_read_UBYTE(MLoader.modreader);
                                pth.vol_env.susbeg=pth.vol_env.susend=MMio._mm_read_UBYTE(MLoader.modreader);
                                pth.vol_env.beg      =  MMio._mm_read_UBYTE(MLoader.modreader);
                                pth.vol_env.end      =  MMio._mm_read_UBYTE(MLoader.modreader);
                                pth.pan_env.susbeg=pth.pan_env.susend=MMio._mm_read_UBYTE(MLoader.modreader);
                                pth.pan_env.beg      =  MMio._mm_read_UBYTE(MLoader.modreader);
                                pth.pan_env.end      =  MMio._mm_read_UBYTE(MLoader.modreader);
                                pth.vol_env.flg      =  MMio._mm_read_UBYTE(MLoader.modreader);
                                pth.pan_env.flg      =  MMio._mm_read_UBYTE(MLoader.modreader);
                                pth.vibflg      =  MMio._mm_read_UBYTE(MLoader.modreader);
                                pth.vibsweep    =  MMio._mm_read_UBYTE(MLoader.modreader);
                                pth.vibdepth    =  MMio._mm_read_UBYTE(MLoader.modreader);
                                pth.vibrate     =  MMio._mm_read_UBYTE(MLoader.modreader);
                                pth.volfade     =  MMio._mm_read_I_UWORD(MLoader.modreader);

                                /* read the remainder of the header
                                   (2 bytes for 1.03, 22 for 1.04) */
                                //for(u=headend-_mm_ftell(MLoader.modreader);u;u--) _mm_read_UBYTE(MLoader.modreader);
				u=headend-MMio._mm_ftell(MLoader.modreader); while(u!=0) { MMio._mm_read_UBYTE(MLoader.modreader); u--; }

                                /* we can't trust the envelope point count here, as some
                                   modules have incorrect values (K_OSPACE.XM reports 32 volume
                                   points, for example). */
                                if(pth.vol_env.pts>XMENVCNT/2) pth.vol_env.pts=Std.int(XMENVCNT/2);
                                if(pth.pan_env.pts>XMENVCNT/2) pth.pan_env.pts=Std.int(XMENVCNT/2);

                                if((MMio._mm_eof(MLoader.modreader))||(pth.vol_env.pts>XMENVCNT/2)||(pth.pan_env.pts>XMENVCNT/2)) {
                                        nextwav=null;
                                        wh=null;
                                        MMio._mm_errno = Defs.MMERR_LOADING_SAMPLEINFO;
                                        return false;
                                }

                                for(u in 0 ... XMNOTECNT)
                                        d.samplenumber[u]=pth.what[u]+MLoader.of.numsmp;
                                d.volfade = pth.volfade;

                                XM_ProcessEnvelope(d.vol_env,pth.vol_env,pth.volenv);
                                XM_ProcessEnvelope(d.pan_env,pth.pan_env,pth.panenv);

                                if (d.vol_env.flg & Defs.EF_ON!=0)
                                        FixEnvelope(d.vol_env);
                                if (d.pan_env.flg & Defs.EF_ON!=0)
                                        FixEnvelope(d.pan_env);

                                /* Samples are stored outside the instrument struct now, so we
                                   have to load them all into a temp area, count the MLoader.of.numsmp
                                   along the way and then do an AllocSamples() and move
                                   everything over */
                                if(mh.version>0x0103) next = 0;
                                for(u in 0 ... ih.numsmp) {	// for: s++
                                        /* Allocate more room for sample information if necessary */
                                        if(MLoader.of.numsmp+u==wavcnt) {
                                                wavcnt+=XM_SMPINCR;
						if (wh==null) wh=new Array();
						if (nextwav==null) nextwav=new Array();
						for (ri in 0 ... wavcnt)
							if (wh[ri]==null) wh[ri]=new XMWAVHEADER();
						/*
                                                if(!(nextwav=realloc(nextwav,wavcnt*sizeof(ULONG)))){
                                                        if(wh) { free(wh);wh=NULL; }
                                                        _mm_errno = Defs.MMERR_OUT_OF_MEMORY;
                                                        return 0;
                                                }
                                                if(!(wh=realloc(wh,wavcnt*sizeof(XMWAVHEADER)))) {
                                                        free(nextwav);nextwav=NULL;
                                                        _mm_errno = Defs.MMERR_OUT_OF_MEMORY;
                                                        return 0;
                                                }
						*/
                                                //s=wh+(wavcnt-XM_SMPINCR);
						si=wavcnt-XM_SMPINCR;
                                        }
					var s=wh[si];
                                        s.length       =MMio._mm_read_I_ULONG (MLoader.modreader);
                                        s.loopstart    =MMio._mm_read_I_ULONG (MLoader.modreader);
                                        s.looplength   =MMio._mm_read_I_ULONG (MLoader.modreader);
                                        s.volume       =MMio._mm_read_UBYTE (MLoader.modreader);
                                        s.finetune     =MMio._mm_read_SBYTE (MLoader.modreader);
                                        s.type         =MMio._mm_read_UBYTE (MLoader.modreader);
                                        s.panning      =MMio._mm_read_UBYTE (MLoader.modreader);
                                        s.relnote      =MMio._mm_read_SBYTE (MLoader.modreader);
                                        s.vibtype      = pth.vibflg;
                                        s.vibsweep     = pth.vibsweep;
                                        s.vibdepth     = pth.vibdepth*4;
                                        s.vibrate      = pth.vibrate;
                                        s.reserved     =MMio._mm_read_UBYTE (MLoader.modreader);
                                        s.samplename=MMio._mm_read_string(22, MLoader.modreader);

                                        nextwav[MLoader.of.numsmp+u]=next;
                                        next+=s.length;

                                        if(MMio._mm_eof(MLoader.modreader)) {
						nextwav=null; wh=null;
                                                MMio._mm_errno = Defs.MMERR_LOADING_SAMPLEINFO;
                                                return false;
                                        }
				si++; // for loop
                                }

                                if(mh.version>0x0103) {
                                        for(u in 0 ... ih.numsmp)
                                                nextwav[MLoader.of.numsmp++]+=MMio._mm_ftell(MLoader.modreader);
                                        MMio._mm_fseek(MLoader.modreader,next,MMio.SEEK_CUR);
                                } else
                                        MLoader.of.numsmp+=ih.numsmp;
                        } else {
                                /* read the remainder of the header */
				u=headend-MMio._mm_ftell(MLoader.modreader);
				while(u!=0) { MMio._mm_read_UBYTE(MLoader.modreader); u--; }
                                //for(... headend-_mm_ftell(MLoader.modreader);u;u--) _mm_read_UBYTE(MLoader.modreader);

                                if(MMio._mm_eof(MLoader.modreader)) {
                                        //free(nextwav);free(wh);
                                        nextwav=null; wh=null;
                                        MMio._mm_errno = Defs.MMERR_LOADING_SAMPLEINFO;
                                        return false;
                                }
                        }
                }
	di++; // for loop
        }

        /* sanity check */
        if(MLoader.of.numsmp==0) {
		nextwav=null; wh=null;
                MMio._mm_errno = Defs.MMERR_LOADING_SAMPLEINFO;
                return false;
        }

        return true;
   }




  override public function Load(curious:Bool):Bool {
	var d:INSTRUMENT;
	var q:SAMPLE;
	var t:Int;
	var u:Int;
	var dummypat=false;
	var tracker:String; // 21
	var modtype:String; // 60

        /* try to read module header */
        mh.id=MMio._mm_read_string(17,MLoader.modreader);
        mh.songname=MMio._mm_read_string(21,MLoader.modreader);
        mh.trackername=MMio._mm_read_string(20,MLoader.modreader);
        mh.version     =MMio._mm_read_I_UWORD(MLoader.modreader);
        if((mh.version<0x102)||(mh.version>0x104)) {
                MMio._mm_errno=Defs.MMERR_NOT_A_MODULE;
                return false;
        }
        mh.headersize  =MMio._mm_read_I_ULONG(MLoader.modreader);
        mh.songlength  =MMio._mm_read_I_UWORD(MLoader.modreader);
        mh.restart     =MMio._mm_read_I_UWORD(MLoader.modreader);
        mh.numchn      =MMio._mm_read_I_UWORD(MLoader.modreader);
        mh.numpat      =MMio._mm_read_I_UWORD(MLoader.modreader);
        mh.numins      =MMio._mm_read_I_UWORD(MLoader.modreader);
        mh.flags       =MMio._mm_read_I_UWORD(MLoader.modreader);
        mh.tempo       =MMio._mm_read_I_UWORD(MLoader.modreader);
        mh.bpm         =MMio._mm_read_I_UWORD(MLoader.modreader);
        if(mh.bpm==0) {
                MMio._mm_errno=Defs.MMERR_NOT_A_MODULE;
                return false;
        }
	mh.orders=MMio._mm_read_UBYTES(256,MLoader.modreader);

        if(MMio._mm_eof(MLoader.modreader)) {
                MMio._mm_errno = Defs.MMERR_LOADING_HEADER;
                return false;
        }

        /* set module variables */
        MLoader.of.initspeed = mh.tempo;         
        MLoader.of.inittempo = mh.bpm;
        //strncpy(tracker,mh->trackername,20);tracker[20]=0;
        //for(t=20;(tracker[t]<=' ')&&(t>=0);t--) tracker[t]=0;
        
        /* some modules have the tracker name empty */
	/*
        if (!tracker[0])
                strcpy(tracker,"Unknown tracker");

        snprintf(modtype,60,"%s (XM format %d.%02d)",
                            tracker,mh->version>>8,mh->version&0xff);
	*/
        MLoader.of.modtype   = "XM";	//strdup(modtype);
        MLoader.of.numchn    = mh.numchn;
        MLoader.of.numpat    = mh.numpat;
        MLoader.of.numtrk    = MLoader.of.numpat*MLoader.of.numchn;   /* get number of channels */
        MLoader.of.songname  = MLoader.DupStr(mh.songname,20,true);
        MLoader.of.numpos    = mh.songlength;               /* copy the songlength */
        MLoader.of.reppos    = mh.restart<mh.songlength?mh.restart:0;
        MLoader.of.numins    = mh.numins;
        MLoader.of.flags    |= Defs.UF_XMPERIODS | Defs.UF_INST | Defs.UF_NOWRAP | Defs.UF_FT2QUIRKS |
                                   Defs.UF_PANNING;
        if(mh.flags&1!=0) MLoader.of.flags |= Defs.UF_LINEAR;
        MLoader.of.bpmlimit  = 32;

        //memset(MLoader.of.chanvol,64,MLoader.of.numchn);             /* store channel volumes */
	for (vi in 0...MLoader.of.numchn) MLoader.of.chanvol[vi]=64;

        if(!MLoader.AllocPositions(MLoader.of.numpos+1)) return false;
        for(t in 0 ... MLoader.of.numpos)
                MLoader.of.positions[t]=mh.orders[t];

        /* We have to check for any pattern numbers in the order list greater than
           the number of patterns total. If one or more is found, we set it equal to
           the pattern total and make a dummy pattern to workaround the problem */
        for(t in 0 ... MLoader.of.numpos) {
                if(MLoader.of.positions[t]>=MLoader.of.numpat) {
                        MLoader.of.positions[t]=MLoader.of.numpat;
                        dummypat=true;
                }
        }
        if(dummypat) {
                MLoader.of.numpat++;MLoader.of.numtrk+=MLoader.of.numchn;
        }

        if(mh.version<0x0104) {
                if(!LoadInstruments()) return false;
                if(!LoadPatterns(dummypat)) return false;
                for(t in 0 ... MLoader.of.numsmp)
                        nextwav[t]+=MMio._mm_ftell(MLoader.modreader);
        } else {
                if(!LoadPatterns(dummypat)) return false;
                if(!LoadInstruments()) return false;
        }

        if(!MLoader.AllocSamples()) {
		nextwav=null; wh=null;
		return false;
        }
        //s = wh;
	si=0;
	var qi=0;
        for(u in 0 ... MLoader.of.numsmp) {	// for: q++,s++
        	var q = MLoader.of.samples[qi];
                var s=wh[si];
                q.samplename   = MLoader.DupStr(s.samplename,22,true);
                q.length       = s.length;
                q.loopstart    = s.loopstart;
                q.loopend      = s.loopstart+s.looplength;
                q.volume       = s.volume;
                q.speed        = s.finetune+128;
                q.panning      = s.panning;
                q.seekpos      = nextwav[u];
                q.vibtype      = s.vibtype;
                q.vibsweep     = s.vibsweep;
                q.vibdepth     = s.vibdepth;
                q.vibrate      = s.vibrate;

                if(s.type & 0x10!=0) {
                        q.length    >>= 1;
                        q.loopstart >>= 1;
                        q.loopend   >>= 1;
                }

                q.flags|=Defs.SF_OWNPAN|Defs.SF_DELTA|Defs.SF_SIGNED;
                if(s.type&0x3!=0) q.flags|=Defs.SF_LOOP;
                if(s.type&0x2!=0) q.flags|=Defs.SF_BIDI;
                if(s.type&0x10!=0) q.flags|=Defs.SF_16BITS;
	qi++; si++; // for loop
        }

	si=0;
	var di=0;
        var s=wh;
        for(u in 0 ... MLoader.of.numins) {  // for: d++
        	var d=MLoader.of.instruments[di];
                for(t in 0 ... XMNOTECNT) {
                        if (d.samplenumber[t]>=MLoader.of.numsmp)
                                d.samplenote[t]=255;
                        else {
                                var note=t+s[d.samplenumber[t]].relnote;
                                d.samplenote[t]=(note<0)?0:note;
                        }
                }
	di++; // for loop
	}
	wh=null; nextwav=null;
        return true;
   }

   override public function LoadTitle():String {
	var s:String;

        MMio._mm_fseek(MLoader.modreader,17,MMio.SEEK_SET);
	s=MMio._mm_read_string(21, MLoader.modreader);
	if (s==null) return null;
        return(MLoader.DupStr(s,21,true));
   }

   public function new() {
	super();
        type="XM";
        version="XM (FastTracker 2)";
   }

}





