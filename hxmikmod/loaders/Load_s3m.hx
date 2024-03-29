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


/* header */

class S3MHEADER {
	public var songname:String;	//28
	public var t1a:UBYTE;
	public var type:UBYTE;
        //UBYTE unused1[2];
	public var ordnum:UWORD;
	public var insnum:UWORD;
	public var patnum:UWORD;
	public var flags:UWORD;
	public var tracker:UWORD;
	public var fileformat:UWORD;
	public var scrm:String; //4
	public var mastervol:UBYTE;
	public var initspeed:UBYTE;
	public var inittempo:UBYTE;
	public var mastermult:UBYTE;
	public var ultraclick:UBYTE;
	public var pantable:UBYTE;
        //UBYTE unused2[8];
	public var special:UWORD;
	public var channels:Array<UBYTE>;	// 32

	public function new() {
	   channels=new Array();
	}
}



/* sample information */
class S3MSAMPLE {
	public var type:UBYTE;
	public var filename:String;	// 12
	public var memsegh:UBYTE;
	public var memsegl:UWORD;
	public var length:ULONG;
	public var loopbeg:ULONG;
	public var loopend:ULONG;
	public var volume:UBYTE;
	public var dsk:UBYTE;
	public var pack:UBYTE;
	public var flags:UBYTE;
	public var c2spd:ULONG;
        //UBYTE unused[12];
	public var sampname:String;	// 28
	public var scrs:String;		// 4

	public function new() {
	}
}

class S3MNOTE {
	public var note:UBYTE;
	public var ins:UBYTE;
	public var vol:UBYTE;
	public var cmd:UBYTE;
	public var inf:UBYTE;

	public function new() {
	   note=ins=vol=cmd=inf=255;
	}
}


class Load_s3m extends MLoader {

   /*========== Loader variables */

   static var s3mbuf:Array<S3MNOTE>; /* pointer to a complete S3M pattern */
   static var mh:S3MHEADER=null;
   static var paraptr:Array<UWORD>=null; /* parapointer array (see S3M docs) */
   static var tracker:Int; 	//unsigned /* tracker id */

   /* tracker identifiers */
   inline static var NUMTRACKERS=4;

   static var S3M_Version=[
        "Screamtracker x.xx",
        "Imago Orpheus x.xx (S3M format)",
        "Impulse Tracker x.xx (S3M format)",
        "Unknown tracker x.xx (S3M format)",
        "Impulse Tracker 2.14p3 (S3M format)",
        "Impulse Tracker 2.14p4 (S3M format)"
   ];


   /*========== Loader code */

   override public function Test():Bool {
	var id:String;
        MMio._mm_fseek(MLoader.modreader,0x2c,MMio.SEEK_SET);
        if((id=MMio._mm_read_string(4,MLoader.modreader))==null) return false;
	return (id=="SCRM");
   }

   override public function Init():Bool {
	if ((s3mbuf=new Array())==null) return false;
	if ((mh=new S3MHEADER())==null) return false;
	if ((MLutils.poslookup=new Array())==null) return false;
	for (i in 0 ... 256) MLutils.poslookup[i]=-1;
        return true;
   }

   override public function Cleanup():Void {
	s3mbuf=null;
	paraptr=null;
	MLutils.poslookup=null;
	mh=null;
	MLutils.origpositions=null;
   }



/* Because so many s3m files have 16 channels as the set number used, but really
   only use far less (usually 8 to 12 still), I had to make this function, which
   determines the number of channels that are actually USED by a pattern.

   For every channel that's used, it sets the appropriate array entry of the
   global variable 'remap'

   NOTE: You must first seek to the file location of the pattern before calling
         this procedure.

   Returns 1 on fail.                                                         */

   static function S3M_GetNumChannels():Bool {
	var row=0;
	var flag:Int;
	var ch:Int;

        while(row<64) {
                flag=MMio._mm_read_UBYTE(MLoader.modreader);

                if(MMio._mm_eof(MLoader.modreader)) {
                        MMio._mm_errno = Defs.MMERR_LOADING_PATTERN;
                        return true;
                }

                if(flag!=0) {
                        ch=flag&31;
                        if(mh.channels[ch]<32) MLutils.remap[ch] = 0;
                        if(flag&32!=0) { MMio._mm_read_UBYTE(MLoader.modreader); MMio._mm_read_UBYTE(MLoader.modreader); }
                        if(flag&64!=0) MMio._mm_read_UBYTE(MLoader.modreader);
                        if(flag&128!=0){ MMio._mm_read_UBYTE(MLoader.modreader); MMio._mm_read_UBYTE(MLoader.modreader); }
                } else row++;
        }
        return false;
   }    


