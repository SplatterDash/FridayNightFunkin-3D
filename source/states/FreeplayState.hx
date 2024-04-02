package states;

import haxe.macro.Expr.Field;
import backend.Highscore;
import backend.Song;

import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;

import objects.HealthIcon;
import states.editors.ChartingState;

//import substates.GameplayChangersSubstate;
import substates.ResetScoreSubState;
import substates.InfoPrompt;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection;

#if MODS_ALLOWED
import sys.FileSystem;
#end

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [
		new SongMetadata("BreadBank", "3Redacted", "3Dami", FlxColor.BLUE, "It's almost time for the hangout, and 3Dami's scoping the rooftops out with his lover, 3Redacted. Why not have a little fun in the process?"),
		new SongMetadata("Parkour", "3DenDerek", "3Dami", FlxColor.BLUE, "A little rooftop hangout never hurt anyone, and 3Dami, 3Derek and 3Den are in the mood for some bars up on high. Do well and you'll get some tips from it!"),
		new SongMetadata("OffWallet", "3DenDerek", "3Dami", FlxColor.RED, "There's a little buzz going around, but you need to kick things up a notch if you wanna get more money!"),
		new SongMetadata("TTM (True To Musicality)", "3DenDerek", "3Dami", FlxColor.BROWN, "There's a massive gang forming now! Your bills are all good, so why not send up to your roots before seemingly going out for the night?"),
		new SongMetadata("FORREAL", "3Mega", "3Dami", FlxColor.RED, "What the nuts?! The beatboxing kingpin 3Mega is here - and he has his eyes set on the dough in that hat of yours. You gotta put up a fight if you wanna keep the cash!"),
		new SongMetadata("20Racks", "3Cock", "3Derek", FlxColor.YELLOW, 'Oh hey look, it\'s that one guy who has like 17 dollars on him or something. Oh, and he wants your payload cause of course.\n3Derek, crush this guy\'s skull.'),
		new SongMetadata("Feelin' Torpid", "3Sharlie", "3Den", FlxColor.WHITE, "No way, it's 3Sharlie from LazyGoobster! It looks like 3Den has his bars all set up for him - that is, if he can get over his case of Storpid fever..."),
		new SongMetadata("TwinZ", "3JosieJitterbud", "3DamiDerek", FlxColor.GRAY, "Seems like this 3Josie person wants to spit bars, especially since his friend 3Jitterbud's in an energy burst again. Why not rap out a 2v2?"),
		new SongMetadata("Citrus Bliss", "3Mako_big", "3Dami", FlxColor.GREEN, "3Mako's coming into town, and everyone's saying he's looking for the 3D crew. It might take more than one person to lay it on him straight!"),
		//new SongMetadata("ALL OUT!!!", "3Supercharged", "3Dami", FlxColor.GRAY),      we couldn't finish in time for V1... but V2 however ;)
		new SongMetadata("Phrenic", "3Vester", "3AletoDerek", FlxColor.YELLOW, "Uh oh, looks like 3Derek's girlfriend squared up to the local jackrabbit! Hopefully 3Aleto doesn't make any wrong moves like she did last week with the local jackass..."),
		//new SongMetadata("Full House", "3Dami", "3Dami", FlxColor.PINK, "The bag and the coin are yours, but hold up - looks like everyone wants to go for one final battle, the 3D crew versus everyone else. Give it your all!"),        ALMOST made it for V1, but we're pushing it back to V2 and making it bigger and better... stay tuned ;)
	];

	var cashBackSongs:Array<SongMetadata> = [
		new SongMetadata("FORREAL (Overnighter Remix)", "3MegaCBP", "3Dami", FlxColor.RED, "Spirits of past competitors are showing up after the big hangout happened - and it seems like it's starting strong with the form of the beatboxing kingpin!"),
		new SongMetadata("TwinZ (Euphoria Remix)", "3JosieJitterbudCBP", "3DamiDerek", FlxColor.GRAY, "The spirits are taking the forms of 3Josie and 3Jitterbud for a 2v1 advantage, but 3Derek's nearby to help you. Shouldn't be that bad of a clean sweep!"),
		new SongMetadata("Parkour (FREERUNNER Remix)", "3DenDerekCBP", "3Dami", FlxColor.BLUE, "Even your friends aren't safe from the spirits - it's a battle like the hangout, 1v2, 3Derek and 3Den versus 3Dami!"),
	];

	var curSongsList:Array<SongMetadata>;

	var selector:FlxText;
	private static var curSelected:Int = 0;
	private static var curOptSelected:Int = 0;
	var lerpSelected:Float = 0;

	var lockAt:Int;

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	private var grpSongs:Map<String, FlxGraphic>;
	private var curPlaying:Bool = false;
	private var albumSprite:FlxSprite;
	private var descriptionText:FlxText;
	private var arrows:FlxTypedSpriteGroup<FlxSprite>;
	private var inGameplay:Bool = false;

	private var iconArray:FlxTypedSpriteGroup<HealthIcon>;

	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	private var optionsArray:Array<GameplayOption> = [];
	var optionsText:FlxTypedGroup<FlxText>;

	public static var cashBackMenu:Bool = false;
	public static var unlockCash:Bool = false;
	public static var finalMessage:Bool = false;
	public var casette:FlxSprite;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		FlxG.mouse.enabled = FlxG.mouse.visible = ClientPrefs.data.mouseOnMenu;

		curSongsList = cashBackMenu ? cashBackSongs : songs;

		lockAt = curSongsList.length;

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

		grpSongs = new Map<String, FlxGraphic>();

		iconArray = new FlxTypedSpriteGroup<HealthIcon>(250, 550);
		add(iconArray);

		iconArray.add(new HealthIcon(curSongsList[0].songCharacter));
		iconArray.add(new HealthIcon(curSongsList[0].playerCharacter));
		iconArray.members[0].x -= 200;
		iconArray.members[0].flipX = true;
		iconArray.members[1].x += 200;

		var lockImage:FlxGraphic = Paths.image('albums/locked');

		for (i in 0...curSongsList.length)
		{
			if(Highscore.getScore(Paths.formatToSongPath(curSongsList[i].songName)) == 0 && lockAt == curSongsList.length) 
				lockAt = i;

			grpSongs.set(curSongsList[i].songName, i > lockAt ? lockImage : Paths.image('albums/${Paths.formatToSongPath(curSongsList[i].songName)}'));
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 50, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		add(scoreText);

		if(curSelected >= curSongsList.length) curSelected = 0;
		bg.color = curSongsList[curSelected].color;
		intendedColor = bg.color;
		lerpSelected = curSelected;

		albumSprite = new FlxSprite(75, bg.y + (bg.height / 2) - 50);
		add(albumSprite);

		descriptionText = new FlxText(albumSprite.x + 25, bg.y + 100, 600, '');
		descriptionText.setFormat('DonGraffiti.otf', 40, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		add(descriptionText);
		
		changeSelection();

		descriptionText.x += albumSprite.width;

		albumSprite.y -= (albumSprite.graphic.height / 2);

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		#if PRELOAD_ALL
		var leText:String = "Press SPACE to listen to the Song / Press CTRL to switch between Gameplay Changers and Song Selection / Press RESET to Reset your Score and Accuracy";
		var size:Int = 16;
		#else
		var leText:String = "Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy";
		var size:Int = 18;
		#end
		if(FlxG.save.data.cashBackUnlocked != null && FlxG.save.data.cashBackUnlocked) leText += ' / Press ALT to switch in/out of the Cash Back songs';
		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText);
		text.setFormat(Paths.font("DonGraffiti.otf"), size, FlxColor.WHITE, CENTER);
		text.scrollFactor.set();
		add(text);

		if(FlxG.save.data.cashBackUnlocked != null && FlxG.save.data.cashBackUnlocked) {
			casette = new FlxSprite(1100, 575).loadGraphic(Paths.image('casette', 'shared'));
			casette.scrollFactor.set(1, 1);
			add(casette);
		}

		arrows = new FlxTypedSpriteGroup<FlxSprite>(albumSprite.x + (albumSprite.width / 2), 0);
		add(arrows);

		var arrowFrames:FlxFramesCollection = Paths.getSparrowAtlas('freeplay-arrows');

		var arrowUp = new FlxSprite(0, albumSprite.y - 50);
		arrowUp.frames = arrowFrames;
		arrowUp.animation.addByPrefix('arrow', 'up', 1, false);
		arrows.add(arrowUp);
		arrowUp.animation.play('arrow');

		var arrowDown = new FlxSprite(0, albumSprite.y + albumSprite.height + 16);
		arrowDown.frames = arrowFrames;
		arrowDown.animation.addByPrefix('arrow', 'down', 1, false);
		arrows.add(arrowDown);
		arrowDown.animation.play('arrow');

		arrows.x -= arrows.members[0].width / 2;

		optionsText = new FlxTypedGroup<FlxText>();
		add(optionsText);

		getOptions();

		for (i in 0...optionsArray.length)
			{
				var text:FlxText = new FlxText(albumSprite.x + albumSprite.width + 25, 600 - (35 * (optionsArray.length - (i + 1))), 0, '${optionsArray[i].name}: ${(optionsArray[i].type != 'bool' ? optionsArray[i].displayFormat.replace('%v', optionsArray[i].getValue()) : (!optionsArray[i].getValue() ? "Off" : "On"))}');
				text.setFormat('DonGraffiti.otf', 30, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
				optionsText.add(text);
			}

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);
		
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
	var holdValue:Float = 0;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7 * ClientPrefs.data.musicVolume)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, FlxMath.bound(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, FlxMath.bound(elapsed * 12, 0, 1));

		if(unlockCash) cash();
		if(finalMessage) finalThing();

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

		if(casette != null) {
			if(FlxG.mouse.overlaps(casette) && FlxG.mouse.enabled) {
				if(casette.scale.x == 1) {
					casette.scale.set(1.1, 1.1);
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4 * ClientPrefs.data.soundVolume);
				}
			} else if (casette.scale.x == 1.1) casette.scale.set(1, 1);
		}

		scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
		positionHighscore();

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if(curSongsList.length > 1 && !inGameplay)
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
			if (controls.UI_UP_P || (FlxG.mouse.overlaps(arrows.members[0]) && FlxG.mouse.justPressed))
			{
				arrows.members[0].alpha = 0.5;
				arrows.members[0].scale.set(0.7, 0.7);
				changeSelection(-shiftMult);
				holdTime = 0;
			}
			if (controls.UI_DOWN_P || (FlxG.mouse.overlaps(arrows.members[1]) && FlxG.mouse.justPressed))
			{
				arrows.members[1].alpha = 0.5;
				arrows.members[1].scale.set(0.7, 0.7);
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

			if((controls.UI_UP_R || (FlxG.mouse.justReleased && FlxG.mouse.enabled)) && arrows.members[0].alpha == 0.5) {
				arrows.members[0].scale.set(FlxG.mouse.overlaps(arrows.members[0]) ? 1.1 : 1, FlxG.mouse.overlaps(arrows.members[0]) ? 1.1 : 1);
				arrows.members[0].alpha = 1;
			}

			if((controls.UI_DOWN_R || (FlxG.mouse.justReleased && FlxG.mouse.enabled)) && arrows.members[1].alpha == 0.5) {
				arrows.members[1].scale.set(FlxG.mouse.overlaps(arrows.members[1]) ? 1.1 : 1, FlxG.mouse.overlaps(arrows.members[1]) ? 1.1 : 1);
				arrows.members[1].alpha = 1;
			}

			if(FlxG.mouse.overlaps(albumSprite) && albumSprite.scale.x != 1.1 && !FlxG.mouse.pressed && FlxG.mouse.enabled) {
				albumSprite.scale.set(1.1, 1.1);
			}
				else if (!FlxG.mouse.overlaps(albumSprite) && albumSprite.scale.x != 1 && !FlxG.mouse.pressed && FlxG.mouse.enabled) 
					albumSprite.scale.set(1, 1);

			if(FlxG.mouse.wheel != 0 && FlxG.mouse.enabled)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.2 * ClientPrefs.data.soundVolume);
				changeSelection(-shiftMult * FlxG.mouse.wheel, false);
			}

			if(FlxG.mouse.overlaps(arrows.members[0]) && !FlxG.mouse.pressed && arrows.members[0].scale.x != 1.1 && FlxG.mouse.enabled)
				arrows.members[0].scale.set(1.1, 1.1)

			else if (!FlxG.mouse.overlaps(arrows.members[0]) && !controls.UI_UP && arrows.members[0].scale.x != 1 && FlxG.mouse.enabled) 
				arrows.members[0].scale.set(1, 1);
	
			if(FlxG.mouse.overlaps(arrows.members[1]) && !FlxG.mouse.pressed && arrows.members[1].scale.x != 1.1 && FlxG.mouse.enabled)
				arrows.members[1].scale.set(1.1, 1.1)

			else if (!FlxG.mouse.overlaps(arrows.members[1]) && !controls.UI_DOWN && arrows.members[1].scale.x != 1 && FlxG.mouse.enabled) 
				arrows.members[1].scale.set(1, 1);

			else if (controls.ACCEPT && !FlxG.keys.justPressed.SPACE) acceptSong()
			else if(controls.RESET)
			{
				if (curSelected <= lockAt) {
					persistentUpdate = false;
					openSubState(new ResetScoreSubState(curSongsList[curSelected].songName, curSongsList[curSelected].songCharacter));
					FlxG.sound.play(Paths.sound('scrollMenu'), 1 * ClientPrefs.data.soundVolume);
				}
				
			}
		} else if (inGameplay) {
			if (controls.UI_UP_P)
				{
					changeOptionSelection(-shiftMult);
					holdTime = 0;
				}
				if (controls.UI_DOWN_P)
				{
					changeOptionSelection(shiftMult);
					holdTime = 0;
				}
	
				if(controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
	
					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
						changeOptionSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
	
				}

			if(controls.UI_LEFT || controls.UI_RIGHT) {
				var curOption:GameplayOption = optionsArray[curOptSelected];
				var pressed = (controls.UI_LEFT_P || controls.UI_RIGHT_P);
				if(holdTime > 0.5 || pressed) {
					if(pressed) {
						var add:Dynamic = null;
						if(curOption.type != 'string') {
							add = controls.UI_LEFT ? -curOption.changeValue : curOption.changeValue;
						}

						switch(curOption.type)
						{
							case 'int' | 'float' | 'percent':
								holdValue = curOption.getValue() + add;
								if(holdValue < curOption.minValue) holdValue = curOption.minValue;
								else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;

								switch(curOption.type)
								{
									case 'int':
										holdValue = Math.round(holdValue);
										curOption.setValue(holdValue);

									case 'float' | 'percent':
										holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
										curOption.setValue(holdValue);
								}

							case 'string':
								var num:Int = curOption.curOption; //lol
								if(controls.UI_LEFT_P) --num;
								else num++;

								if(num < 0) {
									num = curOption.options.length - 1;
								} else if(num >= curOption.options.length) {
									num = 0;
								}

								curOption.curOption = num;
								curOption.setValue(curOption.options[num]); //lol
								
								if (curOption.name == "Scroll Type")
								{
									var oOption:GameplayOption = getOptionByName("Scroll Speed");
									if (oOption != null)
									{
										if (curOption.getValue() == "constant")
										{
											oOption.displayFormat = "%v";
											oOption.maxValue = 6;
										}
										else
										{
											oOption.displayFormat = "%vX";
											oOption.maxValue = 3;
											if(oOption.getValue() > 3) oOption.setValue(3);
										}
										oOption.text = '${oOption.name}: ${oOption.type != 'bool' ? oOption.displayFormat.replace('%v', oOption.getValue()) : (!oOption.getValue() ? "Off" : "On")}';
									}
								}
								//trace(curOption.options[num]);

							case "bool":
								curOption.setValue(!curOption.getValue());
						}
						curOption.change();
						FlxG.sound.play(Paths.sound('scrollMenu'), 1 * ClientPrefs.data.soundVolume);
					} else if(curOption.type != 'string') {
						holdValue = Math.max(curOption.minValue, Math.min(curOption.maxValue, holdValue + curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1)));

						switch(curOption.type)
						{
							case 'int':
								curOption.setValue(Math.round(holdValue));
							
							case 'float' | 'percent':
								var blah:Float = Math.max(curOption.minValue, Math.min(curOption.maxValue, holdValue + curOption.changeValue - (holdValue % curOption.changeValue)));
								curOption.setValue(FlxMath.roundDecimal(blah, curOption.decimals));
						}
						curOption.change();
					}
				}

				if(curOption.type != 'string') {
					holdTime += elapsed;
				}
				optionsText.members[curOptSelected].text = '${curOption.name}: ${curOption.type != 'bool' ? curOption.displayFormat.replace('%v', curOption.getValue()) : (!curOption.getValue() ? "Off" : "On")}';
			} else if(controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					if(holdTime > 0.5) {
						FlxG.sound.play(Paths.sound('scrollMenu'), 1 * ClientPrefs.data.soundVolume);
					}
					holdTime = 0;
			}

			if(controls.RESET)
				{
					for (i in 0...optionsArray.length)
					{
						var leOption:GameplayOption = optionsArray[i];
						leOption.setValue(leOption.defaultValue);
						if(leOption.type != 'bool')
						{
							if(leOption.type == 'string')
							{
								leOption.curOption = leOption.options.indexOf(leOption.getValue());
							}
						}
	
						if(leOption.name == 'Scroll Speed')
						{
							leOption.displayFormat = "%vX";
							leOption.maxValue = 3;
							if(leOption.getValue() > 3)
							{
								leOption.setValue(3);
							}
						}
						optionsText.members[i].text = '${leOption.name}: ${leOption.type != 'bool' ? leOption.displayFormat.replace('%v', leOption.getValue()) : (!leOption.getValue() ? "Off" : "On")}';
						leOption.change();
					}
					FlxG.sound.play(Paths.sound('cancelMenu'), 1 * ClientPrefs.data.soundVolume);
				}
		}

		if(FlxG.keys.justPressed.CONTROL) {
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4 * ClientPrefs.data.soundVolume);
			inGameplay = !inGameplay;
			changeOptionSelection();
		}

		if(FlxG.keys.justPressed.ALT) {
			FlxG.sound.play(Paths.sound('confirmMenu'), 1 * ClientPrefs.data.soundVolume);
			switchMenus();
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

		if(((FlxG.mouse.overlaps(albumSprite) && albumSprite.scale.x != 1.1) || (FlxG.mouse.overlaps(arrows.members[0]) && arrows.members[0].scale.x != 1.1) || (FlxG.mouse.overlaps(arrows.members[1]) && arrows.members[1].scale.x != 1.1)) && !FlxG.mouse.pressed && FlxG.mouse.enabled) {
			inGameplay = false;
			changeOptionSelection();
		}
		for(member in optionsText.members) if (FlxG.mouse.overlaps(member) && (curOptSelected != optionsText.members.indexOf(member) || !inGameplay) && member.color != FlxColor.BLACK) {
			curOptSelected = optionsText.members.indexOf(member);
			inGameplay = true;
			changeOptionSelection();
		}

		else if(FlxG.keys.justPressed.SPACE)
		{
			if(curSelected <= lockAt) {
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

		if (FlxG.mouse.justPressed && FlxG.mouse.enabled) {
			if(casette != null && FlxG.mouse.overlaps(casette)) {
				FlxG.sound.play(Paths.sound('confirmMenu'), 1 * ClientPrefs.data.soundVolume);
				switchMenus();
			}
			else if(FlxG.mouse.overlaps(albumSprite)) acceptSong();
		}
		super.update(elapsed);
	}

	public function acceptSong()
		{
			if(curSelected <= lockAt) {
				persistentUpdate = false;
				var songLowercase:String = Paths.formatToSongPath(curSongsList[curSelected].songName);
				var poop:String = Highscore.formatSong(songLowercase);

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

					persistentUpdate = true;
					return;
				}
				MusicBeatState.switchState(new PlayState());

				FlxG.sound.music.volume = 0;
						
				destroyFreeplayVocals();
			} else {
				persistentUpdate = false;
				FlxG.sound.play(Paths.sound('cancelMenu'), 1 * ClientPrefs.data.soundVolume);
				openSubState(new InfoPrompt('LOCKED!\n\nComplete "${(curSelected > (lockAt + 1)) ? '??????' : curSongsList[curSelected - 1].songName}" in Normal mode to unlock this song!'));
			}
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
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.5 * ClientPrefs.data.soundVolume);

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

		iconArray.members[0].changeIcon(curSongsList[curSelected].songCharacter);
		iconArray.members[1].changeIcon(curSongsList[curSelected].playerCharacter);
		if(curSelected > lockAt) {
			if(iconArray.members[0].alpha == 1) for(member in iconArray.members) member.alpha = 0;
			descriptionText.text = '?????';
			 } else {
				if(iconArray.members[0].alpha == 0) for(member in iconArray.members) member.alpha = 1;
				descriptionText.text = curSongsList[curSelected].description != '' ? curSongsList[curSelected].description : "Guys Splatter worked hard coding this freeplay menu please don't break it pLEASE-";
			 }
		albumSprite.loadGraphic(grpSongs.get(curSongsList[curSelected].songName));
	}

	function changeOptionSelection(change:Int = 0)
		{
			curOptSelected += change;
			if (curOptSelected < 0)
				curOptSelected = optionsArray.length - 1;
			if (curOptSelected >= optionsArray.length)
				curOptSelected = 0;
	
			for(i in 0...optionsText.members.length) {
				if(i == curOptSelected && inGameplay) {
					optionsText.members[i].borderColor = FlxColor.WHITE;
					optionsText.members[i].color = FlxColor.BLACK;
				} else {
					optionsText.members[i].borderColor = FlxColor.BLACK;
					optionsText.members[i].color = FlxColor.WHITE;
				}
			}
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.5 * ClientPrefs.data.soundVolume);
		}

	private function positionHighscore() {
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
	}

	private function switchMenus() {
		cashBackMenu = !cashBackMenu;
		curSelected = 0;
		MusicBeatState.switchState(new FreeplayState());
	}

	private function cash() {
		FlxG.sound.play(Paths.sound('confirmMenu'), 1 * ClientPrefs.data.soundVolume);
		openSubStateSpecial(new substates.InfoPrompt("UNLOCKED CASH BACK PACK!\n\nTo swap between the pack and the other songs, select the cassette tape on the bottom right hand corner of the Freeplay menu or press ALT on the Freeplay menu."));
		unlockCash = false;
	}

	private function finalThing() {
		FlxG.sound.play(Paths.sound('confirmMenu'), 1 * ClientPrefs.data.soundVolume);
		openSubStateSpecial(new substates.InfoPrompt("THANK YOU FOR PLAYING 3D V1!\n\nWe hope you enjoyed playing through the mod and we'll see you for Vs Dami in 2024 (and maybe a potential V2 of 3D in the future...)"));
		finalMessage = false;
	}

	public function openSubStateSpecial(subState:flixel.FlxSubState) {
		persistentUpdate = false;
		subState.closeCallback = function() { persistentUpdate = true; }
		openSubState(subState);
	}

	function getOptions()
		{
			var goption:GameplayOption = new GameplayOption('Scroll Type', 'scrolltype', 'string', 'multiplicative', ["multiplicative", "constant"]);
			optionsArray.push(goption);
	
			var option:GameplayOption = new GameplayOption('Scroll Speed', 'scrollspeed', 'float', 1);
			option.scrollSpeed = 2.0;
			option.minValue = 0.35;
			option.changeValue = 0.05;
			option.decimals = 2;
			if (goption.getValue() != "constant")
			{
				option.displayFormat = '%vX';
				option.maxValue = 3;
			}
			else
			{
				option.displayFormat = "%v";
				option.maxValue = 6;
			}
			optionsArray.push(option);
	
			#if !html5
			var option:GameplayOption = new GameplayOption('Playback Rate', 'songspeed', 'float', 1);
			option.scrollSpeed = 1;
			option.minValue = 0.5;
			option.maxValue = 3.0;
			option.changeValue = 0.05;
			option.displayFormat = '%vX';
			option.decimals = 2;
			optionsArray.push(option);
			#end
	
			var option:GameplayOption = new GameplayOption('Health Gain Multiplier', 'healthgain', 'float', 1);
			option.scrollSpeed = 2.5;
			option.minValue = 0;
			option.maxValue = 5;
			option.changeValue = 0.1;
			option.displayFormat = '%vX';
			optionsArray.push(option);
	
			var option:GameplayOption = new GameplayOption('Health Loss Multiplier', 'healthloss', 'float', 1);
			option.scrollSpeed = 2.5;
			option.minValue = 0.5;
			option.maxValue = 5;
			option.changeValue = 0.1;
			option.displayFormat = '%vX';
			optionsArray.push(option);
	
			var option:GameplayOption = new GameplayOption('Instakill on Miss', 'instakill', 'bool', false);
			optionsArray.push(option);
	
			var option:GameplayOption = new GameplayOption('Practice Mode', 'practice', 'bool', false);
			optionsArray.push(option);
	
			var option:GameplayOption = new GameplayOption('Botplay', 'botplay', 'bool', false);
			optionsArray.push(option);
		}

		public function getOptionByName(name:String)
			{
				for(i in optionsArray)
				{
					var opt:GameplayOption = i;
					if (opt.name == name)
						return opt;
				}
				return null;
			}
}

