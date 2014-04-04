package ftb.app.fbuilder;

import haxe.remoting.Context;
import haxe.xml.Parser;

import flash.geom.Point;
import flash.display.Sprite;
import flash.display.Loader;
import flash.net.URLRequest;
import flash.net.URLLoader;
import flash.events.IOErrorEvent;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.text.StyleSheet;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.ui.Mouse;
import flash.ui.MouseCursor;
import flash.Lib;

import swhx.Connection;

import ftb.app.fbuilder.FBuilder.Target;

using StringTools;

/**
* FBuilder
* written by Michal Romecki (contact@mromecki.fr, filt3r@free.fr)
* v0.95
*
*/

class Target extends Sprite {
	public var color	: Int;
	public var script	: String;
	
	public function new( name : String, color : Int, script : String ) {
		super();
		this.name	= name;
		this.color	= color;
		this.script	= script;
	}
}

class FBuilder {
	
	var _CLICK_EDGE	= 2;
	var _STICK_EDGE	= 20.0;
	var _MARGIN		= 5;

	var _cnx		: Connection;
	var _targets	: Sprite;
	var _consoleBtn	: Sprite;
	var _resizeBtn	: Sprite;
	var _console	: Sprite;
	var _consoleTF	: TextField;
	var _offsetX	: Float;
	var _offsetY	: Float;
	var _css		: StyleSheet;
	var _urlConfig	: String;
	
	var _oldPos		: Point;
	
	public function new( urlConfig : String ) {
		Lib.current.stage.align 		= flash.display.StageAlign.TOP_LEFT;
		Lib.current.stage.scaleMode 	= flash.display.StageScaleMode.NO_SCALE;

		_urlConfig	= urlConfig;
		
		try {
			var ctx		= new Context();
				ctx.addObject( "FBuilder", this );
			_cnx 	= swhx.Connection.desktopConnect( ctx );
			_cnx.App.onFlashInitialized.call( [] );
		}catch ( e : Dynamic ) { }
		
		var scss	= '.btn{font-family:"Lucida Console";}.out{font-family:"Lucida Console";color:#FFFFFF;}.err{font-family:"Lucida Console";color:#FF0000;}';
		_css		= new StyleSheet();
			_css.parseCSS( scss );
			
		_console					= new Sprite();
		
		_consoleTF					= new TextField();
		_consoleTF.background		= true;
		_consoleTF.backgroundColor	= 0;
		_consoleTF.width			= 640;
		_consoleTF.height			= 480;
		_consoleTF.styleSheet		= _css;
		_consoleTF.multiline		= true;
		_consoleTF.wordWrap			= true;
		
		_resizeBtn	= new Sprite();
		_resizeBtn.graphics.beginFill( 0xFFFFFF );
		_resizeBtn.graphics.moveTo( 16, 0 );
		_resizeBtn.graphics.lineTo( 0, 16 );
		_resizeBtn.graphics.lineTo( 16, 16 );
		_resizeBtn.graphics.endFill();
		_resizeBtn.x	= _consoleTF.x + _consoleTF.width - _resizeBtn.width - 1;
		_resizeBtn.y	= _consoleTF.y + _consoleTF.height - _resizeBtn.height - 1;
		_resizeBtn.addEventListener( MouseEvent.MOUSE_OVER, cb_resizeOver );
		_resizeBtn.addEventListener( MouseEvent.MOUSE_OUT, cb_resizeOut );
		_resizeBtn.addEventListener( MouseEvent.MOUSE_DOWN, cb_resizeDown );
		_resizeBtn.buttonMode	= true;
		
		_console.addChild( _consoleTF );
		_console.addChild( _resizeBtn );
		
		var tf				= new TextField();
			tf.selectable	= false;
			tf.autoSize		= TextFieldAutoSize.LEFT;
			tf.textColor	= 0xFFFFFF;
			tf.styleSheet	= _css;
			tf.text			= '<p class="btn">Console</p>';
			
		_consoleBtn	= new Sprite();
		_consoleBtn.graphics.beginFill( 0 );
		_consoleBtn.graphics.drawRect( 0, 0, tf.width + _MARGIN * 2, tf.height + _MARGIN * 2 );
		_consoleBtn.graphics.endFill();
		_consoleBtn.addEventListener( MouseEvent.MOUSE_DOWN, cb_moveDown );
		_consoleBtn.buttonMode		= true;
		_consoleBtn.mouseChildren	= false;
		
		tf.x	= ( _consoleBtn.width - tf.width ) * .5;
		tf.y	= ( _consoleBtn.height - tf.height ) * .5;
		
		_consoleBtn.addChild( tf );
		
		_targets	= new Sprite();
		log( "FBuilder v0.95 - Michal Romecki (contact@mromecki.fr, filt3r@free.fr)" );
	}
	