   static function S3M_ReadPattern():Bool {
	var row=0;
	var flag:Int;
	var ch:Int;
	var n:S3MNOTE;
	var dummy=new S3MNOTE();

        /* clear pattern data */
	for (i in 0 ... 32*64) s3mbuf[i]=new S3MNOTE();
        //memset(s3mbuf,255,32*64*sizeof(S3MNOTE));

        while(row<64) {
                flag=MMio._mm_read_UBYTE(MLoader.modreader);

                if(MMio._mm_eof(MLoader.modreader)) {
                        MMio._mm_errno = Defs.MMERR_LOADING_PATTERN;
                        return false;
                }

                if(flag!=0) {
                        ch=MLutils.remap[flag&31];

                        if(ch!=-1)
                                n=s3mbuf[(64*ch)+row];	// ptr
                        else
                                n=dummy;		// ptr

                        if(flag&32!=0) {
                                n.note=MMio._mm_read_UBYTE(MLoader.modreader);
                                n.ins=MMio._mm_read_UBYTE(MLoader.modreader);
                        }
                        if(flag&64!=0) {
                                n.vol=MMio._mm_read_UBYTE(MLoader.modreader);
                                if (n.vol>64) n.vol=64;
                        }
                        if(flag&128!=0) {
                                n.cmd=MMio._mm_read_UBYTE(MLoader.modreader);
                                n.inf=MMio._mm_read_UBYTE(MLoader.modreader);
                        }
                } else row++;
        }
        return true;
   }



   static function S3M_ConvertTrack(tr:Array<S3MNOTE>,tri:Int):MEMPTR {
	//var t:Int;

        MUnitrk.UniReset();
        for(t in 0 ... 64) {
                var note=tr[t+tri].note;
                var ins=tr[t+tri].ins;
                var vol=tr[t+tri].vol;

                if((ins!=0)&&(ins!=255)) MLutils.UniInstrument(ins-1);
                if(note!=255) {
                        if(note==254) {
                                MLutils.UniPTEffect(0xc,0);     /* note cut command */
                                vol=255;
                        } else
                                MLutils.UniNote(((note>>4)*Defs.OCTAVE)+(note&0xf)); /* normal note */
                }
                if(vol<255) MLutils.UniPTEffect(0xc,vol);

                MLutils.S3MIT_ProcessCmd(tr[t+tri].cmd,tr[t+tri].inf,
                        tracker == 1 ? Defs.S3MIT_OLDSTYLE | Defs.S3MIT_SCREAM : Defs.S3MIT_OLDSTYLE);
                MUnitrk.UniNewline();
        }
        return MUnitrk.UniDup();
   }


