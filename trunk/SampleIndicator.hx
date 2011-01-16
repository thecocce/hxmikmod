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
import flash.display.Shape;
import flash.display.Sprite;
import flash.text.TextField;
import flash.events.MouseEvent;
import hxmikmod.event.TrackerEvent;
import hxmikmod.Virtch;
import hxmikmod.Mem;



// A little box showing an approximate graph of the sample being played.
// The current play position is indicated by a line, and the repeat
// loop (if any) as a blue area.


class SampleIndicator extends Sprite {
   var bm:Bitmap;
   var pos:Shape;
   var rep:Shape;
   var len:Int;
   var tf:TextField;   
   var increment:Float;
   var muted:Bool;
   var index:Int;
   var bg:Shape;

   static var graphs:Hash<BitmapData>=new Hash();
   static var empty=new BitmapData(200, 30, false, 0x000030);



   public function new(i:Int) {
        super();
	bm=new Bitmap();
	bm.bitmapData=empty;
	pos=new Shape();
	pos.graphics.beginFill(0x2060a0);
	pos.graphics.drawRect(0,0,1,30);
	pos.graphics.endFill();
	tf=new TextField();
	tf.x=5; tf.y=0;
	tf.textColor=0xffff00;
	tf.width=190;
	tf.height=20;
	bg=new Shape();
	bg.graphics.beginFill(0x000030);
	bg.graphics.drawRect(0,0,empty.width,empty.height);
	bg.graphics.endFill();
	addChild(bg);
	addChild(bm);
	addChild(pos);
	addChild(tf);
	setMuted(false);
	index=i;
	addEventListener(MouseEvent.CLICK,onClick);
   }


   function onClick(e:MouseEvent) {
	setMuted(!muted);
   }

   function setMuted(m:Bool) {
	muted=m;
	try {
	   hxmikmod.MPlayer.pf.control[index].muted=m;	// quick, dirty, etc
	   bg.graphics.beginFill(muted?0x800000:0x000030);
	   bg.graphics.drawRect(0,0,empty.width,empty.height);
	   bg.graphics.endFill();
	} catch(e:Dynamic) { }
   }


   public function setPos(x:Float,increment:Float) {
	if (len==0) len=1;
	var px=width*x/len;
	if (px<0) px=0;
	else if (px>width) px=width;	// nonsensical values may cause long freezes
	pos.x=px;
	pos.y=0;
	this.increment=empty.width*increment*44100.0/(len*30.0);
   }



   public function onVoicePlay(e:hxmikmod.event.TrackerVoiceEvent) {
	var h=e.handle;
	if (h==-1) return;
	var data=Virtch.Samples[h];
	if (data==-1) return;
	len=e.size;
	tf.text=""+h+":"+Virtch.SampleNames[h];
	var bd=graphs.get(""+h);
	if (bd==null) {
	  bd= new BitmapData(empty.width, empty.height, true, 0x000030);
	  for (x in 0 ... Std.int(width)) {
		var i=Std.int(len*x/width);
		var y=Std.int(height/2+height*Mem.getFloat(data+(i<<2))*0.5);
		var col=0xffffff;
		if (y<0) { y=0; col=0xff0000; }
		else if (y>=Std.int(height)) { y=Std.int(height)-1; col=0xff0000; }
        	bd.setPixel32(x,y,col|0xff000000);
	  }
	  graphs.set(""+h,bd);
        }
	bm.bitmapData=bd;
	if (e.reppos>=0 || e.repend>=0) {
		var replen=e.repend-e.reppos;
		var reppos=e.reppos;
		if (rep==null) {
		   rep=new Shape();
		   rep.graphics.beginFill(0xff);
		   rep.graphics.drawRect(0,0,1,empty.height);
		   rep.graphics.endFill();
		   rep.alpha=0.2;
		   addChild(rep);
		}
		if (reppos<0) reppos=0; else if (reppos>len) reppos=len;
		if (replen<0) replen=0; else if (reppos+replen>len) replen=len-reppos;
		var rw=empty.width*replen/len;
		var rx=empty.width*reppos/len;
		if (rx<0 || rx>width) { rx=0; }
		if (rw<0 || rw>width) { rw=1; }
		rep.width=rw;
		rep.x=rx;
	}
	setPos(e.start,0);
   }


   public function update() {
	if (increment==Math.NaN || pos==null) return;  // ??
	pos.x+=increment;
	if (pos.x<0) pos.x=0;
	else if (pos.x>empty.width-1) pos.x=empty.width-1;
   }

}

