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

import hxmikmod.MMio;
import hxmikmod.SAMPLE;
import hxmikmod.Types;
import hxmikmod.event.TrackerEvent;
import hxmikmod.event.TrackerEventDispatcher;
import hxmikmod.Mem;
import flash.utils.Timer;
import flash.events.TimerEvent;
import flash.utils.ByteArray;

class MLoader {
   static var modreader:MREADER;
   public static var of:MODULE;
   static var loaders:Array<MLoader>;


   public static var finetune=[
        8363,8413,8463,8529,8581,8651,8723,8757,
        7895,7941,7985,8046,8107,8169,8232,8280
   ];


   var type:String;
   var version:String;
   public function Init():Bool { return false; }
   public function Test():Bool { return false; }
   public function Load(curious:Bool):Bool { return false; }
   public function Cleanup():Void { }
   public function LoadTitle():String { return null; }


   public static function ML_FreeEx(mf:MODULE) {
	// gc's job

   }



   public static function Player_Free_internal(mf:MODULE) {
        if(mf!=null) {
                MPlayer.Player_Exit_internal(mf);
                ML_FreeEx(mf);
        }
   }

   public static function Player_Free(mf:MODULE) {
        //MUTEX_LOCK(vars);
        Player_Free_internal(mf);
        //MUTEX_UNLOCK(vars);
   }



   public static function ML_LoadSamples():Bool {
	var si:Int=0;
	var u:Int;
	for (u in 0 ... of.numsmp) {
	   var s=of.samples[u];
	   if (s.length!=0) SLoader.SL_RegisterSample(s,Defs.MD_MUSIC,modreader);
	}
	/*
        for(u=of.numsmp,s=of.samples;u;u--,s++)
                if(s->length) SL_RegisterSample(s,Defs.MD_MUSIC,modreader);
	*/
        return true;
   }

   public static function ML_AllocUniMod():MODULE {
	return new MODULE();
   }



   /* Loads a module given an reader */
   public static function Player_LoadGeneric(reader:MREADER,maxchan:Int,curious:Bool):Bool {
	var t:Int;
	var l:MLoader;
	var ok:Bool;
	var mf:MODULE;

	l=null;
        modreader = reader;
        MMio._mm_errno = 0;
        MMio._mm_critical = false;
        MMio._mm_iobase_setcur(modreader);

	TrackerEventDispatcher.dispatchEvent(new TrackerLoadingEvent(0,"initializing..."));
	Mem.freeAll();
        /* Try to find a loader that recognizes the module */
	for (tryloader in loaders) {	// firstloader ...
                MMio._mm_rewind(modreader);
                if (tryloader.Test()) { l=tryloader; break; }
        }

        if (l==null) {
                MMio._mm_errno = Defs.MMERR_NOT_A_MODULE;
                if (MMio._mm_errorhandler!=null) MMio._mm_errorhandler();
                MMio._mm_rewind(modreader);MMio._mm_iobase_revert();
                return false; //null;
        }


        /* init unitrk routines */
        if(!MUnitrk.UniInit()) {
                if(MMio._mm_errorhandler!=null) MMio._mm_errorhandler();
                MMio._mm_rewind(modreader);MMio._mm_iobase_revert();
                return false; //null;

        }

	TrackerEventDispatcher.dispatchEvent(new TrackerLoadingEvent(0,"loading..."));


        /* init the module structure with vanilla settings */
	of=new MODULE();
        of.bpmlimit = 33;
        of.initvolume = 128;
        for (t in 0 ... Defs.UF_MAXCHAN) of.chanvol[t] = 64;
        for (t in 0 ... Defs.UF_MAXCHAN)
                of.panning[t] = ((t + 1) & 2)!=0 ? Defs.PAN_RIGHT : Defs.PAN_LEFT;
        /* init module loader and load the header / patterns */
        if (l.Init==null || l.Init()) {
                MMio._mm_rewind(modreader);
                ok = l.Load(false /*curious*/);
                /* propagate inflags=flags for in-module samples */
                for (t in 0 ... of.numsmp)
                        if (of.samples[t].inflags == 0)
                                of.samples[t].inflags = of.samples[t].flags;
        } else
                ok = false;


TrackerEventDispatcher.dispatchEvent(new TrackerLoadingEvent(0,"loading...2"));
        /* free loader and unitrk allocations */
        if (l.Cleanup!=null) l.Cleanup();
        MUnitrk.UniCleanup();
        if(!ok) {
                ML_FreeEx(of);
                if(MMio._mm_errorhandler!=null) MMio._mm_errorhandler();
                MMio._mm_rewind(modreader);MMio._mm_iobase_revert();
                return false; //null;
        }

        if(!ML_LoadSamples()) {
                ML_FreeEx(of);
                if(MMio._mm_errorhandler!=null) MMio._mm_errorhandler();
                MMio._mm_rewind(modreader);MMio._mm_iobase_revert();
                return false; //null;
        }

        if((mf=ML_AllocUniMod())==null) {
                ML_FreeEx(of);
                MMio._mm_rewind(modreader);MMio._mm_iobase_revert();
                if(MMio._mm_errorhandler!=null) MMio._mm_errorhandler();
                return false; //null;
        }

        /* If the module doesn't have any specific panning, create a
           MOD-like panning, with the channels half-separated. */
        if ((of.flags & Defs.UF_PANNING)==0)
                for (t in 0 ... of.numchn)
                        of.panning[t] = ((t + 1) & 2)!=0 ? Defs.PAN_HALFRIGHT : Defs.PAN_HALFLEFT;

        /* Copy the static MODULE contents into the dynamic MODULE struct. */
        //memcpy(mf,&of,sizeof(MODULE));
	mf=of;	// ???

        if(maxchan>0) {
                if((mf.flags&Defs.UF_NNA)==0&&(mf.numchn<maxchan))
                        maxchan = mf.numchn;
                else
                  if((mf.numvoices!=0)&&(mf.numvoices<maxchan))
                        maxchan = mf.numvoices;

                if(maxchan<mf.numchn) mf.flags |= Defs.UF_NNA;

                if(MDriver.MikMod_SetNumVoices_internal(maxchan,-1)) {
                        MMio._mm_iobase_revert();
                        Player_Free(mf);
                        return false; //null;
                }
        }

	TrackerEventDispatcher.dispatchEvent(new TrackerLoadingEvent(0,"processing samples..."));
	// do sample loading bit by bit
	SLoader.reset();
	new IncrementalLoader(300,mf).start();
	return true;
   }


