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
import flash.utils.Endian;
import hxmikmod.Types;


class MMio {
   public static var _mm_errno=0;
   public static var _mm_critical=false;
   public static var _mm_errorhandler:Void->Void;
   public static var _mm_iobase=0;
   public static var temp_iobase=0;

   inline public static var SEEK_SET=0;
   inline public static var SEEK_CUR=1;

   static inline function BE(r:MREADER) { r.i.endian=Endian.BIG_ENDIAN; }
   static inline function LE(r:MREADER) { r.i.endian=Endian.LITTLE_ENDIAN; }


   /* Sets the current file-position as the new _mm_iobase */
   public static function _mm_iobase_setcur(reader:MREADER) {
        temp_iobase=_mm_iobase;  /* store old value in case of revert */
        _mm_iobase=reader.Tell();
   }


   /* Reverts to the last known _mm_iobase value. */
   public static function _mm_iobase_revert() {
        _mm_iobase=temp_iobase;
   }

   public static function _mm_rewind(x:MREADER) {
	_mm_fseek(x,0,SEEK_SET);
   }

   public static function _mm_fseek(r:MREADER,pos:Int,whence:Int) {
	r.Seek(pos,whence);
   }

   public static function _mm_ftell(r:MREADER) {
	return r.i.position;
   }


   public static function _mm_read_string(number:Int,reader:MREADER):String {
        return reader.i.readUTFBytes(number);
   }

   public static function _mm_read_M_UWORD(reader:MREADER):UWORD {
	BE(reader);
	var result=reader.i.readUnsignedShort();
	LE(reader);
	return result;
   }

   public static function _mm_read_I_UWORD(reader:MREADER):UWORD {
	return reader.i.readUnsignedShort();
   }

   public static function _mm_read_M_ULONG(reader:MREADER):ULONG {
	BE(reader);
	var result=reader.i.readUnsignedInt();
	LE(reader);
	return result;
   }

   public static function _mm_read_I_ULONG(reader:MREADER):ULONG {
	return reader.i.readUnsignedInt();
   }

   public static function _mm_read_M_SWORD(reader:MREADER):SWORD {
	BE(reader);
	var result=reader.i.readShort();
	LE(reader);
	return result;
   }

   public static function _mm_read_I_SWORD(reader:MREADER):SWORD {
	return reader.i.readShort();
   }

   public static function _mm_read_M_SLONG(reader:MREADER):SLONG {
	BE(reader);
	var result=reader.i.readInt();
	LE(reader);
	return result;
   }

   public static function _mm_read_I_SLONG(reader:MREADER):SLONG {
	return reader.i.readInt();
   }


   public static function _mm_read_UBYTE(reader:MREADER) {
	return reader.i.readUnsignedByte();
   }

   public static function _mm_read_SBYTE(reader:MREADER) {
	return reader.i.readByte();
   }

   public static function _mm_read_UBYTES(len:UInt,reader:MREADER):Array<UBYTE> {
	var ret=new Array<UBYTE>();
	if (reader.i.bytesAvailable<len) return null;
	for (a in 0 ... len) {
	   ret[a]=reader.i.readUnsignedByte();
	}
	return ret;
   }

   public static function _mm_read_ByteArray(len:UInt,reader:MREADER):ByteArray {
        var ret=new ByteArray();
        reader.i.readBytes(ret,0,len);
        if (ret.bytesAvailable!=len) return null;
        return ret;
   }

   public static function _mm_read_I_UWORDS(number:Int,reader:MREADER):Array<UWORD> {
	var ret=new Array<UWORD>();
	for (i in 0 ... number) {
		ret[i]=reader.i.readUnsignedShort();
	}
	if (reader.Eof()) return null;
	return ret;
   }


   public static function _mm_read_I_SWORDS(number:Int,reader:MREADER):Array<SWORD> {
	var ret=new Array<SWORD>();
	for (i in 0 ... number) {
		ret[i]=reader.i.readShort();
	}
	if (reader.Eof()) return null;
	return ret;
   }

   public static function _mm_read_M_SWORDS(number:Int,reader:MREADER):Array<SWORD> {
	BE(reader);
	var result=_mm_read_I_SWORDS(number,reader);
	LE(reader);
	return result;
   }

   public static function _mm_read_I_ULONGS(number:Int,reader:MREADER):Array<ULONG> {
	var ret=new Array<ULONG>();
	for (i in 0 ... number) {
		ret[i]=reader.i.readUnsignedInt();
	}
	if (reader.Eof()) return null;
	return ret;
   }


   public static function _mm_eof(reader:MREADER) {
	return reader.Eof();
   }


}




/*
 *      ========== Reader, Writer
 */

class MREADER {
	public var i:ByteArray;

	public function Seek(offset:Int,whence:Int):Bool {
	   if (whence==MMio.SEEK_SET) i.position=offset;
	   else if (whence==MMio.SEEK_CUR) i.position+=offset;
	   else { trace("Seek: bad whence="+whence); return false; }
	   return true;
	}
	public function Tell():Int {
	  return i.position;
	}
	public function Eof():Bool {
	   //return (i.bytesAvailable<=0);	// wrong
	   return false;			// Flash will throw EOFError anyway
	}

	public function new(i:ByteArray) {
	   this.i=i;
	   i.endian=Endian.LITTLE_ENDIAN;
	}
}


class MWRITER {
        public var Seek:MWRITER->Int->Int->Bool;
        public var Tell:MWRITER->Int;
        public var Write:MWRITER->Dynamic->Int->Bool;
        public var Put:MWRITER->Int->Bool;
}

