package substates;

import backend.Highscore;
import backend.Song;

import flixel.addons.transition.FlxTransitionableState;

import flixel.util.FlxStringUtil;

import states.MainMenuState;
import states.FreeplayState;
import options.OptionsState;

class PauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<FlxText>;

	var loadingFunnies:Array<String> = [
		'3Redacted, canonically, is addicted to prescription drugs.',
		'We don\'t talk about the ice cream incident.',
		'3Den has moaninglipitites.',
		'A lot of the 3D atmosphere is inspired by Jet Set Radio Future and Bomb Rush Cyberfunk - two of Note\'s favorite games!',
		'3Derek, as well as Audity himself, are both Hispanic.',   // included this since the TTM stuff - trust me, if it was someone saying slurs they can't reclaim, I wouldn't let that pass, but since Audity is Hispanic and it's not targetted at someone, I technically have no reason to complain. ~SPD
		'Everyone who worked on this is a portion of another mod team, which is working on Vs Dami!',
		'If you disrespect 3DinkleSpink, 3Derek will find you.',
		'This mod is not compatible with 3D glasses. Not yet, at least.',
		'Talk to Noer. See if he will show you his money.',
		'We\'re no strangers to love. You know the rules, and so do I. I\'ve no commitments that I\'m thinking of, you wouldn\'t get this from any other guy.',
		'3Den is a massive simp for Hideki Naganuma. It\'s why a lot of his songs take a lot of inspiration from songs of Naganuma!',
		'This is bromi- oh no wait that was just soy sauce. This is bromine!',
		'3Mega dies 3 days after 3D takes place from human spontaneous combustion.',
		'3Redacted has a 20-foot Ball Python named Cornball.',
		'3DinkleSpink dies immediately after 3D takes place.',
		'I swear we legitimately started this before the Game Awards (we still <3 you JSR).',    // was kinda funny seeing that SEGA Power Surge commercial air on Game Awards - the only good part of the 2023 Game Awards I might add
		'Who would win: Eminem, or "Woah dag what I cooch"?',
		"bomboclatt!!!",
		"3Sylvester canonically mimics whoever he encounters.",
		"3Mako has a body count. All of his victims also die in the same alleyway.",
		"You know that one meme drawing of the worn out person with a crazy person on a leash? That's 3Josie with 3Jitterbud on the leash.",
		"3Derek has made 29 attempts to kill 3Jitterbud. All of them clearly failed.",
		'3Dami canonically beats up 3Mega after their battle for losing every game in GamePigeon\'s "8Ball".',  // runner up: 3Mega losing in every game of GamePigeon's "Darts".
		"It took 7 months to develop 3D V1.",
		"3Dami stole the hoodie around his waist from 3Nitro.",
		"BreakBank was 3Dami and 3Redacted's first date!",
		"3Dami has a glock in his 'Rari - seventeen bucks, no Fitty Cent.",
		"3DinkleSpink.",
		"3Den really likes 3Sharlie. And I mean, like, they reeeeeeeaaallly like, like like likes, 3Sharlie.",     // this was Dami's idea, before I get hurt for this
		"3Dami's favorite character in Smash Bros is Meta Knight.",
		"                               huh?",
		"3Redacted is a cannibal. Sometimes.         sleep with one eye open tonight",
		'3Dami\'s really good at skating. He is, truly, a skater boy before 3Redacted said "cya later boi".',
		"3Derek has doxxed at least 3 people on Twitter.",    // not the actual Audity, just to clarify
		"Apple bottom jeans, boots with the jeans, the whole club was lookin' at jeans.",
		'"THIS IS THE WRONG MO- oh no wait, nevermind, this is the right mod."    -sketch, 2k24',
		"3Aleto and 3Sylvester are like siblings. You know, the kind that kill each other!",
		"3Grey has all of the fights recorded onto YouTube. Each fight is on 3 million views and counting.",
		"3Aleto gets evicted from her apartment because she received 68 noise complaints from her neighbors.",
		"...uh... I couldn't come up with a fun fact here. I feel a little storpid.",
		"3Den was a homeless breakdancer before he met 3Dami.",
		"Oh my God, they killed Dami! ...those bastards!",
		"3Dami met 3Derek at his favorite restaurant: Outback Steakhouse:tm:.",
		"LazyGoobster didn't know about this mod's existance until today. Hi Goobster!",
		"3Sharlie goes into a local Ikea and sleeps on their beds for free.",
		"3Aleto's old apartment includes the broken microphone she smashed on a wall and thirteen other holes in the wall.",
		'"I\'m blue."    -andy 2k24',
		'"hi guys I\'m mako"    -mako 2k24',
	];

	var menuItems:Array<String> = [];
	var menuItemsOG:Array<String> = ['Resume', 'Restart Song', 'Options', 'Exit to menu'];
	var curSelected:Int = 0;

	var pauseMusic:FlxSound;
	var practiceText:FlxText;
	var skipTimeText:FlxText;
	var skipTimeTracker:FlxText;
	var curTime:Float = Math.max(0, Conductor.songPosition);

	var missingTextBG:FlxSprite;
	var missingText:FlxText;
	var loadingFunny:FlxText;

	public static var songName:String = '';

	public function new(x:Float, y:Float)
	{
		super();

		if(PlayState.chartingMode)
		{
			menuItemsOG.insert(1, 'Leave Charting Mode');
			
			var num:Int = 0;
			if(!PlayState.instance.startingSong)
			{
				num = 1;
				menuItemsOG.insert(2, 'Skip Time');
			}
			menuItemsOG.insert(3 + num, 'End Song');
			menuItemsOG.insert(4 + num, 'Toggle Practice Mode');
			menuItemsOG.insert(5 + num, 'Toggle Botplay');
		}
		if((FlxG.save.data.seenIntro == null || !FlxG.save.data.seenIntro) && Paths.formatToSongPath(PlayState.SONG.song) == 'breadbank')
			menuItemsOG.remove('Exit to menu');
		menuItems = menuItemsOG;

		FlxG.mouse.enabled = FlxG.mouse.visible = ClientPrefs.data.mouseOnMenu;


		pauseMusic = new FlxSound();
		if(songName != null) {
			pauseMusic.loadEmbedded(Paths.music(songName), true, true);
		} else if (songName != 'None') {
			pauseMusic.loadEmbedded(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)), true, true);
		}
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		bg.active = false;
		add(bg);

		var graphic:FlxSprite = new FlxSprite(bg.width - 10, 10).loadGraphic(Paths.image('pausedGraphic'));
		graphic.alpha = 0;
		graphic.x -= graphic.frameWidth;
		graphic.scrollFactor.set();
		graphic.active = false;
		add(graphic);

		var levelInfo:FlxText = new FlxText(graphic.x + (graphic.width / 2), 275, 0, PlayState.SONG.song.replace(' (', '\n('));
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font("DonGraffiti.otf"), 70, FlxColor.fromRGB(PlayState.instance.boyfriend.healthColorArray[0], PlayState.instance.boyfriend.healthColorArray[1], PlayState.instance.boyfriend.healthColorArray[2]), CENTER);
		levelInfo.borderStyle = FlxTextBorderStyle.OUTLINE;
		levelInfo.borderColor = FlxColor.BLACK;
		levelInfo.active = false;
		add(levelInfo);
		levelInfo.x -= (levelInfo.width / 2);

		var blueballedTxt:FlxText = new FlxText(graphic.x + (graphic.width / 2), levelInfo.y + levelInfo.height + 1, 0, "Blueballed: " + PlayState.deathCounter);
		blueballedTxt.scrollFactor.set();
		blueballedTxt.setFormat(Paths.font('DonGraffiti.otf'), 58, FlxColor.fromRGB(PlayState.instance.dad.healthColorArray[0], PlayState.instance.dad.healthColorArray[1], PlayState.instance.dad.healthColorArray[2]));
		blueballedTxt.borderStyle = FlxTextBorderStyle.OUTLINE;
		blueballedTxt.borderColor = FlxColor.BLACK;
		blueballedTxt.active = false;
		add(blueballedTxt);
		blueballedTxt.x -= (blueballedTxt.width / 2);


		practiceText = new FlxText(bg.x + bg.width, bg.y + bg.height, 0, PlayState.chartingMode ? "CHARTING MODE" : "PRACTICE MODE");
		practiceText.scrollFactor.set();
		practiceText.setFormat(Paths.font('DonGraffiti.otf'), 32);
		practiceText.x -= practiceText.width + 20;
		practiceText.y -= practiceText.height + 10;
		practiceText.active = false;
		add(practiceText);
		practiceText.visible = practiceText.alive = ((practiceText.text == 'CHARTING MODE' && PlayState.chartingMode) || (practiceText.text == 'PRACTICE MODE' && PlayState.instance.practiceMode));

		if(Main.isOBS) {
			loadingFunnies.push("Be sure to subscribe to DamiNation2020 on YouTube!");
			loadingFunnies.push('hi chat, I trapped myself in these facts to say hi to you guys');
			loadingFunnies.push("The streamer you're watching currently has a grand total of 0 bitches.");
		}
		loadingFunny = new FlxText(bg.x + 10, bg.y + bg.height, bg.width - 20, ((FlxG.save.data.seenIntro == null || !FlxG.save.data.seenIntro) && Paths.formatToSongPath(PlayState.SONG.song) == 'breadbank') ? "Welcome to the streets, kid..." : loadingFunnies[FlxG.random.int(0, loadingFunnies.length - 1)]);
		loadingFunny.setFormat(Paths.font("DonGraffiti.otf"), 45, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		loadingFunny.screenCenter(X);
		loadingFunny.y -= (loadingFunny.height + 30);
		loadingFunny.active = false;
		add(loadingFunny);

		blueballedTxt.alpha = 0;
		levelInfo.alpha = 0;

		//levelInfo.x = FlxG.width - (levelInfo.width + 150);
		//blueballedTxt.x = FlxG.width - (blueballedTxt.width + 140);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(graphic, {alpha: 1}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(levelInfo, {alpha: 1, y: levelInfo.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(blueballedTxt, {alpha: 1, y: blueballedTxt.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});

		grpMenuShit = new FlxTypedGroup<FlxText>();
		add(grpMenuShit);

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		regenMenu();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	var holdTime:Float = 0;
	var cantUnpause:Float = 0.1;
	override function update(elapsed:Float)
	{
		cantUnpause -= elapsed;
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);
		updateSkipTextStuff();

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}

		var daSelected:String = menuItems[curSelected];
		switch (daSelected)
		{
			case 'Skip Time':
				if (controls.UI_LEFT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4 * ClientPrefs.data.soundVolume);
					curTime -= 1000;
					holdTime = 0;
				}
				if (controls.UI_RIGHT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4 * ClientPrefs.data.soundVolume);
					curTime += 1000;
					holdTime = 0;
				}

				if(controls.UI_LEFT || controls.UI_RIGHT)
				{
					holdTime += elapsed;
					if(holdTime > 0.5)
					{
						curTime += 45000 * elapsed * (controls.UI_LEFT ? -1 : 1);
					}

					if(curTime >= FlxG.sound.music.length) curTime -= FlxG.sound.music.length;
					else if(curTime < 0) curTime += FlxG.sound.music.length;
					updateSkipTimeText();
				}
		}

		if (accepted && (cantUnpause <= 0 || !controls.controllerMode))
			switch (daSelected)
			{
				case "Resume":
					if(FlxG.mouse.visible) FlxG.mouse.enabled = FlxG.mouse.visible = false;
					close();
				case 'Toggle Practice Mode':
					PlayState.instance.practiceMode = !PlayState.instance.practiceMode;
					practiceText.alive = PlayState.instance.practiceMode;
				case "Restart Song":
					restartSong();
				case "Leave Charting Mode":
					restartSong();
					PlayState.chartingMode = false;
				case 'Skip Time':
					if(curTime < Conductor.songPosition)
					{
						PlayState.startOnTime = curTime;
						restartSong(true);
					}
					else
					{
						if (curTime != Conductor.songPosition)
						{
							PlayState.instance.clearNotesBefore(curTime);
							PlayState.instance.setSongTime(curTime);
						}
						close();
					}
				case 'End Song':
					close();
					PlayState.instance.notes.clear();
					PlayState.instance.unspawnNotes = [];
					PlayState.instance.finishSong(true);
				case 'Toggle Botplay':
					PlayState.instance.cpuControlled = !PlayState.instance.cpuControlled;
					PlayState.instance.botplayTxt.visible = PlayState.instance.cpuControlled;
					PlayState.instance.botplayTxt.alpha = 1;
					PlayState.instance.botplaySine = 0;
				case 'Options':
					PlayState.instance.paused = true; // For lua
					PlayState.instance.vocals.volume = 0;
					MusicBeatState.switchState(new OptionsState());
					if(ClientPrefs.data.pauseMusic != 'None')
					{
						FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)), pauseMusic.volume);
						FlxTween.tween(FlxG.sound.music, {volume: 1 * ClientPrefs.data.musicVolume}, 0.8);
						FlxG.sound.music.time = pauseMusic.time;
					}
					OptionsState.onPlayState = true;
				case "Exit to menu":
					#if desktop DiscordClient.resetClientID(); #end
					PlayState.deathCounter = 0;
					PlayState.seenCutscene = false;
					PlayState.loadedFull = false;

					if(PlayState.isStoryMode) {
						MusicBeatState.switchState(new MainMenuState());
					} else {
						MusicBeatState.switchState(new FreeplayState());
					}
					PlayState.cancelMusicFadeTween();
					FlxG.sound.playMusic(Paths.music('3dmainmenu'), 0.7 * ClientPrefs.data.musicVolume);
					PlayState.chartingMode = false;
					FlxG.camera.followLerp = 0;
			}
	}

	function deleteSkipTimeText()
	{
		if(skipTimeText != null)
		{
			skipTimeText.kill();
			remove(skipTimeText);
			skipTimeText.destroy();
		}
		skipTimeText = null;
		if(skipTimeTracker != null)
			{
				skipTimeTracker.kill();
				remove(skipTimeTracker);
				skipTimeTracker.destroy();
			}
		skipTimeTracker = null;
	}

	public static function restartSong(noTrans:Bool = false)
	{
		PlayState.instance.paused = true; // For lua
		FlxG.sound.music.volume = 0;
		PlayState.instance.vocals.volume = 0;

		if(noTrans)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
		}
		MusicBeatState.resetState();
	}

	override function destroy()
	{
		pauseMusic.destroy();
		if(FlxG.mouse.visible) FlxG.mouse.enabled = FlxG.mouse.visible = false;
		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4 * ClientPrefs.data.soundVolume);

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpMenuShit.members)
		{
			/**item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));

				if(item == skipTimeTracker)
				{
					curTime = Math.max(0, Conductor.songPosition);
					updateSkipTimeText();
				}
			}**/
			if(grpMenuShit.members.indexOf(item) == curSelected) {
				item.color = FlxColor.BLACK;
				item.borderColor = FlxColor.WHITE;
			} else if (item.color == FlxColor.BLACK) {
				item.color = FlxColor.WHITE;
				item.borderColor = FlxColor.BLACK;
			}
		}
		missingText.visible = false;
		missingTextBG.visible = false;
	}

	function regenMenu():Void {
		for (i in 0...grpMenuShit.members.length) {
			var obj = grpMenuShit.members[0];
			obj.kill();
			grpMenuShit.remove(obj, true);
			obj.destroy();
		}

		for (i in 0...menuItems.length) {
			/**var item = new Alphabet(90, 320, menuItems[i], true);
			item.isMenuItem = true;
			item.targetY = i;
			grpMenuShit.add(item);

			if(menuItems[i] == 'Skip Time')
			{
				skipTimeText = new FlxText(0, 0, 0, '', 64);
				skipTimeText.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				skipTimeText.scrollFactor.set();
				skipTimeText.borderSize = 2;
				skipTimeTracker = item;
				add(skipTimeText);

				updateSkipTextStuff();
				updateSkipTimeText();
			}**/

			var item = new FlxText(50, 100 + ((menuItems.length >= 5 ? 70 : 110) * i), 0, menuItems[i]);
			item.setFormat(Paths.font('DonGraffiti.otf'), menuItems.length >= 5 ? 75 : 125, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
			item.scrollFactor.set();
			item.borderSize = 2;
			item.active = false;
			item.alpha = 0;
			grpMenuShit.add(item);

			if(menuItems[i] == 'Skip Time') {
				skipTimeText = new FlxText(50, item.y, 0, '');
				skipTimeText.setFormat(Paths.font('vcr.ttf'), 75, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
				skipTimeText.scrollFactor.set();
				skipTimeText.borderSize = 2;
				skipTimeText.active = false;
				add(skipTimeText);

				updateSkipTextStuff();
				updateSkipTimeText();
			}
			FlxTween.tween(item, { alpha: 1 }, 0.5, { startDelay: 0.3 * i });
		}
		curSelected = 0;
		changeSelection();
	}
	
	function updateSkipTextStuff()
	{
		if(skipTimeText == null || skipTimeTracker == null) return;

		/**skipTimeText.x = skipTimeTracker.x + skipTimeTracker.width + 60;
		skipTimeText.y = skipTimeTracker.y;**/
		skipTimeText.visible = (skipTimeTracker.alpha >= 1);
	}

	function updateSkipTimeText()
	{
		skipTimeText.text = FlxStringUtil.formatTime(Math.max(0, Math.floor(curTime / 1000)), false) + ' / ' + FlxStringUtil.formatTime(Math.max(0, Math.floor(FlxG.sound.music.length / 1000)), false);
	}
}