class SongMetadata
{
	public var songName:String = "";
	public var playerCharacter:String = "";
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var description:String = "";

	public function new(song:String, songCharacter:String, playerCharacter:String, color:Int, ?description:String)
	{
		this.songName = song;
		this.playerCharacter = playerCharacter;
		this.songCharacter = songCharacter;
		this.color = color;
		if(description != null) this.description = description;
	}
}

class GameplayOption
{
	public var text:String;
	public var onChange:Void->Void = null; //Pressed enter (on Bool type options) or pressed/held left/right (on other types)

	public var type(get, default):String = 'bool'; //bool, int (or integer), float (or fl), percent, string (or str)
	// Bool will use checkboxes
	// Everything else will use a text

	public var scrollSpeed:Float = 50; //Only works on int/float, defines how fast it scrolls per second while holding left/right

	private var variable:String = null; //Variable from ClientPrefs.hx's gameplaySettings
	public var defaultValue:Dynamic = null;

	public var curOption:Int = 0; //Don't change this
	public var options:Array<String> = null; //Only used in string type
	public var changeValue:Dynamic = 1; //Only used in int/float/percent type, how much is changed when you PRESS
	public var minValue:Dynamic = null; //Only used in int/float/percent type
	public var maxValue:Dynamic = null; //Only used in int/float/percent type
	public var decimals:Int = 1; //Only used in float/percent type

