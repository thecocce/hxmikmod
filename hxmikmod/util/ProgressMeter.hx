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

package hxmikmod.util;

import flash.display.Shape;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.display.Sprite;
import hxmikmod.event.TrackerEvent;
import hxmikmod.event.TrackerEventDispatcher;



class ProgressMeter extends Sprite {
   var tf:TextField;
   var bg:Shape;
   var prog:Shape;

   public function new(w:Float,h:Float) {
	super();
	bg=new Shape();
        bg.graphics.beginFill(0x700000);
        bg.graphics.drawRect(0,0,w,h);
        bg.graphics.endFill();
	bg.graphics.lineStyle(2,0xc0c0c0);
	bg.graphics.drawRect(2,2,w-4,h-4);
	addChild(bg);
	prog=new Shape();
	prog.graphics.beginFill(0x00a000);
	prog.graphics.drawRect(0,0,w-4,h-4);
	prog.graphics.endFill();
	prog.x=2; prog.y=2;
	addChild(prog);
	tf=new TextField();
	addChild(tf);
	tf.x=0; tf.y=4; tf.width=w;
	tf.autoSize=TextFieldAutoSize.CENTER;
	TrackerEventDispatcher.addEventListener(TrackerLoadingEvent.TYPE,onLoading);
   }



   public function onLoading(e:TrackerLoadingEvent):Void {
//	if (e.progress!=1) e.message+=" ("+Std.int(100*e.progress)+"%)";
	if (e.progress>1) e.progress=1;
	tf.text=e.message;
	prog.width=e.progress*(bg.width-4);
   }
   

}
