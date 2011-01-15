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
import hxmikmod.SAMPLE;
import hxmikmod.event.TrackerEvent;
import hxmikmod.event.TrackerEventDispatcher;

class MDriver {

	public static var md_numchn=0;
	public static var md_sngchn=0;
	public static var md_sfxchn=0;
        public static var md_hardchn=0;
	public static var md_softchn=0;

	public static var md_driver:MDriver;

	static var sfxinfo:Array<UBYTE>;

	static var isplaying=false;
	static var initialized=false;
	static var sfxpool:Int;
	static var md_sample:Array<SAMPLE>;

	var Name:String;
	var Version:String;
	var HardVoiceLimit:UBYTE;
	var SoftVoiceLimit:UBYTE;
	var Alias:String;
	var CmdLineHelp:String;

	public function CommandLine(s:String):Void {
	}
	public function IsPresent():Bool {
	  return true;
	}
	public function SampleLoad(s:SAMPLOAD,a:Int):SWORD {
	  return Virtch.VC_SampleLoad(s,a);
	}
	public function SampleUnload(a:SWORD):Void {
	  trace("SampleUnload");
	}
	public function FreeSampleSpace(a:Int):ULONG {
	   return Virtch.VC_SampleSpace(a);
	}
	public function RealSampleLength(a:Int,s:SAMPLE):ULONG {
	   return Virtch.VC_SampleLength(a,s);
	}
	public function Init():Bool {
	  return Virtch.VC_Init();
	}
	public function Exit() {
	  trace("Exit");
	}
	public function Reset():Bool {
	  trace("Reset");
	  return false;
	}
	public function SetNumVoices():Bool {
	  return Virtch.VC_SetNumVoices();
	}
	public function PlayStart():Bool {
	  return Virtch.VC_PlayStart();
	}
	public function PlayStop():Void {
	  trace("PlayStop");
	}
	public function Update():Void {
	  trace("Update");
	}
	public function Pause():Void {
	  trace("Pause");
	}
	public function VoiceSetVolume(a:UBYTE,b:UWORD):Void {
	   Virtch.VC_VoiceSetVolume(a,b);
	}
	public function VoiceGetVolume(a:UBYTE):UWORD {
	   return Virtch.VC_VoiceGetVolume(a);
	}
	public function VoiceSetFrequency(a:UBYTE,b:ULONG):Void {
	   Virtch.VC_VoiceSetFrequency(a,b);
	}
	public function VoiceGetFrequency(a:UBYTE):ULONG {
	  trace("VoiceGetFrequency");
	  return 0;
	}
	public function VoiceSetPanning(a:UBYTE,b:ULONG):Void {
	   Virtch.VC_VoiceSetPanning(a,b);
	}
	public function VoiceGetPanning(a:UBYTE):ULONG {
	  trace("VoiceGetPanning");
	  return 0;
	}
	public function VoicePlay(a:UBYTE,b:SWORD,c:ULONG,d:ULONG,e:ULONG,f:ULONG,g:UWORD):Void {
	   Virtch.VC_VoicePlay(a,b,c,d,e,f,g);
	}
	public function VoiceStop(a:UBYTE):Void {
	   Virtch.VC_VoiceStop(a);
	}
	public function VoiceStopped(a:UBYTE):Bool {
	    return Virtch.VC_VoiceStopped(a);
	}
	public function VoiceGetPosition(a:UBYTE):SLONG {
	   return Virtch.VC_VoiceGetPosition(a);
	}
	public function VoiceRealVolume(a:UBYTE):ULONG {
	  trace("VoiceRealVolume");
	  return 0;
	}

	/* Initial global settings */

	public static var md_device=0;
	public static var md_mixfreq=44100;
	public static var md_mode=Defs.DMODE_STEREO|Defs.DMODE_16BITS|Defs.DMODE_SURROUND|Defs.DMODE_SOFT_MUSIC|Defs.DMODE_SOFT_SNDFX;
	public static var md_pansep=128;
	public static var md_reverb=0;
	public static var md_volume=128;
	public static var md_musicvolume=128;
	public static var md_sndfxvolume=128;
	public static var md_bpm=125;



	public static function Voice_SetFrequency_internal(voice:SBYTE,frq:ULONG):Void {
        	if((voice<0)||(voice>=md_numchn)) return;
        	if((md_sample[voice]!=null)&&(md_sample[voice].divfactor!=0))
                	frq=Std.int(frq/md_sample[voice].divfactor);
        	md_driver.VoiceSetFrequency(voice,frq);
	}

