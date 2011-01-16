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
import hxmikmod.Defs;
import hxmikmod.SAMPLE;
import hxmikmod.VINFO;
import flash.utils.ByteArray;
import hxmikmod.event.TrackerEvent;
import hxmikmod.event.TrackerEventDispatcher;
import flash.utils.Endian;


// Index_t is the type used for mixing samples at
// variable frequencies. Int means fixed floating
// point and is probably a bit faster than Float.

typedef Index_t=Int;    //Float or Int;




class Virtch {
   inline static var MAXVOL_FACTOR=(1<<9);
   inline static var REVERBERATION=11000;
   inline static var TICKLSIZE=8192;
   
   inline static var FRACBITS=12;	// If Index_t=Float, set this to 0. Otherwise 12..13
					// e.g. Yuki Satellites won't work with 13 because of long samples
   public static var buffer_size:Int;


   // No unsigned type in haXe so...
   // returns true if (unsigned)a > (unsigned)b.
   // Using this for sample index comparison allows us one
   // additional FRACBIT which means better accuracy.

   inline static function greaterOrEqual(a:Int,b:Int):Bool {
	var result:Bool;
	if (a==b) result=true;
	else {
	  result=(a>b);
	  if (a<0 || b<0) {
	    if (a<0 && b<0) result=!result;		// both negative, invert result
	    else result=(a<0);				// one of them is negative, actually that's the greater one
	  }
	}
	return result;
   }


/*  

  // use this version if Index_t=Float

  inline static function greaterOrEqual(a:Float, b:Float):Bool {
	return (a>=b);
  }
  
*/


  // These convert between fractional sample index and
  // an integer. If Index_t=Float, it's just a matter of
  // Float->Int casting. For FFP it's a bit shift operation.

   inline public static function indexToSample(si:Index_t):Int {
	return FRACBITS==0 ? Std.int(si)<<2 : (cast(si)>>(FRACBITS-2))&0xfffffffc;	// FRACBITS-2 because it's a byte index to a Float buf
   }

   inline public static function indexToSampleF(si:Index_t):Float {
	return FRACBITS==0 ? si : si/(1<<FRACBITS);
   }

   inline public static function sampleToIndex(ti:Int):Index_t {
	return (ti<<FRACBITS);
   }


   inline public static var  MAXSAMPLEHANDLES=384;

   static var vinf:Array<VINFO>;
   static var vnf:VINFO;
   static var tickleft:Int;
   inline static var samplesthatfit=TICKLSIZE;
   static var vc_memory:Int;
   static var vc_softchn:Int;
   static var idxsize:Index_t;
   static var idxlpos:Index_t;
   static var idxlend:Index_t;
   static var vc_tickbuf=-1;
   static var vc_mode:Int;

   public static var Samples:Array<Int>;  // membuf index of sampledata start
   public static var SampleNames:Array<String>;	// jouko debug addition

   static var hqmix=true;  // clickbuf, rampvol ... not really used at the moment


   public static function VC_Init():Bool {
	Samples=new Array();
	for (i in 0 ... MAXSAMPLEHANDLES) Samples[i]=-1;
	SampleNames=new Array();
	if (vc_tickbuf==-1) {
		vc_tickbuf=Mem.alloc((TICKLSIZE+32)<<3);
	}
	//vc_memory=0; ???
	MDriver.md_mode |= Defs.DMODE_INTERP;
        vc_mode = MDriver.md_mode;
	return false;
   }


   // before loading a new song, free sample handles and memory

   public static function VC_Reset() {
	for (i in 0 ... MAXSAMPLEHANDLES) Samples[i]=-1;
	// Dump everything in the flash.Memory buffer after tickbuf
	// i.e. free samples. TODO a smarter way
	Mem.buf.length=(TICKLSIZE+32)<<3;
   }

