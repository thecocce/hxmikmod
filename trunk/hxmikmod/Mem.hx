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

import flash.Memory;
import flash.utils.ByteArray;
import flash.utils.Endian;


// MEMPTR is an offset in the Alchemy mem ops block
// i.e. Int, but typedef'ed to help readability

typedef MEMPTR=Int;



// This class implements sample memory acess and management in
// a haXe/Flash optimized way.
// All buffers and mixing data are stored in one big chunk.
// This allows us to access them with the fast flash.Memory methods, doing
// only one Memory.select().



class Mem {

   public static var buf=init();
   static var zerobytes:ByteArray;
   static var last_alloc:MEMPTR;

   static var map:Hash<MEMPTR>;	// map of allocated regions, just for debug
   inline static var RESERVED_SIZE=(Virtch.TICKLSIZE+32)<<3;

   static function init() {
	var ret=new ByteArray();
	ret.length=RESERVED_SIZE;	// Virtch tickbuf hardwired to buffer start
	Memory.select(ret);
	zerobytes=new ByteArray();
	map=new Hash();
	for (i in 0 ... 16384>>2) zerobytes.writeFloat(0);	// buffer for fast zeroing
	return ret;
   }


   public static function freeAll() {
	buf.length=RESERVED_SIZE;
   }

   // allocates a new area at the end of the data buffer,
   // returns the byte index to the beginning of it

   public static function alloc(len:Int,?pos:haxe.PosInfos):MEMPTR {
	var ret=buf.length;
	buf.length+=len;
	last_alloc=ret;
	map.set(pos.fileName+":"+pos.lineNumber,ret);
	return ret;
   }

   public static function free(ptr:MEMPTR) {
	if (last_alloc==ptr) {
	   buf.length=last_alloc;
	   last_alloc=0;
	} //else trace("can't free");
   }

   public static function realloc(ptr:MEMPTR,len:Int):Bool {
	if (last_alloc!=ptr) {
		trace("can't realloc "+ptr+", last_alloc="+last_alloc+", map: "+map);
		setByte(-1,-1);		// throw an error for debugging
		return false;
	}
	buf.length+=len;
	return true;
   }


   // note that you have to pass a byte index (4*float index)

   inline public static function setFloat(i:Int,f:Float) {
	Memory.setFloat(i,f);	
   }

   inline public static function getFloat(i:Int):Float {
	return Memory.getFloat(i);
   }

   inline public static function setShort(i:Int,s:Int) {
	Memory.setI16(i,s);
   }

   inline public static function getShort(i:Int):Int {
   	return Memory.signExtend16(Memory.getUI16(i));
   }

   inline public static function getByte(i:MEMPTR):Int {
	return Memory.getByte(i);
   }

   inline public static function setByte(i:MEMPTR,b:Int) {
	Memory.setByte(i,b);
   }

   // idea from http://lain.knark.net/flashmafia/Speakeasy.hx.001.txt

   inline public static function clearFloat(i:Int,len:Int) {
	//if (len>16384) trace("clearFloat: "+len+" too much");	// could also check 4-byte boundary
	buf.position=i;
	buf.writeBytes(zerobytes,0,len);	
   }


}