	public function destroy() {
		while ( _targets.numChildren > 0 ) {
			var target	: Target	= cast _targets.getChildAt( 0 );
				target.removeEventListener( MouseEvent.CLICK, cb_click );
		}
		
		_resizeBtn.removeEventListener( MouseEvent.MOUSE_OVER, cb_resizeOver );
		_resizeBtn.removeEventListener( MouseEvent.MOUSE_OUT, cb_resizeOut );
		_resizeBtn.removeEventListener( MouseEvent.MOUSE_DOWN, cb_resizeDown );
		_resizeBtn.removeEventListener( MouseEvent.MOUSE_UP, cb_resizeUp );
		
		_consoleBtn.removeEventListener( MouseEvent.MOUSE_DOWN, cb_moveDown );
		_consoleBtn.removeEventListener( MouseEvent.MOUSE_UP, cb_moveUp );

		Lib.current.stage.addEventListener( MouseEvent.MOUSE_UP, cb_resizeUp );
		Lib.current.stage.removeEventListener( MouseEvent.MOUSE_UP, cb_moveUp );
		Lib.current.removeEventListener( Event.ENTER_FRAME, cb_resizeOef );
		Lib.current.removeEventListener( Event.ENTER_FRAME, cb_moveOef );
		
		while ( Lib.current.numChildren > 0 ) {
			Lib.current.removeChildAt( 0 );
		}
	}
	
	function cb_moveDown(_) {
		_offsetX	= Lib.current.mouseX;
		_offsetY	= Lib.current.mouseY;
		_oldPos		= new Point( Lib.current.x, Lib.current.y );
		_consoleBtn.addEventListener( MouseEvent.MOUSE_UP, cb_moveUp );
		Lib.current.stage.addEventListener( MouseEvent.MOUSE_UP, cb_moveUp );
		Lib.current.addEventListener( Event.ENTER_FRAME, cb_moveOef );
	}
	
	function cb_moveUp(_) {
		Lib.current.removeEventListener( Event.ENTER_FRAME, cb_moveOef );
		_consoleBtn.removeEventListener( MouseEvent.MOUSE_UP, cb_moveUp );
		Lib.current.stage.removeEventListener( MouseEvent.MOUSE_UP, cb_moveUp );
		if ( Math.abs( Lib.current.x - _oldPos.x ) < _CLICK_EDGE && Math.abs( Lib.current.y - _oldPos.y ) < _CLICK_EDGE ) {
			if ( Lib.current.contains( _console ) ) {
				Lib.current.removeChild( _console );
			}else {
				Lib.current.addChild( _console );
			}
		}
	}
	
	function cb_moveOef(_) {
		var x	= Lib.current.stage.mouseX - _offsetX;
		var y	= Lib.current.stage.mouseY - _offsetY;
		
		if ( Math.abs( x ) < _STICK_EDGE )	x	= 0;
		if ( Math.abs( Lib.current.stage.stageWidth - ( x + Lib.current.width ) ) < _STICK_EDGE )	x	= Lib.current.stage.stageWidth - Lib.current.width;
		if ( Math.abs( y ) < _STICK_EDGE )	y	= 0;
		if ( Math.abs( Lib.current.stage.stageHeight - ( y + Lib.current.height ) ) < _STICK_EDGE )	y	= Lib.current.stage.stageHeight - Lib.current.height;
		
		Lib.current.x	= x;
		Lib.current.y	= y;
	}
	
	function cb_resizeOver(_) {
		Mouse.cursor = MouseCursor.HAND;
	}
	
	function cb_resizeOut(_) {
		Mouse.cursor = MouseCursor.AUTO;
	}
	
	function cb_resizeDown(_) {
		_offsetX	= _resizeBtn.mouseX;
		_offsetY	= _resizeBtn.mouseY;
		_resizeBtn.addEventListener( MouseEvent.MOUSE_UP, cb_resizeUp );
		Lib.current.stage.addEventListener( MouseEvent.MOUSE_UP, cb_resizeUp );
		Lib.current.addEventListener( Event.ENTER_FRAME, cb_resizeOef );
	}
	
	function cb_resizeUp(_) {
		_resizeBtn.removeEventListener( MouseEvent.MOUSE_UP, cb_resizeUp );
		Lib.current.stage.removeEventListener( MouseEvent.MOUSE_UP, cb_resizeUp );
		Lib.current.removeEventListener( Event.ENTER_FRAME, cb_resizeOef );
	}
	
	function cb_resizeOef(_) {
		var x	= _console.mouseX - _offsetX;
		var y	= _console.mouseY - _offsetY;
		
		_resizeBtn.x	= x;
		_resizeBtn.y	= y;
		
		_consoleTF.width	= x + _resizeBtn.width + 1;
		_consoleTF.height	= y + _resizeBtn.height + 1;
	}
	