   public static function AllocPositions(total:Int):Bool {
        if(total==0) {
                MMio._mm_errno=Defs.MMERR_NOT_A_MODULE;
                return false;
        }
	of.positions=new Array<UWORD>();
	for (i in 0 ... total) of.positions[i]=0;
        return true;
   }

   public static function AllocPatterns():Bool {
	var s:Int;
	var t:Int;
	var tracks=0;

        if((of.numpat==0)||(of.numchn==0)) {
                MMio._mm_errno=Defs.MMERR_NOT_A_MODULE;
                return false;
        }
        /* Allocate track sequencing array */
        //if(!(of.patterns=(UWORD*)_mm_calloc((ULONG)(of.numpat+1)*of.numchn,sizeof(UWORD)))) return 0;
        //if(!(of.pattrows=(UWORD*)_mm_calloc(of.numpat+1,sizeof(UWORD)))) return 0;
	of.patterns=new Array<UWORD>();
	of.pattrows=new Array<UWORD>();
        for(t in 0 ... of.numpat+1) {
                of.pattrows[t]=64;
                for (s in 0 ... of.numchn)
                	of.patterns[(t*of.numchn)+s]=tracks++;
        }
        return true;
   }


   public static function AllocTracks():Bool {
        if(of.numtrk==0) {
                MMio._mm_errno=Defs.MMERR_NOT_A_MODULE;
                return false;
        }
	of.tracks=new Array<MEMPTR>();
        //if(!(of.tracks=(UBYTE **)_mm_calloc(of.numtrk,sizeof(UBYTE *)))) return 0;
        return (of.tracks!=null);
   }

   public static function AllocInstruments():Bool {
	var t:Int;
	var n:Int;

        if(of.numins==0) {
                MMio._mm_errno=Defs.MMERR_NOT_A_MODULE;
                return false;
        }
        //if(!(of.instruments=(INSTRUMENT*)_mm_calloc(of.numins,sizeof(INSTRUMENT))))
        //        return 0;
	of.instruments=new Array<INSTRUMENT>();
        for(t in 0 ... of.numins) {
		of.instruments[t]=new INSTRUMENT();
                for(n in 0 ... Defs.INSTNOTES) { 
                        /* Init note / sample lookup table */
                        of.instruments[t].samplenote[n]   = n;
                        of.instruments[t].samplenumber[n] = t;
                }   
                of.instruments[t].globvol = 64;
        }
        return true;
   }


