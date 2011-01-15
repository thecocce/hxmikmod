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
import hxmikmod.event.TrackerEventDispatcher;
import hxmikmod.Virtch;


// this is not good


class NotesMeter extends Sprite {

   var notes:Array<Shape>;
   var bg:Shape;


   public function new() {
	super();
	notes=new Array();
	bg=new Shape();
	bg.graphics.beginFill(0);
	bg.graphics.drawRect(0,0,256,30);
	bg.graphics.endFill();
	addChild(bg);
	TrackerEventDispatcher.addEventListener(TrackerNoteEvent.TYPE,onTrackerEvent);
   }

   public function onTrackerEvent(e:TrackerEvent) {
    try {
	var ne=cast(e,hxmikmod.event.TrackerNoteEvent);
	var c=ne.channel;
	var n=notes[c.note];
	if (n==null) {
	   n=new Shape();
	   n.graphics.beginFill(0x00a000);
	   n.graphics.drawRect(0,0,1,1);
	   n.graphics.endFill();
	   addChild(n);
	   n.x=c.note*2;
	   n.y=30; n.width=1; n.height=30;
	   notes[c.note]=n;
	}
	n.height=30*c.outvolume/256.0;
	n.y=30-n.height;
     } catch(d:Dynamic) { trace(d); }
   }

   public function update() {
	for (n in notes) {
	   if (n==null) continue;
	   if (n.height>0) {
		n.height--;
		if (n.height<0) n.height=0;
		n.y=30-n.height;
	   }
	}
   }


}