	public var displayFormat:String = '%v'; //How String/Float/Percent/Int values are shown, %v = Current value, %d = Default value
	public var name:String = 'Unknown';

	public function new(name:String, variable:String, type:String = 'bool', defaultValue:Dynamic = 'null variable value', ?options:Array<String> = null)
	{
		this.name = name;
		this.variable = variable;
		this.type = type;
		this.defaultValue = defaultValue;
		this.options = options;

		if(defaultValue == 'null variable value')
		{
			switch(type)
			{
				case 'bool':
					defaultValue = false;
				case 'int' | 'float':
					defaultValue = 0;
				case 'percent':
					defaultValue = 1;
				case 'string':
					defaultValue = '';
					if(options.length > 0) {
						defaultValue = options[0];
					}
			}
		}

		if(getValue() == null) {
			setValue(defaultValue);
		}

		switch(type)
		{
			case 'string':
				var num:Int = options.indexOf(getValue());
				if(num > -1) {
					curOption = num;
				}
	
			case 'percent':
				displayFormat = '%v%';
				changeValue = 0.01;
				minValue = 0;
				maxValue = 1;
				scrollSpeed = 0.5;
				decimals = 2;
		}
	}

	public function change()
	{
		//nothing lol
		if(onChange != null) {
			onChange();
		}
	}

	public function getValue():Dynamic
	{
		return ClientPrefs.data.gameplaySettings.get(variable);
	}
	public function setValue(value:Dynamic)
	{
		ClientPrefs.data.gameplaySettings.set(variable, value);
	}

	private function get_type()
	{
		var newValue:String = 'bool';
		switch(type.toLowerCase().trim())
		{
			case 'int' | 'float' | 'percent' | 'string': newValue = type;
			case 'integer': newValue = 'int';
			case 'str': newValue = 'string';
			case 'fl': newValue = 'float';
		}
		type = newValue;
		return type;
	}
}