   static function MixStereoNormal(srci:Int,desti:Int,index:Index_t,increment:Index_t,todo:Int):Index_t {
        var lvolsel = vnf.lvolsel/MAXVOL_FACTOR;
        var rvolsel = vnf.rvolsel/MAXVOL_FACTOR;
	var sample;

	desti<<=3;
	desti+=vc_tickbuf;
	for (i in 0 ... todo) {
		sample=Mem.getFloat(srci+indexToSample(index));
                index += increment;
		Mem.setFloat(desti,Mem.getFloat(desti)+lvolsel*sample); desti+=4;
		Mem.setFloat(desti,Mem.getFloat(desti)+rvolsel*sample); desti+=4;
	}
	return index;
   }

/*

   static function hqMixStereoNormal(srce:Array<SWORD>,dest:Array<Float>,desti:Int,index:Index_t,increment:Index_t,todo:Int):Index_t {
	Profiler.ENTER();		
	var sample=0;
	var desti2=desti<<1;
	for (i in 0 ... todo) {
		sample=srce[indexToSample(index)];
                index += increment;

                if(hqmix && vnf.rampvol!=0) {
                        dest[desti2++] += (
                          ( ( (vnf.oldlvol*vnf.rampvol) +
                              (vnf.lvolsel*(CLICK_BUFFER-vnf.rampvol))
                            ) * sample ) >> CLICK_SHIFT );
                        dest[desti2++] += (
                          ( ( (vnf.oldrvol*vnf.rampvol) +
                              (vnf.rvolsel*(CLICK_BUFFER-vnf.rampvol))
                            ) * sample ) >> CLICK_SHIFT );
                        vnf.rampvol--;
                } else
                  if (hqmix && vnf.click!=0) {
                        dest[desti2++] += (
                          ( ( (vnf.lvolsel*(CLICK_BUFFER-vnf.click)) *
                              sample ) + (vnf.lastvalL * vnf.click) )
                            >> CLICK_SHIFT );
                        dest[desti2++] += (
                          ( ( (vnf.rvolsel*(CLICK_BUFFER-vnf.click)) *
                              sample ) + (vnf.lastvalR * vnf.click) )
                            >> CLICK_SHIFT );
                        vnf.click--;
                } else { 
                        dest[desti2++] +=vnf.lvolsel*sample;
                        dest[desti2++] +=vnf.rvolsel*sample;
                }
        }
        vnf.lastvalL=vnf.lvolsel*sample;
        vnf.lastvalR=vnf.rvolsel*sample;
	Profiler.LEAVE();
        return index;
}


*/


   static function Mix32toFP(out:ByteArray,count:Int) {
	Profiler.ENTER();
	out.endian=Endian.LITTLE_ENDIAN;
	out.writeBytes(Mem.buf,vc_tickbuf,count<<3);
	Profiler.LEAVE();
   }





   static function AddChannel(todo:Int) {
	var end:Index_t;
	var done:Int;
	var s:Int;		// Mem.buf index
	var ptri=0;

        if((s=Samples[vnf.handle])==-1) {
                vnf.current=0; vnf.active=false;
                vnf.lastvalL = vnf.lastvalR = 0;
                return;
        }

	Profiler.ENTER();

	var reverse=(vnf.flags & Defs.SF_REVERSE)!=0;
	var loop=(vnf.flags & Defs.SF_LOOP)!=0;
	var bidi=(vnf.flags & Defs.SF_BIDI)!=0;

        /* update the 'current' index so the sample loops, or stops playing if it
           reached the end of the sample */
        while(todo>0) {
		var endpos:Index_t;

                if (reverse) {
                        /* The sample is playing in reverse */
                        if (loop && !greaterOrEqual(vnf.current,idxlpos)) {
                                /* the sample is looping and has reached the loopstart index */
                                if(bidi) {
                                        /* sample is doing bidirectional loops, so 'bounce' the
                                           current index against the idxlpos */
                                        vnf.current = idxlpos+(idxlpos-vnf.current);
                                        //vnf.flags &= ~Defs.SF_REVERSE;
					reverse=false;
                                        vnf.increment = -vnf.increment;
                                } else
                                        /* normal backwards looping, so set the current position to
                                           loopend index */
                                        vnf.current=idxlend-(idxlpos-vnf.current);
                        } else {
                                /* the sample is not looping, so check if it reached index 0 */
                                if(vnf.current <= 0 && vnf.current-vnf.increment>0) { // suspicious unsignedness fix
                                        /* playing index reached 0, so stop playing this sample */
                                        vnf.current=0; vnf.active=false;
                                        break;
                                }
                        }
                } else {
                        /* The sample is playing forward */
                        if (loop && (greaterOrEqual(vnf.current,idxlend))) {
                                /* the sample is looping, check the loopend index */
                                if (bidi) {
                                        /* sample is doing bidirectional loops, so 'bounce' the
                                           current index against the idxlend */
                                        //vnf.flags |= Defs.SF_REVERSE;
					reverse=true;
                                        vnf.increment = -vnf.increment;
                                        vnf.current = idxlend-(vnf.current-idxlend);
                                } else
                                        /* normal backwards looping, so set the current position
                                           to loopend index */
                                        vnf.current=idxlpos+(vnf.current-idxlend);
                        } else {
                                /* sample is not looping, so check if it reached the last
                                   position */
                                if(greaterOrEqual(vnf.current,idxsize)) {
                                        /* yes, so stop playing this sample */
                                        vnf.current=0; vnf.active=false;
                                        break;
                                }
                        }
                }

                end=reverse?(loop?idxlpos:0):(loop?idxlend:idxsize);
                /* if the sample is not blocked... */
                if (end==vnf.current || vnf.increment==0)
                        done=0;
                else {
                        //done=Std.int(Math.min((end-vnf.current)/vnf.increment+1,todo));
			var a=Std.int((end-vnf.current)/vnf.increment+1);
			//if (a<todo) done=a; else done=todo;
			if (greaterOrEqual(todo,a)) done=a; else done=todo;	// hmm ?
                        if (done<0) done=0;
                }

                if (done==0) {
                        vnf.active=false;
                        break;
                }

                endpos=vnf.current+done*vnf.increment;

                if (vnf.vol!=0 || vnf.rampvol!=0) {
			vnf.current=MixStereoNormal(s,ptri,vnf.current,vnf.increment,done);
    		} else  {
                        vnf.lastvalL = vnf.lastvalR = 0;
                        /* update sample position */
                        vnf.current=endpos;
                }

                todo -= done;
                ptri += done;
        }
	if (reverse) vnf.flags |= Defs.SF_REVERSE;
	else vnf.flags &= ~Defs.SF_REVERSE;

	Profiler.LEAVE();
   }





