package states;

import lime.system.ThreadPool;
import lime.app.Promise;
import lime.app.Future;

import flixel.FlxState;

import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;
import flixel.graphics.FlxGraphic;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;

import sys.thread.Thread;

import backend.StageData;

import haxe.io.Path;

class LoadingState extends MusicBeatState
{
	inline static var MIN_TIME = 1.0;

	// Browsers will load create(), you can make your song load a custom directory there
	// If you're compiling to desktop (or something that doesn't use NO_PRELOAD_ALL), search for getNextState instead
	// I'd recommend doing it on both actually lol
	
	// TO DO: Make this easier
	
	var target:FlxState;
	var stopMusic = false;
	var directory:Array<String>;
	var callbacks:MultiCallback;
	var targetShit:Float = 0;
	static var percent:Int = 0;
	var transitioning:Bool = false;
	var keyArray:Array<String> = [];

	function new(target:FlxState, stopMusic:Bool, directory:Array<String>)
	{
		super();
		this.target = target;
		this.stopMusic = stopMusic;
		this.directory = directory;
	}

	var funkay:FlxSprite;
	var loadBar:FlxSprite;
	override function create()
	{
		var bg:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xffcaff4d);
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		funkay = new FlxSprite(0, 0).loadGraphic(Paths.getPath('images/funkay.png', IMAGE));
		funkay.setGraphicSize(0, FlxG.height);
		funkay.updateHitbox();
		add(funkay);
		funkay.antialiasing = ClientPrefs.data.antialiasing;
		funkay.scrollFactor.set();
		funkay.screenCenter();

		loadBar = new FlxSprite(0, FlxG.height - 20).makeGraphic(FlxG.width, 10, 0xffff16d2);
		loadBar.screenCenter(X);
		add(loadBar);

		callbacks = new MultiCallback(onLoad);

		for (i in Paths.currentTrackedAssets.keys()) keyArray.push(i);
		
		#if NO_PRELOAD_ALL
		initSongsManifest().onComplete
		(
			function (lib)
			{
				#end
				//Thread.create(function() { target.load();});
				//Thread.create(function() { checkLibrary();});
				#if NO_PRELOAD_ALL
			}
		);
		#end

