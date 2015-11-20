# How to embed #

Example: [here](http://zulu-51.nebula.fi/~modplayer/hxMikMod/SimplePlayer.swf)(a 74k file playing a module by Radix).

The easiest way for haXe is to use the haxe.Resource API as described [here](http://haxe.org/doc/advanced/resources).

```

Player.LoadBytes(haxe.Resource.getBytes("tune_resource_id").getData(),32,false);

```

You will also need an event listener to start playback when the resource has been loaded, the same way as with URL loading.