	public static function Voice_SetFrequency(voice:SBYTE,frq:ULONG):Void {
        	//MUTEX_LOCK(vars);
        	Voice_SetFrequency_internal(voice,frq);
        	//MUTEX_UNLOCK(vars);
	}



	public static function Voice_SetPanning_internal(voice:SBYTE,pan:ULONG) {
        	if((voice<0)||(voice>=md_numchn)) return;
        	if(pan!=Defs.PAN_SURROUND) {
                	if(md_pansep>128) md_pansep=128;
                	if(md_mode & Defs.DMODE_REVERSE!=0) pan=255-pan;
                	pan = Std.int(((pan-128)*md_pansep)/128)+128;	// cast
        	}
        	md_driver.VoiceSetPanning(voice, pan);
	}

	public static function Voice_SetPanning(voice:SBYTE,pan:ULONG):Void {
        	//MUTEX_LOCK(vars);
        	Voice_SetPanning_internal(voice,pan);
        	//MUTEX_UNLOCK(vars);
	}

	public static function Voice_SetVolume_internal(voice:SBYTE,vol:UWORD):Void {
        	var tmp:ULONG;

        	if((voice<0)||(voice>=MDriver.md_numchn)) return;

	        /* range checks */
        	if(md_musicvolume>128) md_musicvolume=128;
        	if(md_sndfxvolume>128) md_sndfxvolume=128;
        	if(md_volume>128) md_volume=128;

        	tmp=vol*md_volume*((voice<md_sngchn)?md_musicvolume:md_sndfxvolume);	// casteja
        	md_driver.VoiceSetVolume(voice,Std.int(tmp/16384));	// UL
	}

	public static function Voice_SetVolume(voice:SBYTE,vol:UWORD):Void {
        	//MUTEX_LOCK(vars);
        	Voice_SetVolume_internal(voice,vol);
        	//MUTEX_UNLOCK(vars);
	}



	public static function Voice_Play_internal(voice:SBYTE,s:SAMPLE,start:ULONG):Void {
        	var repend:ULONG;
        	if((voice<0)||(voice>=MDriver.md_numchn)) return;

	        MDriver.md_sample[voice]=s;
        	repend=s.loopend;

        	if(s.flags&Defs.SF_LOOP!=0)
                	/* repend can't be bigger than size */
                	if(repend>s.length) repend=s.length;

        	md_driver.VoicePlay(voice,s.handle,start,s.length,s.loopstart,repend,s.flags);
		TrackerEventDispatcher.dispatchEvent(new hxmikmod.event.TrackerVoiceEvent(voice,s.handle,start,s.length,s.loopstart,repend,s.flags));
	}


	public static function Voice_Play(voice:SBYTE,s:SAMPLE,start:ULONG):Void {
        	if(start>s.length) return;
	        //MUTEX_LOCK(vars);
        	Voice_Play_internal(voice,s,start);
        	//MUTEX_UNLOCK(vars);
	}



	function Voice_Stopped(voice:SBYTE):Bool {
        	var result:Bool;
        	//MUTEX_LOCK(vars);
        	result=Voice_Stopped_internal(voice);
        	//MUTEX_UNLOCK(vars);
	        return result;
	}



	public static function MikMod_Active_internal():Bool {
        	return isplaying;
	}


	public static function Voice_Stop(voice:SBYTE):Void {
        	//MUTEX_LOCK(vars);
        	Voice_Stop_internal(voice);
        	//MUTEX_UNLOCK(vars);
	}

	public static function Voice_Stopped_internal(voice:SBYTE):Bool {
        	if((voice<0)||(voice>=md_numchn)) return false;
        	return(md_driver.VoiceStopped(voice));
	}

	public static function Voice_Stop_internal(voice:SBYTE):Void {
           if((voice<0)||(voice>=md_numchn)) return;
           if(voice>=md_sngchn)
                /* It is a sound effects channel, so flag the voice as non-critical! */
                sfxinfo[voice-md_sngchn]=0;
           md_driver.VoiceStop(voice);
	}


	public static function MikMod_DisableOutput_internal() {
        	if(isplaying && md_driver!=null) {
                	isplaying = false;
                	md_driver.PlayStop();
        	}
	}


