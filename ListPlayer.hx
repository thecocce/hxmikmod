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
import flash.display.Shape;
import flash.display.Bitmap;
import flash.text.TextField;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.MouseEvent;
import flash.net.URLLoader;
import flash.net.URLRequest;
import hxmikmod.event.TrackerEvent;
import hxmikmod.event.TrackerEventDispatcher;
import hxmikmod.MikMod;
import hxmikmod.Player;
import hxmikmod.util.ProgressMeter;
import hxmikmod.MODULE;
import flash.display.Loader;

class ListPlayer extends Sprite {
   var prog:ProgressMeter;
   var loader:URLLoader;
   var songs:Array<String>;
   var btPause:Button;
   var btPrev:Button;
   var btNext:Button;
   var btLoop:Button;
   var btShuffle:Button;
   public static var buttonColor=0x000000;
   public static var hoverColor=0x808080;
   public static var pressColor=0xffffff;
   var current:Int;
   var paused:Bool;
   var mod:MODULE;
   var shuffle:Array<Int>;
   var skin:Bitmap;
   var skinloader:Loader;
   var playpos:TextField;

   public function new() {
	super();
        addChild(prog=new ProgressMeter(180,20));
	addChild(btPause=new Button(50,30,15,15,onPause,false));
	addChild(btPrev	=new Button(70,30,15,15,onPrev,false));
	addChild(btNext=new Button(90,30,15,15,onNext,false));
	addChild(btLoop=new Button(110,30,15,15,onLoop,true));
	addChild(btShuffle=new Button(130,30,15,15,onShuffle,true));
	skinloader=new Loader();
	skinloader.load(new URLRequest("skin.png"));
	skinloader.contentLoaderInfo.addEventListener(Event.INIT,skinLoaded);
	current=-1;
	paused=true;
   }

   function skinLoaded(e:Event) {
	addChild(skinloader.content);
	addChild(playpos=new TextField());
	playpos.x=10; playpos.y=20; playpos.text="--";
	playpos.width=40; playpos.height=20;
   }



   function init() {
	MikMod.Init(null);
	TrackerEventDispatcher.addEventListener(TrackerLoadingEvent.TYPE,onTrackerLoading);
	TrackerEventDispatcher.addEventListener(TrackerPlayPosEvent.TYPE,onPlayPos);
	var list=flash.Lib.current.loaderInfo.parameters.playlist;
	if (list==null) list="playlist.txt";
	loader=new URLLoader(new URLRequest(list));
	loader.addEventListener(Event.COMPLETE,onLoadList);
	loader.dataFormat=flash.net.URLLoaderDataFormat.TEXT;
   }

   function setStatus(s:String) {
        prog.onLoading(new TrackerLoadingEvent(0,s));
   }

   function onPlayPos(e:TrackerPlayPosEvent) {
	if (playpos!=null) playpos.text=""+e.pos+"/"+e.max;
	if (e.finished) onNext();
   }

   function onShuffle() {
	makeShuffle();
	btLoop.setState(false);
   }

   function onPause() {
	paused=!paused;
	if (paused) Player.Stop();
	else Player.Start(mod);
   }

   function onPrev() {
	gotoSong(current-1);
   }

   function onNext() {
	gotoSong(current+1);
   }

   function onLoop() {
	if (mod!=null) mod.wrap=btLoop.getState();
   }

   function onLoadList(e:Event) {
	var list:String=loader.data;
	songs=list.split("\n");
	for (s in songs) {
	  s=~/^\s+/.replace(s,"");
	  s=~/\s+$/.replace(s,"");
	  if (~/^\s*$/.match(s)) songs.remove(s);
	}
	gotoSong(0);
   }

   function gotoSong(i:Int) {
	if (songs==null || songs.length==0) return;
	if (i<0) i=songs.length-1;
	if (i>=songs.length) i=0;
	if (btShuffle.getState()) {
		if (shuffle==null) makeShuffle();
		i=shuffle[i];
	}
	var s=songs[i];
	if (s==null) return;
	if (current==i) return;
	Player.Stop();
	Player.LoadURL(s);
	current=i;
   }

   function makeShuffle() {
	shuffle=new Array();
	shuffle[0]=0;
	for (i in 1 ... songs.length) {
		var j=Std.int(Math.random()*(i+1));
		shuffle[i]=shuffle[j];
		shuffle[j]=i;
	}
   }


   function onError(event:IOErrorEvent) {
	setStatus(event.text);
   }



   // This will be called several times during the loading process.
   // state=LOADED when the module is ready to be played.

   public function onTrackerLoading(e:TrackerLoadingEvent) {
	if (e.state==TrackerLoadingEvent.LOADED) {
		Player.Start(mod=e.module);
		paused=false;
		mod.wrap=btLoop.getState();
	}
   }



   public static function main() {
	var p=new ListPlayer();
	flash.Lib.current.addChild(p);
	p.init();
   }



}


class Button extends Sprite {
	var shape:Shape;
	var handler:Void->Void;
	var stateful:Bool;
	var state:Bool;


	public function new(x:Int, y:Int, w:Int, h:Int,handler:Void->Void,stateful:Bool) {
		super();
		this.x=x; this.y=y;
		this.handler=handler;
		this.stateful=stateful;
		addChild(shape=new Shape());
		shape.graphics.beginFill(0x000000,0);
		shape.graphics.drawRect(0,0,w,h);
		shape.graphics.endFill();
		opaqueBackground=ListPlayer.buttonColor;
		addEventListener(MouseEvent.MOUSE_OVER,onEnter);
		addEventListener(MouseEvent.MOUSE_OUT,onLeave);
		addEventListener(MouseEvent.MOUSE_DOWN,onPress);
		addEventListener(MouseEvent.MOUSE_UP,onClick);
	}

	function onEnter(e:MouseEvent) {
		opaqueBackground=ListPlayer.hoverColor;
	}

	function onLeave(e:MouseEvent) {
		opaqueBackground=state?ListPlayer.pressColor:ListPlayer.buttonColor;
	}

	function onPress(e:MouseEvent) {
		if (stateful) state=!state;
		opaqueBackground=ListPlayer.pressColor;
	}

	function onClick(e:MouseEvent) {
		opaqueBackground=ListPlayer.hoverColor;
		if (handler!=null) handler();
	}


	public function getState() { return state; }
	public function setState(b:Bool) { state=b; onLeave(null); }

}