	public function run() {
		var ul = new URLLoader();
			ul.addEventListener( Event.COMPLETE, cb_parseXml );
			ul.addEventListener( IOErrorEvent.IO_ERROR, function( e ) {
				createIcons();
				draw();
				log( '<p class="err">$_urlConfig not found</p>' );
			});
			ul.load( new URLRequest( _urlConfig ) );
	}
		
	function cb_parseXml( e : Event ) {
		var ul : URLLoader = e.target;
		ul.removeEventListener( Event.COMPLETE, cb_parseXml );
				
		var xml = Parser.parse( ul.data ).firstElement();
		if ( xml.exists( "stick-edge" ) ) {
			var fl	= Std.parseFloat( xml.get( "stick-edge" ) );
			if ( !Math.isNaN( fl ) )	_STICK_EDGE	= fl;
		}
		for ( ndtarget in xml.elements() ) {
			var s	= null;
			if( ndtarget.firstChild() != null ){
				var nv	= StringTools.trim( ndtarget.firstChild().nodeValue.split( "\r\n" ).join( "\n" ) ).split( "\n" );
				var a = [];
				for ( i in nv ) {
					a.push( StringTools.startsWith( i, "\t\t" ) ? i.substr( 2 ) : i );
				}
				s	 = a.join( "\n" );
			}else {
				s	= "\"No command/script found\";";
			}
			var target	= new Target( ndtarget.get( "name" ), Std.parseInt( "0x" + ndtarget.get( "color" ).split( "#" ).join( "" ).split( "0x" ).join( "" ) ), s );
			_targets.addChild( target );
		}
		createIcons();
		draw();
	}
	
	function createIcons() {
		var x	= _consoleBtn.x + _consoleBtn.width + _MARGIN;
		
		for ( i in 0..._targets.numChildren ) {
			var target	: Target	= cast _targets.getChildAt( i );
			var tf					= new TextField();
				tf.selectable		= false;
				tf.styleSheet		= _css;
				tf.text				= '<p class="btn">${ target.name }</p>';
				tf.autoSize			= TextFieldAutoSize.LEFT;
			
			target.graphics.beginFill( target.color );
			target.graphics.drawRect( 0, 0, tf.width + _MARGIN * 2, tf.height + _MARGIN * 2 );
			target.graphics.endFill();
			target.addEventListener( MouseEvent.CLICK, cb_click );
			target.buttonMode		= true;
			target.mouseChildren	= false;
			target.x				= x;
			
			tf.x	= ( target.width - tf.width ) * .5;
			tf.y	= ( target.height - tf.height ) * .5;

			target.addChild( tf );
			
			x	+= target.width + _MARGIN;
		}
	}
	
	function draw() {
		Lib.current.addChild( _console );
		Lib.current.addChild( _consoleBtn );
		Lib.current.addChild( _targets );
		_console.y	= _consoleBtn.y + _consoleBtn.height + _MARGIN;		
	}
	
	function cb_click( e : MouseEvent ) {
		var target : Target = cast e.currentTarget;
		log( 'Launching ${ target.name } :' );
		log( target.script );
		log( 'Result :' );
		log( _cnx.App.script.call( [ target.script ] ) );
	}
	
	function log( d : Dynamic ) {
		var s	= "";
		if ( d != null ) {
			var t	= Type.typeof( d );
			switch( t ) {
				case TObject	:
					if( d.err != null || d.out != null ){
						if ( d.err != null && d.err != "" ) {
							s	= '<p class="err">' + format( d.err ) + '</p><br />';
						}
						if ( d.out != null && d.out != "" ) {
							s	+= '<p class="out">' + format( d.out ) + ' </p><br />';
						}
					}else {
						s	= '<p class="out">' + format( Std.string( d ) ) + '</p>';
					}
				case TClass( String )	:
					s	= '<p class="out">' + format( d ) + '</span>';
				default	:
					s	= '<p class="out">'  + format( Std.string( d ) ) + '</p>';
			}
		}
		_consoleTF.htmlText	= _consoleTF.htmlText + s + "<br />";
		_consoleTF.scrollV	= 10000;
	}
	
	function format( s : String ) {
		return s.split( "\r\n" ).join( "<br />" ).htmlEscape();
	}
	
	public function reload() {
		while ( _targets.numChildren > 0 ) {
			var target	: Target	= cast _targets.getChildAt( 0 );
				target.removeEventListener( MouseEvent.CLICK, cb_click );
				_targets.removeChild( target );
		}
		run();
	}
	
	public function clearConsole() {
		_consoleTF.htmlText	= "";
	}
	
	public static function main() {
		var arg	: Dynamic	= Reflect.fields( Lib.current.loaderInfo.parameters )[ 0 ];
		if ( arg == null || StringTools.trim( arg ) == "" )	arg	= "project.fbxml";
		
		var v	= new FBuilder( arg );
		v.run();		
	}
}