   public static function AllocSamples():Bool {
	var u:UWORD;

        if(of.numsmp==0) {
                MMio._mm_errno=Defs.MMERR_NOT_A_MODULE;
                return false;
        }
        //if(!(of.samples=(SAMPLE*)_mm_calloc(of.numsmp,sizeof(SAMPLE)))) return 0;
	of.samples=new Array<SAMPLE>();

        for(u in 0 ... of.numsmp) {
		of.samples[u]=new SAMPLE();
                of.samples[u].panning = 128; /* center */
                of.samples[u].handle  = -1;
                of.samples[u].globvol = 64;
                of.samples[u].volume  = 64;
        }
        return true;
   }


   /* Creates a CSTR out of a character buffer of 'len' bytes, but strips any
      terminating non-printing characters like 0, spaces etc.                    */
   public static function DupStr(s:String,len:UWORD,strict:Bool):String {
	var t:UWORD;
	var d="";

        /* Scan for last printing char in buffer [includes high ascii up to 254] */
        while(len!=0) {
                if(s.charCodeAt(len-1)>0x20) break;
                len--;
        }

        /* Scan forward for possible NULL character */
        if(strict) {
		var nul=-1;
                for(t in 0 ... len) if (s.charCodeAt(t)==0 && nul==-1) nul=t;
		if (nul!=-1 && nul<len) len=nul;
        }

        /* When the buffer wasn't completely empty, allocate a cstring and copy the
           buffer into that string, except for any control-chars */

        for(t in 0 ... len) d+=(s.charCodeAt(t)<32)?'.':s.substr(t,1);
        return d;
   }




   /* Loads a module given a file pointer.
      File is loaded from the current file seek position. */

   public static function Player_LoadBytes(data:ByteArray,maxchan:Int,curious:Bool) {
	var reader=new MREADER(data);
	var result=Player_LoadGeneric(reader,maxchan,curious);
        return result;
   }



   private function new() {
   }



   public static function registerLoaders():Void {
	loaders=new Array<MLoader>();
	loaders.push(new hxmikmod.loaders.Load_mod());
	loaders.push(new hxmikmod.loaders.Load_xm());
	loaders.push(new hxmikmod.loaders.Load_s3m());
	loaders.push(new hxmikmod.loaders.Load_it());
   }



   public static function ReadComment(len:UWORD):Bool {
        if(len!=0) {
                var i:Int;

                //if(!(of.comment=(CHAR*)_mm_malloc(len+1))) return 0;
                //_mm_read_UBYTES(of.comment,len,modreader);
		of.comment=MMio._mm_read_string(len,modreader);
		~/\r/g.replace(of.comment,"\n");

                /* translate IT linefeeds */
                //for(i=0;i<len;i++)
                //        if(of.comment[i]=='\r') of.comment[i]='\n';
		//
                //of.comment[len]=0;      /* just in case */
        }
	if (of.comment=="") of.comment=null;
        return true;
   }


}


   /********* Flash incremental loading **************/

   class IncrementalLoader extends Timer {
	var mf:MODULE;

	public function new(delay:Float,mf:MODULE) {
	   super(delay,1);
	   this.mf=mf;
	   addEventListener(TimerEvent.TIMER_COMPLETE, completeHandler);
	}



        function completeHandler(e:TimerEvent):Void {
	   var prog=SLoader.SL_LoadSamples();
	   switch(prog) {
	   	case 0:  // not complete, need another timer
		   new IncrementalLoader(10,mf).start();
	   	case -1: // failed
                   MMio._mm_iobase_revert();
                   MLoader.Player_Free_internal(mf);
		   TrackerEventDispatcher.dispatchEvent(new TrackerLoadingEvent(-1,"Loading failed, err="+MMio._mm_errno));
	   	case 1: // done loading
        	   if (Player.Init(mf)) {
                  	MMio._mm_iobase_revert();
                  	MLoader.Player_Free_internal(mf);
		   	TrackerEventDispatcher.dispatchEvent(new TrackerLoadingEvent(-1,"Player init failed."));
			return;
		   }
        	   MMio._mm_iobase_revert();
		   TrackerEventDispatcher.dispatchEvent(new TrackerLoadingEvent(1,"\""+mf.songname+"\"",1,mf));
	   }
	}

   }