		/**initVideoManifest().onComplete
		(
			function (lib)
			{
				var introComplete = callbacks.add("introComplete");
			}
		);**/


	}
	
	function checkLoadSong(path:String)
	{
		if (!Assets.cache.hasSound(path))
		{
			var library = Assets.getLibrary("songs");
			final symbolPath = path.split(":").pop();
			// @:privateAccess
			// library.types.set(symbolPath, SOUND);
			// @:privateAccess
			// library.pathGroups.set(symbolPath, [library.__cacheBreak(symbolPath)]);
		}
		var callback = callbacks.add("song:" + path);
		Assets.loadSound(path).onComplete(function (_) { callback(); });
	}
	
		
	function checkLibrary() {
		var countUp:Int = 0;
		if(!Assets.hasLibrary('shared')) trace("Missing stage library") else {
			Assets.loadLibrary('shared');
			//var callback = callbacks.add("stage asset:" + path);
			//for (item in library.list) Assets.loadBitmapData('shared/images/stage' + item, true).onComplete(function (_) { callback(); });
			//library.load();
		}
		for (i in Paths.currentTrackedAssets.keys())
			{
				//i.replace("assets/images/", "");
				//var callCard = i.substring(14, i.length - 4);
				trace('calling asset $i');
				var savedGraphic:FlxGraphic = Paths.image(i);
				savedGraphic.persist = true;
				Paths.excludeAsset(i);
				//trace(savedGraphic + ', yeah its working');
	
				countUp++;
				targetShit = countUp / keyArray.length;
				//loadText.text = 'Loading... Progress at ${Math.floor(storedPercentage * 100)}%';
			}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		funkay.setGraphicSize(Std.int(0.88 * FlxG.width + 0.9 * (funkay.width - 0.88 * FlxG.width)));
		funkay.updateHitbox();
		/**if(controls.ACCEPT)
		{
			funkay.setGraphicSize(Std.int(funkay.width + 60));
			funkay.updateHitbox();
		}**/

		//if(callbacks != null) {
			//targetShit = FlxMath.remapToRange(callbacks.numRemaining / callbacks.length, 1, 0, 0, 1);
			loadBar.scale.x += 0.5 * (targetShit - loadBar.scale.x);
			//trace(targetShit);
		//}

		if(targetShit == 1.0 && !transitioning) {
			transitioning = true;
			var fadeTime = 0.5;
			FlxG.camera.fade(FlxG.camera.bgColor, fadeTime, true);
			new FlxTimer().start(fadeTime + MIN_TIME, function(_) onLoad());
		}
	}
	
	function onLoad()
	{
		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();
		
		percent = 0;
		MusicBeatState.switchState(target);
	}
	
	static function getSongPath()
	{
		return Paths.inst(PlayState.SONG.song);
	}
	
	static function getVocalPath()
	{
		return Paths.voices(PlayState.SONG.song);
	}
	
	inline static public function loadAndSwitchState(target:FlxState, stopMusic = false)
	{
		MusicBeatState.switchState(getNextState(target, stopMusic));
	}
	
	static function getNextState(target:FlxState, stopMusic = false):FlxState
	{
		var directoryBoi:String = 'preload';
		var weekDir:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;

		//if(weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;

		//Paths.setCurrentLevel(directoryBoi);
		//trace('Setting asset folder to ' + directoryBoi);

		#if NO_PRELOAD_ALL
		var loaded:Bool = false;
		if (PlayState.SONG != null) {
			loaded = isSoundLoaded(getSongPath()) && (!PlayState.SONG.needsVoices || isSoundLoaded(getVocalPath())) && isLibraryLoaded("shared") && isLibraryLoaded('week_assets');
		}
		
		if (!loaded) return new LoadingState(target, stopMusic, [directoryBoi]);
		#end
		return target;
		
	}
	
	#if NO_PRELOAD_ALL
	static function isSoundLoaded(path:String):Bool
	{
		trace(path);
		return Assets.cache.hasSound(path);
	}
	
	static function isLibraryLoaded(library:String):Bool
	{
		return Assets.getLibrary(library) != null;
	}
	#end
	
	override function destroy()
	{
		super.destroy();
		
		callbacks = null;
	}
	
	static function initSongsManifest()
	{
		var id = "songs";
		var promise = new Promise<AssetLibrary>();

		var library = LimeAssets.getLibrary(id);

		if (library != null)
		{
			return Future.withValue(library);
		}

		var path = id;
		var rootPath = null;

		@:privateAccess
		var libraryPaths = LimeAssets.libraryPaths;
		if (libraryPaths.exists(id))
		{
			path = libraryPaths[id];
			rootPath = Path.directory(path);
		}
		else
		{
			if (StringTools.endsWith(path, ".bundle"))
			{
				rootPath = path;
				path += "/library.json";
			}
			else
			{
				rootPath = Path.directory(path);
			}
			@:privateAccess
			path = LimeAssets.__cacheBreak(path);
		}

		AssetManifest.loadFromFile(path, rootPath).onComplete(function(manifest)
		{
			if (manifest == null)
			{
				promise.error("Cannot parse asset manifest for library \"" + id + "\"");
				return;
			}

			var library = AssetLibrary.fromManifest(manifest);

			if (library == null)
			{
				promise.error("Cannot open library \"" + id + "\"");
			}
			else
			{
				@:privateAccess
				LimeAssets.libraries.set(id, library);
				library.onChange.add(LimeAssets.onChange.dispatch);
				promise.completeWith(Future.withValue(library));
			}
		}).onError(function(_)
		{
			promise.error("There is no asset library with an ID of \"" + id + "\"");
		});

		percent += 50;
		return promise.future;
	}

}

class MultiCallback
{
	public var callback:Void->Void;
	public var logId:String = null;
	public var length(default, null) = 0;
	public var numRemaining(default, null) = 0;
	
	var unfired = new Map<String, Void->Void>();
	var fired = new Array<String>();
	public var fireCallbacks:Bool = false;
	
	public function new (callback:Void->Void, logId:String = null)
	{
		this.callback = callback;
		this.logId = logId;
	}
	
	public function add(id = "untitled")
	{
		id = '$length:$id';
		length++;
		numRemaining++;
		var func:Void->Void = null;
		func = function ()
		{
			if (unfired.exists(id) && fireCallbacks)
			{
				unfired.remove(id);
				trace('here');
				fired.push(id);
				numRemaining--;
				
				if (logId != null)
					log('fired $id, $numRemaining remaining');
				
				if (numRemaining == 0)
				{
					if (logId != null)
						log('all callbacks fired');
					callback();
				}
			}
			else if (fired.contains(id))
				log('already fired $id');
		}
		unfired[id] = func;
		return func;
	}
	
	inline function log(msg):Void
	{
		if (logId != null)
			trace('$logId: $msg');
	}

	public function fire(id:String) {
		var func:Void->Void = unfired.get(id);
		func();
	}
	
	public function getFired() return fired.copy();
	public function getUnfired() return [for (id in unfired.keys()) id];
}