   override public function Load(curious:Bool):Bool {
	var t:Int;
	var u:Int;
	var track=0;
	var q:SAMPLE;
	var pan=new Array<UBYTE>(); // 32

        /* try to read module header */
        mh.songname=MMio._mm_read_string(28,MLoader.modreader);
        mh.t1a         =MMio._mm_read_UBYTE(MLoader.modreader);
        mh.type        =MMio._mm_read_UBYTE(MLoader.modreader);
        /*mh.unused1=*/MMio._mm_read_UBYTES(2,MLoader.modreader);
        mh.ordnum      =MMio._mm_read_I_UWORD(MLoader.modreader);
        mh.insnum      =MMio._mm_read_I_UWORD(MLoader.modreader);
        mh.patnum      =MMio._mm_read_I_UWORD(MLoader.modreader);
        mh.flags       =MMio._mm_read_I_UWORD(MLoader.modreader);
        mh.tracker     =MMio._mm_read_I_UWORD(MLoader.modreader);
        mh.fileformat  =MMio._mm_read_I_UWORD(MLoader.modreader);
        mh.scrm=MMio._mm_read_string(4,MLoader.modreader);
        mh.mastervol   =MMio._mm_read_UBYTE(MLoader.modreader);
        mh.initspeed   =MMio._mm_read_UBYTE(MLoader.modreader);
        mh.inittempo   =MMio._mm_read_UBYTE(MLoader.modreader);
        mh.mastermult  =MMio._mm_read_UBYTE(MLoader.modreader);
        mh.ultraclick  =MMio._mm_read_UBYTE(MLoader.modreader);
        mh.pantable    =MMio._mm_read_UBYTE(MLoader.modreader);
        /*mh.unused2=*/MMio._mm_read_UBYTES(8,MLoader.modreader);
        mh.special     =MMio._mm_read_I_UWORD(MLoader.modreader);
	mh.channels=MMio._mm_read_UBYTES(32,MLoader.modreader);

        if(MMio._mm_eof(MLoader.modreader)) {
                MMio._mm_errno = Defs.MMERR_LOADING_HEADER;
                return false;
        }

        /* then we can decide the module type */
        tracker=mh.tracker>>12;
        if((tracker==0)||(tracker>=NUMTRACKERS))
                tracker=NUMTRACKERS-1; /* unknown tracker */
        else {
                if(mh.tracker>=0x3217)
                        tracker=NUMTRACKERS+1; /* IT 2.14p4 */
                else if(mh.tracker>=0x3216)
                        tracker=NUMTRACKERS; /* IT 2.14p3 */
                else tracker--;
        }
        MLoader.of.modtype = S3M_Version[tracker];
        if(tracker<NUMTRACKERS) {
		var re=~/x/;
		re.replace(MLoader.of.modtype,String.fromCharCode((mh.tracker>>8)&0xf)+48);
		re.replace(MLoader.of.modtype,String.fromCharCode((mh.tracker>>4)&0xf)+48);
		re.replace(MLoader.of.modtype,String.fromCharCode((mh.tracker)&0xf)+48);
                //of.modtype[numeric[tracker]] = ((mh.tracker>>8) &0xf)+'0';
                //of.modtype[numeric[tracker]+2] = ((mh.tracker>>4)&0xf)+'0';
                //of.modtype[numeric[tracker]+3] = ((mh.tracker)&0xf)+'0';
        }
        /* set module variables */
        MLoader.of.songname    = MLoader.DupStr(mh.songname,28,false);
        MLoader.of.numpat      = mh.patnum;
        MLoader.of.reppos      = 0;
        MLoader.of.numins      = MLoader.of.numsmp = mh.insnum;
        MLoader.of.initspeed   = mh.initspeed;
        MLoader.of.inittempo   = mh.inittempo;
        MLoader.of.initvolume  = mh.mastervol<<1;
        MLoader.of.flags      |= Defs.UF_ARPMEM | Defs.UF_PANNING;
        if((mh.tracker==0x1300)||(mh.flags&64)!=0)
                MLoader.of.flags|=Defs.UF_S3MSLIDES;
        MLoader.of.bpmlimit    = 32;

        /* read the order data */
        if(!MLoader.AllocPositions(mh.ordnum)) return false;
	if ((MLutils.origpositions=new Array())==null) return false;
        //if(!(origpositions=_mm_calloc(mh->ordnum,sizeof(UWORD)))) return 0;

        for(t in 0 ... mh.ordnum) {
                MLutils.origpositions[t]=MMio._mm_read_UBYTE(MLoader.modreader);
                if((MLutils.origpositions[t]>=mh.patnum)&&(MLutils.origpositions[t]<254))
                        MLutils.origpositions[t]=255/*mh->patnum-1*/;
        }

        if(MMio._mm_eof(MLoader.modreader)) {
                MMio._mm_errno = Defs.MMERR_LOADING_HEADER;
                return false;
        }

        MLutils.poslookupcnt=mh.ordnum;
        MLutils.S3MIT_CreateOrders(curious);

        /* read the instrument+pattern parapointers */
        paraptr=MMio._mm_read_I_UWORDS(MLoader.of.numins+MLoader.of.numpat,MLoader.modreader);

        if(mh.pantable==252) {
                /* read the panning table (ST 3.2 addition.  See below for further
                   portions of channel panning [past reampper]). */
		pan=MMio._mm_read_UBYTES(32,MLoader.modreader);
        }

        if(MMio._mm_eof(MLoader.modreader)) {
                MMio._mm_errno = Defs.MMERR_LOADING_HEADER;
                return false;
        }

        /* load samples */
        if(!MLoader.AllocSamples()) return false;
        //q = MLoader.of.samples;
	var qi=0;
        for(t in 0 ... MLoader.of.numins) {
                var s=new S3MSAMPLE();
		var q=MLoader.of.samples[qi];

                /* seek to instrument position */
                MMio._mm_fseek(MLoader.modreader,paraptr[t]<<4,MMio.SEEK_SET);
                /* and load sample info */
                s.type      =MMio._mm_read_UBYTE(MLoader.modreader);
                s.filename=MMio._mm_read_string(12,MLoader.modreader);
                s.memsegh   =MMio._mm_read_UBYTE(MLoader.modreader);
                s.memsegl   =MMio._mm_read_I_UWORD(MLoader.modreader);
                s.length    =MMio._mm_read_I_ULONG(MLoader.modreader);
                s.loopbeg   =MMio._mm_read_I_ULONG(MLoader.modreader);
                s.loopend   =MMio._mm_read_I_ULONG(MLoader.modreader);
                s.volume    =MMio._mm_read_UBYTE(MLoader.modreader);
                s.dsk       =MMio._mm_read_UBYTE(MLoader.modreader);
                s.pack      =MMio._mm_read_UBYTE(MLoader.modreader);
                s.flags     =MMio._mm_read_UBYTE(MLoader.modreader);
                s.c2spd     =MMio._mm_read_I_ULONG(MLoader.modreader);
                /*s.unused=*/MMio._mm_read_UBYTES(12,MLoader.modreader);
                s.sampname=MMio._mm_read_string(28,MLoader.modreader);
                s.scrs=MMio._mm_read_string(4,MLoader.modreader);

                /* ScreamTracker imposes a 64000 bytes (not 64k !) limit */
                if (s.length > 64000)
                        s.length = 64000;

                if(MMio._mm_eof(MLoader.modreader)) {
                        MMio._mm_errno = Defs.MMERR_LOADING_SAMPLEINFO;
                        return false;
                }

                q.samplename = MLoader.DupStr(s.sampname,28,false);
                q.speed      = s.c2spd;
                q.length     = s.length;
                q.loopstart  = s.loopbeg;
                q.loopend    = s.loopend;
                q.volume     = s.volume;
                q.seekpos    = ((s.memsegh)<<16|s.memsegl)<<4;

                if(s.flags&1!=0) q.flags |= Defs.SF_LOOP;
                if(s.flags&4!=0) q.flags |= Defs.SF_16BITS;
                if(mh.fileformat==1) q.flags |= Defs.SF_SIGNED;

                /* don't load sample if it doesn't have the SCRS tag */
		if (s.scrs!="SCRS") q.length=0;

                qi++;
        }

        /* determine the number of channels actually used. */
        MLoader.of.numchn = 0;
	for (i in 0 ... 32) MLutils.remap[i]=-1; // 255?
        //memset(remap,-1,32*sizeof(UBYTE));
        for(t in 0 ... MLoader.of.numpat) {
                /* seek to pattern position (+2 skip pattern length) */
                MMio._mm_fseek(MLoader.modreader,((paraptr[MLoader.of.numins+t])<<4)+2,MMio.SEEK_SET);
                if(S3M_GetNumChannels()) return false;
        }

        /* build the remap array  */
	// ???????????????????????????????????????????????????????????????
        for(t in 0 ... 32)
                if(MLutils.remap[t]==0) 
                        MLutils.remap[t]=MLoader.of.numchn++;

        /* set panning positions after building remap chart! */
        for(t in 0 ... 32) 
                if((mh.channels[t]<32)&&(MLutils.remap[t]!=-1)) {
                        if(mh.channels[t]<8)
                                MLoader.of.panning[MLutils.remap[t]]=0x30;
                        else
                                MLoader.of.panning[MLutils.remap[t]]=0xc0;
                }
        if(mh.pantable==252)
                /* set panning positions according to panning table (new for st3.2) */
                for(t in 0 ... 32)
                        if((pan[t]&0x20!=0)&&(mh.channels[t]<32)&&(MLutils.remap[t]!=-1))
                                MLoader.of.panning[MLutils.remap[t]]=(pan[t]&0xf)<<4;

        /* load pattern info */
        MLoader.of.numtrk=MLoader.of.numpat*MLoader.of.numchn;
        if(!MLoader.AllocTracks()) return false;
        if(!MLoader.AllocPatterns()) return false;

        for(t in 0 ... MLoader.of.numpat) {
                /* seek to pattern position (+2 skip pattern length) */
                MMio._mm_fseek(MLoader.modreader,((paraptr[MLoader.of.numins+t])<<4)+2,MMio.SEEK_SET);
                if(!S3M_ReadPattern()) return false;
                for(u in 0 ... MLoader.of.numchn)
                        if(0==(MLoader.of.tracks[track++]=S3M_ConvertTrack(s3mbuf,u*64))) return false;
        }

        return true;
   }


   override public function LoadTitle():String {
	var s:String;
        MMio._mm_fseek(MLoader.modreader,0,MMio.SEEK_SET);
        // ... mm_read_UBYTES(s,28,MLoader.modreader)) return NULL;
	if ((s=MMio._mm_read_string(28,MLoader.modreader))==null) return null;
        return(MLoader.DupStr(s,28,false));
   }

   /*========== Loader information */

   public function new() {
	super();
	type="S3M";
	version="S3M (Scream Tracker 3)";
   }


}