   public static function MD_SampleLoad(s:SAMPLOAD,type:Int):SWORD {
        var result:SWORD;
        if(type==Defs.MD_MUSIC)
                type=(md_mode & Defs.DMODE_SOFT_MUSIC)!=0?Defs.MD_SOFTWARE:Defs.MD_HARDWARE;
        else if(type==Defs.MD_SNDFX)
                type=(md_mode & Defs.DMODE_SOFT_SNDFX)!=0?Defs.MD_SOFTWARE:Defs.MD_HARDWARE;
        SLoader.SL_Init(s);
        result=md_driver.SampleLoad(s,type);
        SLoader.SL_Exit(s);
        return result;
   }

   public static function MD_SampleUnload(handle:SWORD) {
        md_driver.SampleUnload(handle);
   }


   /* Note: 'type' indicates whether the returned value should be for music or for
      sound effects. */
   public static function MD_SampleSpace(type:Int):ULONG {
        if(type==Defs.MD_MUSIC)
                type=(md_mode & Defs.DMODE_SOFT_MUSIC)!=0?Defs.MD_SOFTWARE:Defs.MD_HARDWARE;
        else if(type==Defs.MD_SNDFX)
                type=(md_mode & Defs.DMODE_SOFT_SNDFX)!=0?Defs.MD_SOFTWARE:Defs.MD_HARDWARE;
        return md_driver.FreeSampleSpace(type);
   }

   public static function MD_SampleLength(type:Int,s:SAMPLE):ULONG {
        if(type==Defs.MD_MUSIC)
                type=(md_mode & Defs.DMODE_SOFT_MUSIC)!=0?Defs.MD_SOFTWARE:Defs.MD_HARDWARE;
        else
          if(type==Defs.MD_SNDFX)
                type=(md_mode & Defs.DMODE_SOFT_SNDFX)!=0?Defs.MD_SOFTWARE:Defs.MD_HARDWARE;
        return md_driver.RealSampleLength(type,s);
   }




   public static function LimitSoftVoices(limit:Int) {
	var t=0;

        if ((md_mode & Defs.DMODE_SOFT_SNDFX)!=0 && (md_sfxchn>limit)) md_sfxchn=limit;
        if ((md_mode & Defs.DMODE_SOFT_MUSIC)!=0 && (md_sngchn>limit)) md_sngchn=limit;

        if (md_mode & Defs.DMODE_SOFT_SNDFX!=0)
                md_softchn=md_sfxchn;
        else
                md_softchn=0;

        if (md_mode & Defs.DMODE_SOFT_MUSIC!=0) md_softchn+=md_sngchn;

        while (md_softchn>limit) {
                if (++t & 1!=0) {
                        if ((md_mode & Defs.DMODE_SOFT_SNDFX)!=0 && (md_sfxchn>4)) md_sfxchn--;
                } else {
                        if ((md_mode & Defs.DMODE_SOFT_MUSIC)!=0 && (md_sngchn>8)) md_sngchn--;
                }

                if ((md_mode & Defs.DMODE_SOFT_SNDFX)==0)
                        md_softchn=md_sfxchn;
                else
                        md_softchn=0;

                if ((md_mode & Defs.DMODE_SOFT_MUSIC)==0)
                        md_softchn+=md_sngchn;
        }
        md_numchn=md_hardchn+md_softchn;
   }




   public static function LimitHardVoices(limit:Int) {
	var t=0;

        if ((md_mode & Defs.DMODE_SOFT_SNDFX)==0 && (md_sfxchn>limit)) md_sfxchn=limit;
        if ((md_mode & Defs.DMODE_SOFT_MUSIC)==0 && (md_sngchn>limit)) md_sngchn=limit;

        if ((md_mode & Defs.DMODE_SOFT_SNDFX)==0)
                md_hardchn=md_sfxchn;
        else
                md_hardchn=0;

        if ((md_mode & Defs.DMODE_SOFT_MUSIC)==0) md_hardchn += md_sngchn;

        while (md_hardchn>limit) {
                if (++t & 1!=0) {
                        if ((md_mode & Defs.DMODE_SOFT_SNDFX)==0 && (md_sfxchn>4)) md_sfxchn--;
                } else {
                        if ((md_mode & Defs.DMODE_SOFT_MUSIC)==0 && (md_sngchn>8)) md_sngchn--;
                }

                if ((md_mode & Defs.DMODE_SOFT_SNDFX)==0)
                        md_hardchn=md_sfxchn;
                else
                        md_hardchn=0;

                if ((md_mode & Defs.DMODE_SOFT_MUSIC)==0)
                        md_hardchn+=md_sngchn;
        }
        md_numchn=md_hardchn+md_softchn;
   }



