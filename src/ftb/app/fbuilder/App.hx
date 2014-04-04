package ftb.app.fbuilder;

import haxe.remoting.Context;
import neko.vm.Thread;

import sys.FileSystem;
import sys.io.Process;
import sys.io.File;

import systools.win.Tray;
import systools.win.Menus;
import systools.win.Events;
import systools.Display;
import systools.Dialogs;

import swhx.Application;
import swhx.Window;
import swhx.Flash;
import swhx.Connection;

import hscript.Interp;
import hscript.Parser;

/**
* FBuilder
* written by Michal Romecki (contact@mromecki.fr, filt3r@free.fr)
* v0.95
*
*/

class App {
	static var _iconTray	: Tray;
	static var _window		: Window;
	static var _swf			: Flash;
	static var _cnx			: Connection;
	static var _projectDir	: String;
	static var _interp		: Interp;
	static var _parser		: Parser;
	
	static var _cmd		: String;
	static var _args	: Array<String>;
	static function command( cmd : String, args : Array<String>, keepPrompt = false ) {
		_args	= args;
		_args.unshift( cmd );
		if ( keepPrompt ) {
			_args.unshift( "/k" );
			_cmd	= "cmd";
		}else {
			_args.unshift( "/B" );
			_cmd	= "start";
		}
		
		Thread.create( _command );
		return null;
	}
	static function _command() {
		Sys.command( _cmd, _args );	
	}
	
	static function script( s : String ) : Dynamic {
		var program = _parser.parseString( s );
		try {
			return _interp.execute( program );
		}catch ( e : Dynamic ) {
			return { err : 'Error : $e' };
		}
	}
	
	static function execute( cmd : String, args : Array<String> ) {
		var p	= new Process( cmd, args );
		var out	= p.stdout.readAll().toString();
		var err	= p.stderr.readAll().toString();
		return { out : out, err : err }
	}
		
	static function createPopupMenu() {
		var menu = new Menus( true );
		menu.addItem( "Clear console", 1 );
		menu.addItem( "Reload", 2 );
		menu.addItem( "Exit", 3 );
		_window.onRightClick = function() {
			switch( menu.showPopup( _window.handle ) )	{
				case 1	:	
					_cnx.FBuilder.clearConsole.call( [] );
				case 2	:	
					_cnx.FBuilder.reload.call( [] );
				case 3	:	exit();
			}
			return false;
		}
	}
	
	static function createIconTray() {	
		_iconTray = new Tray( _window, "fbuilder.ico", "FBuilder" );
			
		var trayMenu = new Menus( true );
		trayMenu.addItem( "Reload", 1 );
		trayMenu.addItem( "Exit", 2 );
		
		var trayHook = _window.addMessageHook( Events.TRAYEVENT );
		trayHook.setNekoCallback( function () {
			if ( Std.string( trayHook.p2 ) == Std.string( Events.RBUTTONUP ) )	{
				switch( trayMenu.showPopup( _window.handle ) )	{
					case 1	:	
						_cnx.FBuilder.reload.call( [] );
					case 2	:	exit();
				}
			}
			return 0;
		});
	}
	
	static function exit()	{	
		if( _iconTray != null ){
			_iconTray.dispose();
		}
		Application.exitLoop();
		//Application.cleanup();
	}
	
	static function onFlashInitialized() {
		_cnx = Connection.flashConnect( _swf );
		_window.show( true );
		Sys.setCwd( _projectDir );
		createPopupMenu();
		createIconTray();
	}
	
	static function main()	{
		try	{
			var args	= Sys.args();
			if ( args.length == 1 ) {
				throw "Specify a project xml file";
			}
			var a	= args[ 1 ].split( "\\" );
				a.pop();
			_projectDir = a.join( "/" );

			Application.init();
			
			var fileName	= args[ 1 ];
			var xml			= haxe.xml.Parser.parse( File.getContent( fileName ) ).firstElement();
			var taskbar		= xml.exists( "taskbar" ) ? xml.get( "taskbar" ) == "true" ? 0 : Window.WF_NO_TASKBAR : Window.WF_NO_TASKBAR;
			var aot			= xml.exists( "always-on-top" ) ? xml.get( "always-on-top" ) == "false" ? 0 : Window.WF_ALWAYS_ONTOP : Window.WF_ALWAYS_ONTOP;

			var screenSize 	= Display.getScreenSize();
			_window 		= new Window( "FBuilder", screenSize.w, screenSize.h, Window.WF_TRANSPARENT + taskbar + aot );
			
			_parser 		= new Parser();
			_interp 		= new Interp();
			
			_interp.variables.set( "Sys", Sys );
			_interp.variables.set( "StringTools", StringTools );
			_interp.variables.set( "sys", 
				{
					FileSystem	: FileSystem,
					io	: {
						File	: File,
						Process	: Process,
					}
				}
			);
			_interp.variables.set( "execute", execute );
			_interp.variables.set( "process", execute );
			_interp.variables.set( "command", command );
						
			var context = new Context();
				context.addObject( "App", App );
										
			_swf = new Flash( _window, context );
			_swf.setAttribute( "flashvars", fileName );
			_swf.setAttribute( "src", "FBuilder.swf" );
			_swf.start();
			
			Application.loop();
			Application.exitLoop();
			//Application.cleanup();

		} catch ( e : String ) {
			Dialogs.message( "Error", e, true );
			exit();
		}
    }
}