   static function clearTickBuf(len:Int) {
	Profiler.ENTER();
	Mem.clearFloat(vc_tickbuf,len<<3);
	Profiler.LEAVE();
   }


   public static function VC_SampleLoad(sload:SAMPLOAD,type:Int):SWORD {
        var s = sload.sample;
        var handle:Int;
	var t:ULONG;
	var length:ULONG;
	var loopstart:ULONG;
	var loopend:ULONG;

        if(type==Defs.MD_HARDWARE) return -1;

        /* Find empty slot to put sample address in */
	t=MAXSAMPLEHANDLES;
        for(handle in 0 ... MAXSAMPLEHANDLES)
                if(Samples[handle]==-1) { t=handle; break; }
	handle=t;
        if(handle==MAXSAMPLEHANDLES) {
                MMio._mm_errno = Defs.MMERR_OUT_OF_HANDLES;
                return -1;
        }
        
        /* Reality check for loop settings */
        if (s.loopend > s.length)
                s.loopend = s.length;
        if (s.loopstart >= s.loopend)
                s.flags &= ~Defs.SF_LOOP;

        length    = s.length;
        loopstart = s.loopstart;
        loopend   = s.loopend;

        SLoader.SL_SampleSigned(sload);
        SLoader.SL_Sample8to16(sload);

	/*
        if(!(Samples[handle]=(SWORD*)_mm_malloc((length+20)<<1))) {
                _mm_errno = MMERR_SAMPLE_TOO_BIG;
                return -1;
        }
	*/
	Samples[handle]=Mem.alloc((length+20)<<2);
	SampleNames[handle]=s.samplename;

        /* read sample into buffer */
        if (SLoader.SL_Load(Samples[handle],sload,length))
                return -1;

        /* Unclick sample */
        if(s.flags & Defs.SF_LOOP!=0) {
                if(s.flags & Defs.SF_BIDI!=0)
                        for(t in 0 ... 16)
				Mem.setFloat(Samples[handle]+((loopend+t)<<2),
					Mem.getFloat(Samples[handle]+((loopend-t-1)<<2)));
                else
                        for(t in 0 ... 16) {
				Mem.setFloat(Samples[handle]+((loopend+t)<<2),
					Mem.getFloat(Samples[handle]+((loopstart+t)<<2)));
			}
        } else
                for(t in 0 ... 16)
			Mem.setFloat(Samples[handle]+((t+length)<<2),0);
        return handle;
   }



