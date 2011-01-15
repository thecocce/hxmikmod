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



import flash.display.Sprite;
import flash.text.TextField;
import flash.events.MouseEvent;
import flash.display.DisplayObject;
import flash.display.Shape;




class SongSelect extends Sprite {
   var names:Array<String>;
   var urls:Array<String>;
   var expanded:Bool;
   var selectedIndex:Int;
   var onSelect:String->Void;
   var border:Shape;

   public function new(onSelect:String->Void) {
	super();
	names=new Array();
	urls=new Array();
	border=new Shape();
        border.graphics.lineStyle(2,0xc0c0c0);
        border.graphics.drawRect(1,1,200-2,16-2);
	addChild(border);
	var tf=new TextField();
	tf.text="(select song)";
	addChild(tf);
	tf.height=16; tf.width=200;
	tf.selectable=false;
	opaqueBackground=0x4040ff;
	setExpanded(false);
	tf.addEventListener(MouseEvent.MOUSE_DOWN,onDown);
	addEventListener(MouseEvent.MOUSE_UP,onUp);
	addEventListener(MouseEvent.MOUSE_OUT,close);
	selectedIndex=0;
	this.onSelect=onSelect;
   }



   public function close(e:MouseEvent) {
	var x=e.localX;
	var y=e.localY;
	if (e.target!=this) { x+=e.target.x; y+=e.target.y; }
	if (x>=0 && x<width && y>=0 && y<height) return;
	selectedIndex=0;
	setExpanded(false);
   }



   function onDown(e:MouseEvent) {
	setExpanded(true);
   }



   function onUp(e:MouseEvent) {
	setExpanded(false);
	if (selectedIndex!=0 && onSelect!=null) onSelect(urls[selectedIndex-1]);
   }



   public function setExpanded(e:Bool) {
	expanded=e;
	for (i in 2 ... numChildren) {
		var c=getChildAt(i);
		c.visible=e;
		c.y=e?(i-1)*16:0;
	}
   }



   public function add(url:String, name:String) {
	names.push(name);
	urls.push(url);
	var n=names.length;
	var tf=new TextField();
	tf.x=0;
	tf.y=expanded?n*16:0;
	tf.width=200;
	tf.height=16;
	tf.text=name;
	tf.selectable=false;
	tf.visible=expanded;
	tf.addEventListener(MouseEvent.MOUSE_OVER,onOver);
	tf.addEventListener(MouseEvent.MOUSE_OUT,onOut);
	addChild(tf);
   }



   function onOver(e:MouseEvent) {
	var tf=cast(e.target,TextField);
	tf.opaqueBackground=0xc0c0c0;
	selectedIndex=Std.int(tf.y/16);
   }




   function onOut(e:MouseEvent) {
	var tf=cast(e.target,TextField);
	tf.opaqueBackground=null;
	if (selectedIndex==Std.int(tf.y/16)) selectedIndex=0;
   }


}

