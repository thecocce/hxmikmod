
all: MultiPlayer.swf SimplePlayer.swf

MultiPlayer.swf: *.hx compile.hxml hxmikmod/*.hx hxmikmod/event/*.hx hxmikmod/loaders/*.hx
	haxe compile.hxml

SimplePlayer.swf: SimplePlayer.hx compile2.hxml
	haxe compile2.hxml


	
.PHONY: clean
clean:
	rm -f MultiPlayer.swf SimplePlayer.swf *~