   public static function MikMod_EnableOutput_internal():Bool {
        MMio._mm_critical = true;
        if(!isplaying) {
                if(md_driver.PlayStart()) return true;
                isplaying = true;
        }
        MMio._mm_critical = false;
        return false;
   }



   public static function MikMod_Exit_internal() {
        MikMod_DisableOutput_internal();
        md_driver.Exit();
        md_numchn = md_sfxchn = md_sngchn = 0;
        md_driver = null; // drv_nos;
        md_sample  = null;
        sfxinfo    = null;
        initialized = false;
   }




   /* If either parameter is -1, the current set value will be retained. */
   public static function MikMod_SetNumVoices_internal(music:Int, sfx:Int):Bool {
        var resume = false;
	var t:Int;
	var oldchn=0;

        if((music==0)&&(sfx==0)) return true;
        MMio._mm_critical = true;
        if (isplaying) {
                MikMod_DisableOutput_internal();
                oldchn = md_numchn;
                resume = true;
        }

        // if (sfxinfo) free(sfxinfo);
        // if(md_sample) free(md_sample);
        md_sample  = null;
        sfxinfo    = null;

        if(music!=-1) md_sngchn = music;
        if(sfx!=-1)   md_sfxchn = sfx;
        md_numchn = md_sngchn + md_sfxchn;

        LimitHardVoices(md_driver.HardVoiceLimit);
        LimitSoftVoices(md_driver.SoftVoiceLimit);

        if(md_driver.SetNumVoices()) {
                MikMod_Exit_internal();
                if(MMio._mm_errno!=0)
                        if(MMio._mm_errorhandler!=null) MMio._mm_errorhandler();
                md_numchn = md_softchn = md_hardchn = md_sfxchn = md_sngchn = 0;
                return true;
        }
        if(md_sngchn+md_sfxchn!=0)
                md_sample=new Array<SAMPLE>(); // (SAMPLE**)_mm_calloc(md_sngchn+md_sfxchn,sizeof(SAMPLE*));
        if(md_sfxchn!=0)
                sfxinfo = new Array<UBYTE>();  //(UBYTE *)_mm_calloc(md_sfxchn,sizeof(UBYTE));

        /* make sure the player doesn't start with garbage */
        for(t in oldchn ... md_numchn)  Voice_Stop_internal(t);

        sfxpool = 0;
        if(resume) MikMod_EnableOutput_internal();
        MMio._mm_critical = false;
        return false;
   }


   public static function _mm_init(params:Hash<Dynamic>):Bool {
        var t:UWORD;

        MMio._mm_critical = true;

        /* if md_device==0, try to find a device number */

	md_driver=new FlashDriver(params);

/*
        if(md_device==0) {
                cmdline=NULL;

                for(t=1,md_driver=firstdriver;md_driver;md_driver=md_driver->next,t++)
                        if(md_driver->IsPresent()) break;

                if(!md_driver) {
                        _mm_errno = MMERR_DETECTING_DEVICE;
                        if(_mm_errorhandler) _mm_errorhandler();
                        md_driver = &drv_nos;
                        return 1;
                }

                md_device = t;
        } else {
                // if n>0, use that driver
                for(t=1,md_driver=firstdriver;(md_driver)&&(t!=md_device);md_driver=md_driver->next)
                        t++;

                if(!md_driver) {
                        _mm_errno = MMERR_INVALID_DEVICE;
                        if(_mm_errorhandler) _mm_errorhandler();
                        md_driver = &drv_nos;
                        return 1;
                }

                // arguments here might be necessary for the presence check to succeed
                if(cmdline&&(md_driver->CommandLine))
                        md_driver->CommandLine(cmdline);

                if(!md_driver->IsPresent()) {
                        _mm_errno = MMERR_DETECTING_DEVICE;
                        if(_mm_errorhandler) _mm_errorhandler();
                        md_driver = &drv_nos;
                        return 1;
                }
        }

        olddevice = md_device;
*/
	if (md_driver.Init()) {
                MikMod_Exit_internal();
                if(MMio._mm_errorhandler!=null) MMio._mm_errorhandler();
                return true;
        }

        initialized=true;
        MMio._mm_critical=false;

        return false;
   }





}

