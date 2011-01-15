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
import hxmikmod.event.TrackerEvent;
import hxmikmod.event.TrackerEventDispatcher;
import hxmikmod.util.ProgressMeter;
import hxmikmod.MikMod;
import hxmikmod.Player;
import flash.events.MouseEvent;


class MultiPlayer extends Sprite {
   var osc:Osc;
   //var nm:NotesMeter;
   var prog:ProgressMeter;
   var tfProfiler:TextField;
   var indicators:Array<SampleIndicator>;
   var summarycounter:Int;	// update profiling info every 16th frame only
   var sel:SongSelect;


   public function new() {
	super();
   }


   function initGUI() {
	osc=new Osc();
	addChild(osc);
	osc.x=450; osc.y=20;
	//nm=new NotesMeter();
	//addChild(nm);
	//nm.x=450; nm.y=20;
	tfProfiler=new TextField();
	addChild(tfProfiler);
	tfProfiler.width=400; tfProfiler.height=400;
	tfProfiler.x=450; tfProfiler.y=230;
	prog=new ProgressMeter(400,30);
	addChild(prog);
	prog.x=450; prog.y=150;
	indicators=new Array();
	sel=new SongSelect(onSelect);
	sel.add("Cascade.xm","Radix - Cascade.xm");
	sel.add("Chiptjat.mod","Radix - Chiptjat.mod");
	sel.add("compulsion.mod","Lizardking - Compulsion to Obey");
	sel.add("enigma.mod","Tip&Firefox - The Final Hyperbase");
	sel.add("harlet.mod","Barry Leitch - Harlequin Title");
	sel.add("mod.audiokraft","Tor Gausen - Audiokraft");
	sel.add("mod.we're the devils","Tor Gausen - We're the Devils");
	sel.add("QSN-MAG.IT","Quasian - Magenta Magnet");
	sel.add("radix-imaginary_friend.xm","Radix - Imaginary Friend");
	sel.add("sac14.mod","Maktone - sac14.mod");
	sel.add("radix-yuki_satellites.xm","Radix - Yuki Satellites");
	sel.add("random_voice-monday.mod","Random Voice - Monday");
	sel.add("S3M.Satellite one.","Purple Motion - Satellite one");
	sel.add("S3M.World of plastic","Purple Motion - World of Plastic");
	sel.add("younme.xm","Radix - You & Me");
	addChild(sel);
	sel.x=450;
	sel.y=190;
	prog.onLoading(new TrackerLoadingEvent(0,"Please select a song below"));
   }







   function init() {
	initGUI();
	var params:Hash<Dynamic>=new Hash();
	params.set("buffer_size",4096);
	MikMod.Init(params);
	TrackerEventDispatcher.addEventListener(TrackerLoadingEvent.TYPE,onTrackerLoading);
	TrackerEventDispatcher.addEventListener(TrackerSamplePosEvent.TYPE,onSamplePos);
	TrackerEventDispatcher.addEventListener(TrackerVoiceEvent.TYPE,onVoicePlay);
        stage.addEventListener(flash.events.Event.ENTER_FRAME,onEnterFrame);
   }




   function onEnterFrame(e:Dynamic) {
	for (i in indicators) if (i!=null) i.update();
	//nm.update();
        if (summarycounter++&15!=0) return;
        Profiler.Summary(tfProfiler);
   }


   function onSelect(url:String) {
	Player.Stop();
	Player.LoadURL(url);
   }


   public function onVoicePlay(e:TrackerVoiceEvent) {
	var v=e.voice;
	try {
	   if (indicators[v]==null) {
	      var i=indicators[v]=new SampleIndicator();
	      addChild(i);
	      i.x=4;
	      i.y=v*33+4;
	      if (v>=16) { i.x+=210; i.y-=16*33; }
	   }
	   indicators[v].onVoicePlay(e);
	} catch(e:Dynamic) { trace(e); }
   }


   public function onSamplePos(e:hxmikmod.event.TrackerSamplePosEvent) {
	try {
	   var v=e.voice;
	   var i=indicators[v];
	   if (i!=null) i.setPos(e.pos,e.increment);
	} catch(e:Dynamic) { trace(e); }
   }





   public function onTrackerLoading(e:TrackerLoadingEvent) {
	if (e.state==TrackerLoadingEvent.LOADED) {
		Profiler.reset();
		// new song, reset sample graphics
		for (i in indicators) if (i!=null) removeChild(i);
		indicators=new Array();
		for (i in 0 ... te.module.numchn) onVoicePlay(new TrackerVoiceEvent(i,-1,0,0,0,0,0));
		Player.Start(e.module);
	}
   }


   public static function main() {
	var p=new MultiPlayer();
	flash.Lib.current.addChild(p);
	p.init();
   }



}
