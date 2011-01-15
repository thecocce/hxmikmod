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
	}
   }


   function onBuffer(e:TrackerAudioBufferEvent) {
	Profiler.ENTER();
	var buf=e.buffer;
	var bufsize=buf.position;
	bmd.lock();
        bmd.fillRect(bmd.rect, 0x005500);
	bmd.fillRect(new flash.geom.Rectangle(0,0,400,10),0x550000);
	bmd.fillRect(new flash.geom.Rectangle(0,110,400,10),0x550000);
	for (x in 0 ... Std.int(width)) {
	   buf.position=Std.int(bufsize*x/width)&0xfffffff8;
	   var y=(buf.readFloat()+buf.readFloat())/2;
	   var yi=Std.int(60+50*y);
	   bmd.setPixel(x,yi,0xffffff);
	}
	bmd.unlock();
	buf.position=bufsize;
	Profiler.LEAVE();
   }

}
