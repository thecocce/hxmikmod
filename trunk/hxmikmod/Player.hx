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

import flash.utils.ByteArray;
import hxmikmod.MMio;

class Player {


   public static function LoadURL(url:String) {
        new URLLoader(url);
   }

   public static function Start(mod:MODULE) {
        var t:Int;
        if (mod==null) return;

        if (!MikMod.Active())
                MikMod.EnableOutput();

        mod.forbid=false;

        //MUTEX_LOCK(vars);
        if (MPlayer.pf!=mod) {
                /* new song is being started, so completely stop out the old one. */
                if (MPlayer.pf!=null) MPlayer.pf.forbid=true;
                for (t in 0 ... MDriver.md_sngchn) MDriver.Voice_Stop_internal(t);
        }
        MPlayer.pf=mod;
        //MUTEX_UNLOCK(vars);

   }

   public static function Stop():Void {
        //MUTEX_LOCK(vars);
                MPlayer.Player_Stop_internal();
        //MUTEX_UNLOCK(vars);
   }



  public static function Player_Exit(mod:MODULE) {
        //MUTEX_LOCK(vars);
        MPlayer.Player_Exit_internal(mod);
        //MUTEX_UNLOCK(vars);
   }



   public static function Init(mod:MODULE):Bool {
        mod.extspd=true;
        mod.panflag=true;
        mod.wrap=true; //false;
        mod.loop=true;
        mod.fadeout=false;
        mod.relspd=0;

        /* make sure the player doesn't start with garbage */
        mod.control=new Array<MP_CONTROL>();
        for (i in 0 ... mod.numchn) mod.control[i]=new MP_CONTROL();
        mod.voice=new Array<MP_VOICE>();
        for (i in 0 ... MDriver.md_sngchn) mod.voice[i]=new MP_VOICE();

        //if (!(mod.control=(MP_CONTROL*)_mm_calloc(mod.numchn,sizeof(MP_CONTROL))))
        //        return 1;
        //if (!(mod.voice=(MP_VOICE*)_mm_calloc(md_sngchn,sizeof(MP_VOICE))))
        //        return 1;

        MPlayer.Player_Init_internal(mod);
        return false;
   }


   /* Loads a module given a file pointer.
      File is loaded from the current file seek position. */

   public static function LoadBytes(data:ByteArray,maxchan:Int,curious:Bool) {
        var reader=new MREADER(data);
        var result=MLoader.Player_LoadGeneric(reader,maxchan,curious);
        return result;
   }



}
