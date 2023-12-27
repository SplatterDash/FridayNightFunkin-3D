package states;

import haxe.macro.Expr.Field;
import backend.Highscore;
import backend.Song;

import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;

import objects.HealthIcon;
import states.editors.ChartingState;

import substates.GameplayChangersSubstate;
import substates.ResetScoreSubState;
import substates.InfoPrompt;

#if MODS_ALLOWED
import sys.FileSystem;
#end

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [
		new SongMetadata("BreadBank", 1, "3Dami", FlxColor.BLUE),
		new SongMetadata("Parkour", 1, "3DenDerek", FlxColor.BLUE),
		new SongMetadata("OffWallet", 1, "3DenDerek", FlxColor.RED),
		new SongMetadata("TTM (True To Musicality)", 1, "3Dami", FlxColor.BROWN),
		new SongMetadata("FORREAL", 1, "3Mega", FlxColor.RED),
		new SongMetadata("20Racks", 2, "3Cock", FlxColor.YELLOW),
		new SongMetadata("Feelin' Torpid", 3, "3Sharlie", FlxColor.WHITE),
		//new SongMetadata("uhh uhm uhh umm", 2, "3Mako", FlxColor.GREEN),
		new SongMetadata("Twin-Z", 4, "3Josie", FlxColor.GRAY),
		new SongMetadata("ALL OUT!!!", 2, "3Jitterbud", FlxColor.GRAY),
		new SongMetadata("Phrenic", 5, "3Vester", FlxColor.YELLOW),
		new SongMetadata("Full House", 2, "3Dami", FlxColor.PINK),
	];

	var cashBackSongs:Array<SongMetadata> = [
		new SongMetadata("FORREAL (Overnighter Remix)", 1, "3Mega", FlxColor.RED),
		new SongMetadata("Twin-Z (Euphoria Remix)", 4, "3Jitterbud", FlxColor.GRAY),
		new SongMetadata("Parkour (FREERUNNER Remix)", 1, "3Dami", FlxColor.BLUE),
	];

	var curSongsList:Array<SongMetadata>;

	var selector:FlxText;
	private static var curSelected:Int = 0;
	var lerpSelected:Float = 0;

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	public static var cashBackMenu:Bool = false;
	public static var unlockCash:Bool = false;
	public var casette:FlxSprite;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		FlxG.mouse.visible = true;

		curSongsList = cashBackMenu ? cashBackSongs : songs;
		var lockAt:Int = curSongsList.length;

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...curSongsList.length)
		{
			//if(Highscore.getScore(Paths.formatToSongPath(curSongsList[i].songName)) == 0 && lockAt == curSongsList.length) 
				//lockAt = i;

			if(i > lockAt) {
				var songText:Alphabet = new Alphabet(90, 320, '?????', true);
				songText.targetY = i;
				grpSongs.add(songText);

				songText.scaleX = Math.min(1, 980 / songText.width);
				songText.snapToPosition();

				var icon:HealthIcon = new HealthIcon('lock');
				icon.sprTracker = songText;
				
				// too laggy with a lot of songs, so i had to recode the logic for it
				songText.visible = songText.active = songText.isMenuItem = false;
				icon.visible = icon.active = false;

				// using a FlxGroup is too much fuss!
				iconArray.push(icon);
				add(icon);
			} else {
				var songText:Alphabet = new Alphabet(90, 320, curSongsList[i].songName, true);
				songText.targetY = i;
				grpSongs.add(songText);

				songText.scaleX = Math.min(1, 980 / songText.width);
				songText.snapToPosition();

				var icon:HealthIcon = new HealthIcon(curSongsList[i].songCharacter);
				icon.sprTracker = songText;

				
				// too laggy with a lot of songs, so i had to recode the logic for it
				songText.visible = songText.active = songText.isMenuItem = false;
				icon.visible = icon.active = false;

				// using a FlxGroup is too much fuss!
				iconArray.push(icon);
				add(icon);
			}

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 50, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		add(scoreText);

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		if(curSelected >= curSongsList.length) curSelected = 0;
		bg.color = curSongsList[curSelected].color;
		intendedColor = bg.color;
		lerpSelected = curSelected;
		
		changeSelection();

		var swag:Alphabet = new Alphabet(1, 0, "swag");

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		#if PRELOAD_ALL
		var leText:String = "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 16;
		#else
		var leText:String = "Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 18;
		#end
		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, size);
		text.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);

		//if(FlxG.save.data.cashBackUnlocked != null && FlxG.save.data.cashBackUnlocked) {
			casette = new FlxSprite(1100, 500).loadGraphic(Paths.image('casette', 'shared'));
			casette.scrollFactor.set(1, 1);
			add(casette);
		//}
		
		updateTexts();
		super.create();
	}

	override function closeSubState() {
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if(!FlxG.mouse.visible) FlxG.mouse.visible = true;
		if (FlxG.sound.music.volume < 0.7 * ClientPrefs.data.musicVolume)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, FlxMath.bound(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, FlxMath.bound(elapsed * 12, 0, 1));

		if(unlockCash) cash();

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}
		
		while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}

		if(casette != null && FlxG.mouse.overlaps(casette)) {
			if(casette.scale.x == 1) {
				casette.scale.set(1.1, 1.1);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4 * ClientPrefs.data.soundVolume);
			}
		} else if (casette.scale.x == 1.1) casette.scale.set(1, 1);

		scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
		positionHighscore();

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if(curSongsList.length > 1)
		{
			if(FlxG.keys.justPressed.HOME)
			{
				curSelected = 0;
				changeSelection();
				holdTime = 0;	
			}
			else if(FlxG.keys.justPressed.END)
			{
				curSelected = curSongsList.length - 1;
				changeSelection();
				holdTime = 0;	
			}
			if (controls.UI_UP_P)
			{
				changeSelection(-shiftMult);
				holdTime = 0;
			}
			if (controls.UI_DOWN_P)
			{
				changeSelection(shiftMult);
				holdTime = 0;
			}

			if(controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
			}

			if(FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.2 * ClientPrefs.data.soundVolume);
				changeSelection(-shiftMult * FlxG.mouse.wheel, false);
			}
		}

		if (controls.BACK)
		{
			persistentUpdate = false;
			if(colorTween != null) {
				colorTween.cancel();
			}
			FlxG.sound.play(Paths.sound('cancelMenu'), 1 * ClientPrefs.data.soundVolume);
			if(cashBackMenu) switchMenus() else MusicBeatState.switchState(new MainMenuState());
		}

		if(FlxG.keys.justPressed.CONTROL)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		else if(FlxG.keys.justPressed.SPACE)
		{
			if(grpSongs.members[curSelected].text != '?????') {
				if(instPlaying != curSelected)
					{
						#if PRELOAD_ALL
						destroyFreeplayVocals();
						FlxG.sound.music.volume = 0;
						var poop:String = Highscore.formatSong(curSongsList[curSelected].songName.toLowerCase());
						PlayState.SONG = Song.loadFromJson(poop, curSongsList[curSelected].songName.toLowerCase());
						if (PlayState.SONG.needsVoices)
							vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
						else
							vocals = new FlxSound();
		
						FlxG.sound.list.add(vocals);
						FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.7 * ClientPrefs.data.musicVolume);
						vocals.play();
						vocals.persist = true;
						vocals.looped = true;
						vocals.volume = 0.7;
						instPlaying = curSelected;
						#end
					}
			}
		}

		else if (FlxG.mouse.justPressed) {
			if(FlxG.mouse.overlaps(casette)) switchMenus();
		}

		else if (controls.ACCEPT)
		{
			if(grpSongs.members[curSelected].text != '?????') {
				persistentUpdate = false;
				var songLowercase:String = Paths.formatToSongPath(curSongsList[curSelected].songName);
				var poop:String = Highscore.formatSong(songLowercase);
				/*#if MODS_ALLOWED
				if(!sys.FileSystem.exists(Paths.modsJson(songLowercase + '/' + poop)) && !sys.FileSystem.exists(Paths.json(songLowercase + '/' + poop))) {
				#else
				if(!OpenFlAssets.exists(Paths.json(songLowercase + '/' + poop))) {
				#end
					poop = songLowercase;
					curDifficulty = 1;
					trace('Couldnt find file');
				}*/
				//trace(poop);

				try
				{
					PlayState.SONG = Song.loadFromJson(poop, songLowercase);
					PlayState.isStoryMode = false;

					if(colorTween != null) {
						colorTween.cancel();
					}
				}
				catch(e:Dynamic)
				{
					trace('ERROR! $e');

					var errorStr:String = e.toString();
					if(errorStr.startsWith('[file_contents,assets/data/')) errorStr = 'Missing file: ' + errorStr.substring(27, errorStr.length-1); //Missing chart
					missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
					missingText.screenCenter(Y);
					missingText.visible = true;
					missingTextBG.visible = true;
					FlxG.sound.play(Paths.sound('cancelMenu'), 1 * ClientPrefs.data.soundVolume);

					updateTexts(elapsed);
					super.update(elapsed);
					return;
				}
				LoadingState.loadAndSwitchState(new PlayState());

				FlxG.sound.music.volume = 0;
						
				destroyFreeplayVocals();
			} else {
				persistentUpdate = false;
				FlxG.sound.play(Paths.sound('cancelMenu'), 1 * ClientPrefs.data.soundVolume);
				openSubState(new InfoPrompt('LOCKED!\n\nComplete "${grpSongs.members[curSelected - 1].text}" in Normal mode to unlock this song!'));
			}
		}
		else if(controls.RESET)
		{
			if (grpSongs.members[curSelected].text != '?????') {
				persistentUpdate = false;
				openSubState(new ResetScoreSubState(curSongsList[curSelected].songName, curSongsList[curSelected].songCharacter));
				FlxG.sound.play(Paths.sound('scrollMenu'), 1 * ClientPrefs.data.soundVolume);
			}
			
		}

		updateTexts(elapsed);
		super.update(elapsed);
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) {
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4 * ClientPrefs.data.soundVolume);

		curSelected += change;

		if (curSelected < 0)
			curSelected = curSongsList.length - 1;
		if (curSelected >= curSongsList.length)
			curSelected = 0;

		intendedScore = Highscore.getScore(curSongsList[curSelected].songName);
		intendedRating = Highscore.getRating(curSongsList[curSelected].songName);
			
		var newColor:Int = curSongsList[curSelected].color;
		if(newColor != intendedColor) {
			if(colorTween != null) {
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
		}

		// selector.y = (70 * curSelected) + 30;

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			bullShit++;
			item.alpha = 0.6;
			if (item.targetY == curSelected)
				item.alpha = 1;
		}
		
		PlayState.storyWeek = curSongsList[curSelected].week;
	}

	private function positionHighscore() {
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
	}

	private function switchMenus() {
		FlxG.sound.play(Paths.sound('confirmMenu'), 1 * ClientPrefs.data.soundVolume);
		cashBackMenu = !cashBackMenu;
		curSelected = 0;
		MusicBeatState.switchState(new FreeplayState());
	}

	private function cash() {
		FlxG.sound.play(Paths.sound('confirmMenu'), 1 * ClientPrefs.data.soundVolume);
		openSubStateSpecial(new substates.InfoPrompt("UNLOCKED CASH BACK PACK!\n\nTo swap between the pack and the other songs, select the cassette tape on the bottom right hand corner of the Freeplay menu."));
		unlockCash = false;
	}

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];
	public function updateTexts(elapsed:Float = 0.0)
	{
		lerpSelected = FlxMath.lerp(lerpSelected, curSelected, FlxMath.bound(elapsed * 9.6, 0, 1));
		for (i in _lastVisibles)
		{
			grpSongs.members[i].visible = grpSongs.members[i].active = false;
			iconArray[i].visible = iconArray[i].active = false;
		}
		_lastVisibles = [];

		var min:Int = Math.round(Math.max(0, Math.min(curSongsList.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(curSongsList.length, lerpSelected + _drawDistance)));
		for (i in min...max)
		{
			var item:Alphabet = grpSongs.members[i];
			item.visible = item.active = true;
			item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.startPosition.x;
			item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;

			var icon:HealthIcon = iconArray[i];
			icon.visible = icon.active = true;
			_lastVisibles.push(i);
		}
	}

	public function openSubStateSpecial(subState:flixel.FlxSubState) {
		persistentUpdate = false;
		subState.closeCallback = function() { persistentUpdate = true; }
		openSubState(subState);
	}


}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		if(this.folder == null) this.folder = '';
	}
}