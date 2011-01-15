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
import hxmikmod.event.TrackerEvent;
import hxmikmod.Virtch;



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


   static var graphs:Hash<BitmapData>=new Hash();
   static var empty=new BitmapData(200, 30, false, 0x000030);



   public function new() {
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
	addChild(bm);
	addChild(pos);
	addChild(tf);
   }



   public function setPos(x:Int,increment:Float) {
	if (len==0) len=1;
	pos.x=Std.int(width*x/len);
	pos.y=0;
	this.increment=empty.width*increment*44100.0/(len*30.0);
   }



   public function onVoicePlay(e:hxmikmod.event.TrackerVoiceEvent) {
	var h=e.handle;
	var data=Virtch.Samples[h];
	if (data==null) return;
	len=e.size;
	tf.text=""+h+":"+Virtch.SampleNames[h];
	var bd=graphs.get(""+h);
	if (bd==null) {
	  bd= new BitmapData(empty.width, empty.height, false, 0x000030);
	  for (x in 0 ... Std.int(width)) {
		var i=Std.int(len*x/width);
		var y=Std.int(height/2+height*data[i]/65536);
		var col=0xffffff;
		if (y<0) { y=0; col=0xff0000; }
		else if (y>=Std.int(height)) { y=Std.int(height)-1; col=0xff0000; }
        	bd.setPixel(x,y,col);
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
		rep.width=empty.width*replen/len;
		rep.x=empty.width*reppos/len;
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

