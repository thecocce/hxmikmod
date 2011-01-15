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


class MikMod {


   public static function RegisterAllDrivers():Void {
   }

   public static function Active():Bool {
        return MDriver.MikMod_Active_internal();
   }


   public static function EnableOutput():Bool {
        return MDriver.MikMod_EnableOutput_internal();
   }


   public static function Exit():Void {
        return MDriver.MikMod_Exit_internal();
   }


   public static function Init(params:Hash<Dynamic>):Bool {
        var result:Bool;

        MLoader.registerLoaders();
        //MUTEX_LOCK(vars);
        //MUTEX_LOCK(lists);
        result=MDriver._mm_init(params);
        //MUTEX_UNLOCK(lists);
        //MUTEX_UNLOCK(vars);
        return result;
   }



}
