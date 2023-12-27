package states;

import flixel.FlxSubState;
import backend.Achievements;
import backend.Song;

import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;

import flixel.input.keyboard.FlxKey;
import lime.app.Application;

import objects.AchievementPopup;
import states.editors.MasterEditorMenu;
import options.OptionsState;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.7.1h'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;
	private var campaignScoreGroup:FlxTypedGroup<FlxSprite>;
	
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		'credits',
		'options'
	];

	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var bg:FlxSprite;

	public static var needToCongratulate:Bool = false;
	public static var tutorialComplete:Bool = false;

	override function create()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement, false);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		bg = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.antialiasing = ClientPrefs.data.antialiasing;
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		add(magenta);
		
		// magenta.scrollFactor.set();

		campaignScoreGroup = new FlxTypedGroup<FlxSprite>();
		add(campaignScoreGroup);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1;
		/*if(optionShit.length > 6) {
			scale = 6 / optionShit.length;
		}*/

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, (i * 140)  + offset);
			menuItem.antialiasing = ClientPrefs.data.antialiasing;
			menuItem.scale.x = scale;
			menuItem.scale.y = scale;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter(X);
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if(optionShit.length < 6) scr = 0;
			menuItem.scrollFactor.set(0, scr);
			//menuItem.setGraphicSize(Std.int(menuItem.width * 0.58));
			menuItem.updateHitbox();
		}

		FlxG.camera.follow(camFollow, null, 0);

		var campaignScore = new FlxText(FlxG.width, 5, 0, "CAMPAIGN SCORE: " + backend.Highscore.getWeekScore(), 32);
		campaignScore.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		campaignScore.scrollFactor.set();
		campaignScore.x -= campaignScore.width;

		var campaignBox = new FlxSprite(campaignScore.x - 6, 0).makeGraphic(FlxG.width, 50, FlxColor.BLACK);
		campaignBox.width -= campaignBox.x;
		campaignBox.alpha = 0.3;
		campaignBox.scrollFactor.set();
		campaignScoreGroup.add(campaignBox);
		campaignScoreGroup.add(campaignScore);
		

		var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();

		super.create();
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < (0.8 * ClientPrefs.data.musicVolume))
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
			if(FreeplayState.vocals != null) FreeplayState.vocals.volume += 0.5 * elapsed;
		}
		FlxG.camera.followLerp = FlxMath.bound(elapsed * 9 / (FlxG.updateFramerate / 60), 0, 1);

		if(tutorialComplete) checkIt();

		if(needToCongratulate) congratulate();

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 1 * ClientPrefs.data.soundVolume);
				changeItem(-1);
			}

			if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 1 * ClientPrefs.data.soundVolume);
				changeItem(1);
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'), 1 * ClientPrefs.data.soundVolume);
				MusicBeatState.switchState(new TitleState());
			}
			else if(controls.RESET && curSelected == 0)
				{
					persistentUpdate = false;
					openSubState(new substates.ResetScoreSubState('', '', true));
					//FlxG.sound.play(Paths.sound('scrollMenu'));
				}

			if (controls.ACCEPT)
			{
				if (optionShit[curSelected] == 'freeplay' && (!FlxG.save.data.weekCompleted || FlxG.save.data.weekCompleted == null))
				{
					persistentUpdate = false;
					selectedSomethin = false;
					FlxG.sound.play(Paths.sound('cancelMenu'), 1 * ClientPrefs.data.soundVolume);
					openSubState(new substates.InfoPrompt("FREEPLAY LOCKED!\n\nComplete all songs in Story Mode to unlock Freeplay!"));
				}
				else
				{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'), 1 * ClientPrefs.data.soundVolume);

					if(ClientPrefs.data.flashing) FlxFlicker.flicker(magenta, 1.1, 0.15, false);

					menuItems.forEach(function(spr:FlxSprite)
					{
						if (curSelected != spr.ID)
						{
							FlxTween.tween(spr, {alpha: 0}, 0.4, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});
						}
						else
						{
							FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
							{
								var daChoice:String = optionShit[curSelected];

								switch (daChoice)
								{
									case 'story_mode':
										var songArray:Array<String> = [];
										var leWeek:Array<Dynamic> = [
											['Parkour', '3Derek', [127, 127, 255]],
											['OffWallet', '3Derek', [255, 0, 0]],
											['TTM (True To Musicality)', '3DerekTTM', [0, 0, 255]]
										];
										for (i in 0...leWeek.length) {
											songArray.push(leWeek[i][0]);
										}

										// Nevermind that's stupid lmao
										try
										{
											PlayState.storyPlaylist = songArray;
											PlayState.isStoryMode = true;

											var poop = Paths.formatToSongPath(PlayState.storyPlaylist[0].toLowerCase());
								
											PlayState.SONG = Song.loadFromJson(poop, poop);
											PlayState.campaignScore = 0;
											PlayState.campaignMisses = 0;
										}
										catch(e:Dynamic)
										{
											trace('ERROR! $e');
											return;
										}
										FlxG.sound.music.fadeOut(1, 0);
										FlxG.camera.fade(FlxColor.BLACK, 1);
										
										new FlxTimer().start(1, function(tmr:FlxTimer)
										{
											flixel.addons.transition.FlxTransitionableState.skipNextTransIn = true;
											LoadingState.loadAndSwitchState(new PlayState(), true);
										});
									case 'freeplay':
										MusicBeatState.switchState(new FreeplayState());
									case 'credits':
										MusicBeatState.switchState(new CreditsState());
									case 'options':
										LoadingState.loadAndSwitchState(new OptionsState());
										OptionsState.onPlayState = false;
										if (PlayState.SONG != null)
										{
											PlayState.SONG.arrowSkin = null;
											PlayState.SONG.splashSkin = null;
										}
								}
							});
						}
					});
				}
			}
			#if desktop
			else if (controls.justPressed('debug_1'))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.screenCenter(X);
		});
	}

	override function openSubState(SubState:FlxSubState) {
		persistentUpdate = false;
		super.openSubState(SubState);
	}

	override function closeSubState() {
		persistentUpdate = true;
		super.closeSubState();
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected != 0)
			for (item in campaignScoreGroup) {
				FlxTween.cancelTweensOf(item);
				FlxTween.tween(item, { alpha: 0}, 0.7);
			} else {
				for (item in campaignScoreGroup) FlxTween.cancelTweensOf(item);
				FlxTween.tween(campaignScoreGroup.members[0], { alpha: 0.6}, 0.7);
				FlxTween.tween(campaignScoreGroup.members[1], { alpha: 1}, 0.7);
			}

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			spr.updateHitbox();

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');
				var add:Float = 0;
				if(menuItems.length > 4) {
					add = menuItems.length * 8;
				}
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y - add);
				spr.centerOffsets();
			}
		});
	}

	public function congratulate()
		{
			FlxG.sound.play(Paths.sound('confirmMenu'), 1 * ClientPrefs.data.soundVolume);
			openSubState(new substates.InfoPrompt("YOU'RE RICH!\n\nBut some other friends want your money now...\nNew songs now available in Freeplay!"));
			needToCongratulate = false;
		}

	public function checkIt()
		{
			FlxG.sound.play(Paths.sound('confirmMenu'), 1 * ClientPrefs.data.soundVolume);
			openSubState(new substates.InfoPrompt("YOU GOT IT!\n\nNow try your hand at the three songs in Story Mode. Complete them all to unlock Freeplay Mode!"));
			tutorialComplete = false;
		}
}