   public static function WriteSamples(buf:ByteArray) {
	var left:Int;
	var portion=0;
	var t:Int;
	var pan:Int;
	var vol:Int;
	var todo=buffer_size;
	var written=0;
	
	while(todo>0) {
	   if (tickleft==0) {
		MPlayer.Player_HandleTick();
		tickleft=Std.int((MDriver.md_mixfreq*125)/(MDriver.md_bpm*50));
	   }
	   left = Std.int(Math.min(tickleft,todo));
	   tickleft -= left;
	   todo     -= left;
	   while(left>0) {
		portion = Std.int(Math.min(left, samplesthatfit));
		if (portion<=0) { return; }	// ?
		clearTickBuf(portion);
		for (t in 0 ... vc_softchn) {
			vnf=vinf[t];
			if (vnf.kick!=0) {
			   vnf.current=sampleToIndex(vnf.start);
			   vnf.kick=0;
			   vnf.active=true;
			   //vnf.click=CLICK_BUFFER;
			   vnf.rampvol=0;
			}
			if (vnf.frq==0) vnf.active=false;
			if (vnf.active) {
			   vnf.increment=cast((sampleToIndex(vnf.frq)/MDriver.md_mixfreq));
			   if ((vnf.flags&Defs.SF_REVERSE)!=0) vnf.increment=-vnf.increment;
			   vol=vnf.vol; pan=vnf.pan;
			   vnf.oldlvol=vnf.lvolsel; vnf.oldrvol=vnf.rvolsel;
			   if (vc_mode & Defs.DMODE_STEREO!=0) {
				if (pan!=Defs.PAN_SURROUND) {
				   vnf.lvolsel=(vol*(Defs.PAN_RIGHT-pan))>>8;
				   vnf.rvolsel=(vol*pan)>>8;
				} else {
				   vnf.lvolsel=vnf.rvolsel=Std.int((vol * 256) / 480);
				}
			   } else vnf.lvolsel=vol;
			   idxsize=(vnf.size!=0)?sampleToIndex(vnf.size):0;
			   idxlend=(vnf.repend!=0)?sampleToIndex(vnf.repend):0;
			   if (FRACBITS!=0) {
				if (vnf.size!=0) idxsize--;
				if (vnf.repend!=0) idxlend--;
			   }
			   idxlpos=sampleToIndex(vnf.reppos); 
			   AddChannel(portion);
			   TrackerEventDispatcher.dispatchEventDelay(new hxmikmod.event.TrackerSamplePosEvent(t,indexToSampleF(vnf.current),indexToSampleF(vnf.increment)),MPlayer.pf.sngtime-MPlayer.pf.audiobufferstart);
			}
		}
		Mix32toFP(buf,portion);
		TrackerEventDispatcher.dispatchEvent(new TrackerAudioBufferEvent(vc_tickbuf,portion,written,buffer_size));
		written+=portion;
                left-=portion;
	   }
	}
   }


   public static function VC_PlayStart():Bool {
	MDriver.md_mode |= Defs.DMODE_INTERP;
	tickleft=0;
	return false;
   }



   public static function VC_VoicePlay(voice:UBYTE,handle:SWORD,start:ULONG,size:ULONG,reppos:ULONG,repend:ULONG,flags:UWORD):Void {
        vinf[voice].flags    = flags;
        vinf[voice].handle   = handle;
        vinf[voice].start    = start;
        vinf[voice].size     = size;
        vinf[voice].reppos   = reppos;
        vinf[voice].repend   = repend;
        vinf[voice].kick     = 1;
   }


  public static function VC_VoiceSetPanning(voice:UBYTE,pan:ULONG):Void {
        /* protect against clicks if panning variation is too high */

        //if(Math.abs(vinf[voice].pan-pan)>48)
        //        vinf[voice].rampvol=CLICK_BUFFER;
        vinf[voice].pan=pan;
   }


   public static function VC_SetNumVoices():Bool {
	var t:Int;

        MDriver.md_mode|=Defs.DMODE_INTERP;

        if ((vc_softchn=MDriver.md_softchn)==0) return false;

        //if(vinf) free(vinf);
	vinf=null;
	vinf=new Array<VINFO>();
	hqmix=(vc_softchn <= 8);

        for(t in 0 ... vc_softchn) {
		vinf[t]=new VINFO();
                vinf[t].frq=10000;
                vinf[t].pan=(t&1!=0)?Defs.PAN_LEFT:Defs.PAN_RIGHT;
        }

        return false;
   }

   public static function VC_VoiceSetFrequency(voice:UBYTE,frq:ULONG) {
        vinf[voice].frq=frq;
   }


   public static function VC_VoiceSetVolume(voice:UBYTE,vol:UWORD):Void {
        /* protect against clicks if volume variation is too high */
        //if(Math.abs(vinf[voice].vol-vol)>32)
        //        vinf[voice].rampvol=CLICK_BUFFER;
        vinf[voice].vol=vol;
  }

  public static function VC_SampleLength(type:Int,s:SAMPLE):ULONG {
        if (s==null) return 0;
        return (s.length*((s.flags&Defs.SF_16BITS)!=0?2:1))+16;
  }

  public static function VC_SampleSpace(type:Int):ULONG {
        return vc_memory;
  }


   public static function VC_VoiceStop(voice:UBYTE):Void {
        vinf[voice].active = false;
   }  

   public static function VC_VoiceStopped(voice:UBYTE):Bool {
        return(vinf[voice].active==false);
   }

   public static function VC_VoiceGetPosition(voice:UBYTE):SLONG {
        return(Std.int(vinf[voice].current));
   }

   public static function VC_VoiceGetVolume(voice:UBYTE):UWORD {
        return vinf[voice].vol;
   }



}
