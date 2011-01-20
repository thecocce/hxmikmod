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

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import hxmikmod.event.TrackerEvent;
import hxmikmod.event.TrackerEventDispatcher;
import flash.utils.ByteArray;
import flash.events.MouseEvent;
import flash.text.TextField;
import hxmikmod.Mem;

class Osc extends Sprite {
   var bm:Bitmap;
   var bmd:BitmapData;
   var enabled:Bool;
   var tf:TextField;

   public function new() {
	super();
	bm=new Bitmap(bmd=new BitmapData(400,120,false,0x00a000));
	addEventListener(MouseEvent.CLICK,onClick);
	tf=new TextField();
	tf.text="Click to enable";
        tf.autoSize=flash.text.TextFieldAutoSize.CENTER;
	setEnabled(false);
	addChild(bm);
   }


   function onClick(e:MouseEvent) {
	setEnabled(!enabled);
   }


   function setEnabled(e:Bool) {
	enabled=e;
	if (!e) {
		bmd.draw(tf);
        	TrackerEventDispatcher.removeEventListener(TrackerAudioBufferEvent.TYPE,onBuffer);
	} else {
        	TrackerEventDispatcher.addEventListener(TrackerAudioBufferEvent.TYPE,onBuffer);
		bmd.fillRect(new flash.geom.Rectangle(0,0,400,10),0x550000);
		bmd.fillRect(new flash.geom.Rectangle(0,110,400,10),0x550000);
	}
   }

   var bgcol:Bool;

   function onBuffer(e:TrackerAudioBufferEvent) {
	Profiler.ENTER();
	var addr=e.addr;
	var mult=400/e.audiobufsize;
	var left=Std.int((e.startpos>>3)*mult);
	var right=Std.int((e.endpos>>3)*mult);
	var savepos=addr.position;
	bmd.lock();
	bmd.fillRect(new flash.geom.Rectangle(left,10,right-left,100),bgcol?0x00a000:0x005000);
	//bgcol=!bcol;	// debug: show tickbuf change
	for (x in left ... right) {
	   addr.position=e.startpos+(Std.int((x-left)/mult)<<3);
	   var f=addr.readFloat();
	   f+=addr.readFloat();
	   var y=60+Std.int(f*25);
	   if (y<10) y=10; else if (y>110) y=110;
	   bmd.setPixel(x,y,0xffffff);
	}
	bmd.unlock();
	addr.position=savepos;
	Profiler.LEAVE();
   }

}
