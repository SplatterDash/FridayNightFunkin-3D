package states;

import cpp.vm.Gc;
import backend.Highscore;

import flixel.input.keyboard.FlxKey;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import tjson.TJSON as Json;
import flixel.sound.FlxSound;

import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.BitmapData;

import shaders.ColorSwap;

import Random;

import states.OutdatedState;
import states.MainMenuState;

#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

#if VIDEOS_ALLOWED 
#if (hxCodec >= "3.0.0") import hxcodec.flixel.FlxVideo as VideoHandler;
#elseif (hxCodec >= "2.6.1") import hxcodec.VideoHandler as VideoHandler;
#elseif (hxCodec == "2.6.0") import VideoHandler;
#else import vlc.MP4Handler as VideoHandler; #end
#end

typedef TitleData =
{

	titlex:Float,
	titley:Float,
	startx:Float,
	starty:Float,
	gfx:Float,
	gfy:Float,
	backgroundSprite:String,
	bpm:Int
}

class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var initialized:Bool = false;

	var blackScreen:FlxSprite;
	var credGroup:FlxGroup;
	var credTextShit:Alphabet;
	var textGroup:FlxTypedGroup<Alphabet>;
	var ngSpr:FlxSprite;
	var psychSpr:FlxSprite;

	public static var easterEggKeys:Array<String> = [
		'PUMPKINS', 'DADDY', 'AFFLICTION', 'AUDITY', 'AMBATUKUM', 'SHUTUP', 'NOER', 'MCDONALDS', 'AYONEPH', 'DOOMI', 'NOTETTE', 'DEVELOPMENT', 'YOUMADEME'
	];
	var allowedKeys:String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

	public static var theWackys:Array<String> = [
		"penis.", "no honey mustard", "heeeeeelp", "hartwell white.", "what're we getting for dinner?"
	];

	var easterEggKeysBuffer:String = '';
	var inEgg:Bool = false;
	
	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];

	var curWacky:Array<String> = [];

	var wackyImage:FlxSprite;

	var funnySound:FlxSound;
	var hasAFunny:Bool = false;
	var video:VideoHandler = null;
	var nowPlaying:Bool = false;

	var mustUpdate:Bool = false;

	var titleJSON:TitleData;

	public static var updateVersion:String = '';

	override public function create():Void
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];
		
		curWacky = FlxG.random.getObject(getIntroTextShit());

		if(curWacky.contains('.')) {
			curWacky.insert(curWacky.indexOf('.'), '');
			curWacky.remove('.');
		}

		super.create();

		FlxG.save.bind('funkin', CoolUtil.getSavePath());
		FlxG.save.data.gameVersion = '1.0';

		ClientPrefs.loadPrefs();

		Highscore.load();

		if(curWacky[1].toLowerCase() == "penis.") funnySound = new FlxSound().loadEmbedded(Paths.sound('quack'))
		else if(curWacky[1].toLowerCase() == "heeeeeelp") funnySound = new FlxSound().loadEmbedded(Paths.sound('helpme'))
		else if(curWacky[1].toLowerCase() == "hartwell white.") funnySound = new FlxSound().loadEmbedded(Paths.sound('confession'))
		else if(curWacky[1].toLowerCase() == "what're we getting for dinner?") funnySound = new FlxSound().loadEmbedded(Paths.sound('gasstation'))
		else if(curWacky[1].toLowerCase() == "no honey mustard") funnySound = new FlxSound().loadEmbedded(Paths.sound('vineboom'));

		if(funnySound != null) {
			//funnySound = new FlxSound().loadEmbedded(Paths.sound(theSound));
			funnySound.volume = 0.7 * ClientPrefs.data.soundVolume;
			hasAFunny = true;
		}

		// IGNORE THIS!!!
		titleJSON = Json.parse(Paths.getTextFromFile('images/gfDanceTitle.json'));

		if(!initialized)
		{
			if(FlxG.save.data != null && FlxG.save.data.fullscreen)
			{
				FlxG.fullscreen = FlxG.save.data.fullscreen;
				//trace('LOADED FULLSCREEN SETTING!!');
			}
			persistentUpdate = true;
			persistentDraw = true;
		}

		video = new VideoHandler();
		video.height = FlxG.camera.getViewRect().height;
		video.width = FlxG.camera.getViewRect().width;
		video.x = FlxG.camera.getViewRect().left;
		video.y = FlxG.camera.getViewRect().top;
		video.onEndReached.add(function() {
			video.stop();
			video.visible = false;
			nowPlaying = false;
		});
		video.onStopped.add(function() {
			video.stop();
			video.visible = false;
		});
		video.volume = 1;
		//add(video);

		if(curWacky[0].toLowerCase() == 'fall.') {
			var filepath:String = Paths.video('fall');
			video.play(filepath);
			video.pause();
			video.position = 0;
		};


		FlxG.mouse.visible = false;
		#if FREEPLAY
		MusicBeatState.switchState(new FreeplayState());
		#elseif CHARTING
		MusicBeatState.switchState(new ChartingState());
		#else
		if(FlxG.save.data.flashing == null && !FlashingState.leftState) {
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new FlashingState());
		} else {
			if (initialized)
				startIntro();
			else
			{
				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					startIntro();
				});
			}
		}
		#end
	}

	var logoBl:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;
	var swagShader:ColorSwap = null;

	override function onFocus() {
		if(!video.isPlaying && nowPlaying) video.resume();
		super.onFocus();
	}

	override function onFocusLost() {
		if(video.isPlaying && nowPlaying) video.pause();
		super.onFocusLost();
	}

	function startIntro()
	{
		if (!initialized)
		{
			if(FlxG.sound.music == null) {
				FlxG.sound.playMusic(Paths.music('3dmainmenu'), 0);
			}
		}

		Conductor.bpm = titleJSON.bpm;
		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite();
		bg.antialiasing = ClientPrefs.data.antialiasing;

		if (titleJSON.backgroundSprite != null && titleJSON.backgroundSprite.length > 0 && titleJSON.backgroundSprite != "none"){
			bg.loadGraphic(Paths.image(titleJSON.backgroundSprite));
			bg.setGraphicSize(Std.int(bg.width * 0.6));
			bg.updateHitbox();
		}else{
			bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		}
		bg.screenCenter();
		add(bg);

		logoBl = new FlxSprite(titleJSON.titlex, titleJSON.titley);
		logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
		logoBl.antialiasing = ClientPrefs.data.antialiasing;

		logoBl.animation.addByPrefix('bump', 'logobumpin', 24, false);
		logoBl.animation.play('bump');
		logoBl.setGraphicSize(Std.int(logoBl.width * 0.85));
		logoBl.updateHitbox();
		logoBl.screenCenter();
		// logoBl.color = FlxColor.BLACK;

		if(ClientPrefs.data.shaders) swagShader = new ColorSwap();
		/**gfDance = new FlxSprite(titleJSON.gfx, titleJSON.gfy);
		gfDance.antialiasing = ClientPrefs.data.antialiasing;

				gfDance.frames = Paths.getSparrowAtlas('gfDanceTitle');
				gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
				gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);

		add(gfDance);**/
		add(logoBl);
		if(swagShader != null)
		{
			//gfDance.shader = swagShader.shader;
			logoBl.shader = swagShader.shader;
		}

		titleText = new FlxSprite(titleJSON.startx, titleJSON.starty);
		titleText.frames = Paths.getSparrowAtlas('titleEnter');
		var animFrames:Array<FlxFrame> = [];
		@:privateAccess {
			titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}
		
		if (animFrames.length > 0) {
			newTitle = true;
			
			titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
			titleText.animation.addByPrefix('press', ClientPrefs.data.flashing ? "ENTER PRESSED" : "ENTER FREEZE", 24);
		}
		else {
			newTitle = false;
			
			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}
		
		titleText.animation.play('idle');
		titleText.updateHitbox();
		// titleText.screenCenter(X);
		add(titleText);

		var logo:FlxSprite = new FlxSprite().loadGraphic(Paths.image('logo'));
		logo.antialiasing = ClientPrefs.data.antialiasing;
		logo.screenCenter();
		// add(logo);

		// FlxTween.tween(logoBl, {y: logoBl.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG});
		// FlxTween.tween(logo, {y: logoBl.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG, startDelay: 0.1});

		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxTypedGroup<Alphabet>();

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		credTextShit = new Alphabet(0, 0, "", true);
		credTextShit.screenCenter();

		// credTextShit.alignment = CENTER;

		credTextShit.visible = false;

		ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('newgrounds_logo'));
		add(ngSpr);
		ngSpr.visible = false;
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.x -= 260;
		ngSpr.antialiasing = ClientPrefs.data.antialiasing;

		psychSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('logo'));
		add(psychSpr);
		psychSpr.visible = false;
		psychSpr.setGraphicSize(Std.int(psychSpr.width * 0.8));
		psychSpr.updateHitbox();
		psychSpr.screenCenter(X);
		psychSpr.x += 260;
		psychSpr.antialiasing = ClientPrefs.data.antialiasing;

		FlxTween.tween(credTextShit, {y: credTextShit.y + 20}, 2.9, {ease: FlxEase.quadInOut, type: PINGPONG});

		if (initialized)
			skipIntro();
		else
			initialized = true;

		// credGroup.add(credTextShit);
	}

	function getIntroTextShit():Array<Array<String>>
	{
		var fullText:String = Assets.getText(Paths.txt('introText'));
		var firstArray:Array<String> = fullText.split(';');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			var bugFix = i.split('--');
			swagGoodArray.push([bugFix[0].trim(), bugFix[1]]);
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;
	private static var playJingle:Bool = false;
	
	var newTitle:Bool = false;
	var titleTimer:Float = 0;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
		// FlxG.watch.addQuick('amp', FlxG.sound.music.amplitude);

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;

			#if switch
			if (gamepad.justPressed.B)
				pressedEnter = true;
			#end
		}
		
		if (newTitle) {
			titleTimer += FlxMath.bound(elapsed, 0, 1);
			if (titleTimer > 2) titleTimer -= 2;
		}

		if (initialized && !transitioning && skippedIntro)
		{
			if (newTitle && !pressedEnter)
			{
				var timer:Float = titleTimer;
				if (timer >= 1)
					timer = (-timer) + 2;
				
				timer = FlxEase.quadInOut(timer);
				
				titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
				titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
			}
			
			if(pressedEnter)
			{
				if(inEgg && video.time < video.length - 500) {
					video.time = video.length - 500;
					return;
				}
				titleText.color = FlxColor.WHITE;
				titleText.alpha = 1;
				
				if(titleText != null) titleText.animation.play('press');

				FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7 * ClientPrefs.data.soundVolume);

				transitioning = true;
				video = null;
				// FlxG.sound.music.stop();

				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					#if html5
					if(states.IllegalCopyState)MusicBeatState.switchState(new states.IllegalCopyState());
					#end
					if (FlxG.save.data.seenIntro == null || !FlxG.save.data.seenIntro) {
						MusicBeatState.switchState(new IntroState());
					} else {
						MusicBeatState.switchState(new MainMenuState());
					}
					closedState = true;
				});
				// FlxG.sound.play(Paths.music('titleShoot'), 0.7);
			}
			else if (FlxG.keys.firstJustPressed() != FlxKey.NONE)
				{
					var keyPressed:FlxKey = FlxG.keys.firstJustPressed();
					var keyName:String = Std.string(keyPressed);
					if(allowedKeys.contains(keyName)) {
						easterEggKeysBuffer += keyName;
						if(easterEggKeysBuffer.length >= 32) easterEggKeysBuffer = easterEggKeysBuffer.substring(1);
						//trace('Test! Allowed Key pressed!!! Buffer: ' + easterEggKeysBuffer);
	
						for (wordRaw in easterEggKeys)
						{
							var word:String = wordRaw.toUpperCase(); //just for being sure you're doing it right
							if (easterEggKeysBuffer.contains(word))
							{
								inEgg = true;
								nowPlaying = true;
								FlxG.sound.music.fadeOut(0.5, 0.2 * ClientPrefs.data.musicVolume);
								video.visible = true;
								video.play(Paths.video(word.toLowerCase()));
								video.onEndReached.add(function() {
									FlxG.sound.music.fadeIn(0.5, 0.7 * ClientPrefs.data.musicVolume);
								});
								easterEggKeysBuffer = '';
								break;
							}
						}
					}
				}
		}

		if (initialized && pressedEnter && !skippedIntro)
		{
			skipIntro();
		}

		if(swagShader != null)
		{
			if(controls.UI_LEFT) swagShader.hue -= elapsed * 0.1;
			if(controls.UI_RIGHT) swagShader.hue += elapsed * 0.1;
		}

		super.update(elapsed);
	}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0)
	{
		for (i in 0...textArray.length)
		{
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true);
			money.screenCenter(X);
			money.y += (i * 60) + 200 + offset;
			if(credGroup != null && textGroup != null) {
				credGroup.add(money);
				textGroup.add(money);
			}
		}
	}

	function addMoreText(text:String, ?offset:Float = 0)
	{
		if(textGroup != null && credGroup != null) {
			var coolText:Alphabet = new Alphabet(0, 0, text, true);
			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200 + offset;
			credGroup.add(coolText);
			textGroup.add(coolText);
		}
	}

	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	function deleteFirstCoolText()
		{
				credGroup.remove(textGroup.members[0], true);
				textGroup.remove(textGroup.members[0], true);

				for(text in textGroup.members) text.y -= 60;
		}

	private var sickBeats:Int = 0; //Basically curBeat but won't be skipped if you hold the tab or resize the screen
	public static var closedState:Bool = false;
	override function beatHit()
	{
		super.beatHit();

		if(logoBl != null)
			logoBl.animation.play('bump', true);

		/**if(gfDance != null) {
			danceLeft = !danceLeft;
			if (danceLeft)
				gfDance.animation.play('danceRight');
			else
				gfDance.animation.play('danceLeft');
		}**/

		if(!closedState) {
			sickBeats++;
			switch (sickBeats)
			{
				case 1:
					//FlxG.sound.music.stop();
					FlxG.sound.playMusic(Paths.music('3dmainmenu'), 0);
					FlxG.sound.music.fadeIn(4, 0, 0.7 * ClientPrefs.data.musicVolume);
				case 2:
					createCoolText(['The 3D Funkin Team'], 40);
				// credTextShit.visible = true;
				case 4:
					addMoreText('presents', 40);
				// credTextShit.text += '\npresent...';
				// credTextShit.addText();
				case 5:
					deleteCoolText();
				// credTextShit.visible = false;
				// credTextShit.text = 'In association \nwith';
				// credTextShit.screenCenter();
				case 6:
					createCoolText(['In association', 'with'], -150);
				case 8:
					addMoreText('Psych Engine', -150);
					addMoreText('&', -150);
					addMoreText('newgrounds', -150);
					psychSpr.visible = ngSpr.visible = true;
				// credTextShit.text += '\nNewgrounds';
				case 9:
					deleteCoolText();
					psychSpr.visible = ngSpr.visible = false;
				// credTextShit.visible = false;

				// credTextShit.text = 'Shoutouts Tom Fulp';
				// credTextShit.screenCenter();
				case 10:
					if(curWacky[0] == 'my name is walter' && !skippedIntro) {
						FlxG.sound.play(Paths.sound('recordscratch'), 1 * ClientPrefs.data.soundVolume);
						FlxG.sound.music.pause();
						var timer:FlxTimer = new FlxTimer().start(1.378, function(tmr:FlxTimer) {
							funnySound.play();
							createCoolText([curWacky[0]]);
							addMoreText(curWacky[1]);
							var timer:FlxTimer = new FlxTimer().start(2.654, function(tmr:FlxTimer) {
								addMoreText('I live at');
								var timer:FlxTimer = new FlxTimer().start(0.478, function(tmr:FlxTimer) {
									addMoreText('308 Negra Arroyo Lane');
									addMoreText('Albuquerque, NM 87104');
									var timer:FlxTimer = new FlxTimer().start(6.372, function(tmr:FlxTimer) {
										addMoreText('This is my confession.');
										var timer:FlxTimer = new FlxTimer().start(0.4, function(tmr:FlxTimer) {
											FlxG.sound.music.volume = 0;
											FlxG.sound.music.resume();
										});
									});
								});
							});
						});
					}
					else if(curWacky[0] == 'you, me, gas station.' && !skippedIntro) {
						FlxG.sound.music.pause();
						funnySound.play();
						createCoolText([curWacky[0]]);
						var timer:FlxTimer = new FlxTimer().start(2.159, function(tmr:FlxTimer) {
							addMoreText(curWacky[1]);
							var timer:FlxTimer = new FlxTimer().start(1.255, function(tmr:FlxTimer) {
								addMoreText('Sushi of course!');
								var timer:FlxTimer = new FlxTimer().start(1.534, function(tmr:FlxTimer) {
									addMoreText('Uh oh!');
									var timer:FlxTimer = new FlxTimer().start(0.66, function(tmr:FlxTimer) {
										addMoreText('There was a roofie inside of');
										addMoreText('our gas station sushi!');
										var timer:FlxTimer = new FlxTimer().start(2.718, function(tmr:FlxTimer) {
											deleteFirstCoolText();
											addMoreText('We black out and');
											var timer:FlxTimer = new FlxTimer().start(0.878, function(tmr:FlxTimer) {
												deleteFirstCoolText();
												addMoreText('wake up in a sewer');
												var timer:FlxTimer = new FlxTimer().start(1.133, function(tmr:FlxTimer) {
													deleteFirstCoolText();
													addMoreText("We're surrounded by fish.");
													var timer:FlxTimer = new FlxTimer().start(1.378, function(tmr:FlxTimer) {
														deleteFirstCoolText();
														addMoreText('Horny fish!');
														var timer:FlxTimer = new FlxTimer().start(0.925, function(tmr:FlxTimer) {
															deleteFirstCoolText();
															addMoreText('You know what that means...');
															var timer:FlxTimer = new FlxTimer().start(1.2, function(tmr:FlxTimer) {
																deleteFirstCoolText();
																addMoreText("FISH!");
																var timer:FlxTimer = new FlxTimer().start(0.351, function(tmr:FlxTimer) {
																	deleteFirstCoolText();
																	addMoreText('The stench drives in a bear.');
																	var timer:FlxTimer = new FlxTimer().start(1.729, function(tmr:FlxTimer) {
																		deleteFirstCoolText();
																		addMoreText('What do we do?');
																		var timer:FlxTimer = new FlxTimer().start(0.833, function(tmr:FlxTimer) {
																			deleteFirstCoolText();
																			addMoreText('We\'re gonna fight it!');
																			var timer:FlxTimer = new FlxTimer().start(1.2, function(tmr:FlxTimer) {
																				deleteFirstCoolText();
																				addMoreText('Bear fight!');
																				var timer:FlxTimer = new FlxTimer().start(1.025, function(tmr:FlxTimer) {
																					deleteFirstCoolText();
																					addMoreText('Bear handed!');
																					var timer:FlxTimer = new FlxTimer().start(1.043, function(tmr:FlxTimer) {
																						deleteFirstCoolText();
																						addMoreText('Bear');
																						var timer:FlxTimer = new FlxTimer().start(0.543, function(tmr:FlxTimer) {
																							deleteFirstCoolText();
																							addMoreText('naked?');
																							var timer:FlxTimer = new FlxTimer().start(0.891, function(tmr:FlxTimer) {
																								deleteFirstCoolText();
																								addMoreText('Oh yes, please!');
																								var timer:FlxTimer = new FlxTimer().start(1.612, function(tmr:FlxTimer) {
																									deleteFirstCoolText();
																									deleteFirstCoolText();
																									addMoreText('We befriend the bear after');
																									addMoreText('we beat it in a brawl,');
																									var timer:FlxTimer = new FlxTimer().start(2.677, function(tmr:FlxTimer) {
																										deleteFirstCoolText();
																										deleteFirstCoolText();
																										addMoreText('then we ride it into a');
																										addMoreText('Chuck E Cheese.');
																										var timer:FlxTimer = new FlxTimer().start(2.016, function(tmr:FlxTimer) {
																											deleteFirstCoolText();
																											addMoreText('Dance Dance Revolution!');
																											var timer:FlxTimer = new FlxTimer().start(2.007, function(tmr:FlxTimer) {
																												deleteFirstCoolText();
																												addMoreText('Revolution?');
																												var timer:FlxTimer = new FlxTimer().start(1.084, function(tmr:FlxTimer) {
																													deleteFirstCoolText();
																													addMoreText('Overthrow the government?');
																													var timer:FlxTimer = new FlxTimer().start(1.472, function(tmr:FlxTimer) {
																														deleteFirstCoolText();
																														addMoreText('Uhhh, I think so!');
																														var timer:FlxTimer = new FlxTimer().start(1.894, function(tmr:FlxTimer) {
																															deleteFirstCoolText();
																															addMoreText('Next thing you know,');
																															var timer:FlxTimer = new FlxTimer().start(0.908, function(tmr:FlxTimer) {
																																deleteFirstCoolText();
																																deleteFirstCoolText();
																																addMoreText('I\'m reincarnated as');
																																addMoreText('Jesus Christ!');
																																var timer:FlxTimer = new FlxTimer().start(2.199, function(tmr:FlxTimer) {
																																	deleteFirstCoolText();
																																	addMoreText('Then I turn into a jet,');
																																	var timer:FlxTimer = new FlxTimer().start(1.541, function(tmr:FlxTimer) {
																																		deleteFirstCoolText();
																																		addMoreText('fly into the sun,');
																																		var timer:FlxTimer = new FlxTimer().start(1.205, function(tmr:FlxTimer) {
																																			deleteFirstCoolText();
																																			addMoreText('black out again,');
																																			var timer:FlxTimer = new FlxTimer().start(1.234, function(tmr:FlxTimer) {
																																				deleteFirstCoolText();
																																				addMoreText('wake up,');
																																				var timer:FlxTimer = new FlxTimer().start(0.786, function(tmr:FlxTimer) {
																																					deleteFirstCoolText();
																																					addMoreText('do a bump,');
																																					var timer:FlxTimer = new FlxTimer().start(0.973, function(tmr:FlxTimer) {
																																						deleteFirstCoolText();
																																						addMoreText('white out');
																																						var timer:FlxTimer = new FlxTimer().start(0.545, function(tmr:FlxTimer) {
																																							deleteFirstCoolText();
																																							deleteFirstCoolText();
																																							addMoreText('which I didn\'t know you');
																																							addMoreText('could do,');
																																							var timer:FlxTimer = new FlxTimer().start(1.457, function(tmr:FlxTimer) {
																																								deleteFirstCoolText();
																																								addMoreText('then I smoked a joint,');
																																								var timer:FlxTimer = new FlxTimer().start(1.456, function(tmr:FlxTimer) {
																																									deleteFirstCoolText();
																																									addMoreText('greened out,');
																																									var timer:FlxTimer = new FlxTimer().start(1.005, function(tmr:FlxTimer) {
																																										deleteFirstCoolText();
																																										addMoreText('then I turned into the sun,');
																																										var timer:FlxTimer = new FlxTimer().start(1.697, function(tmr:FlxTimer) {
																																											deleteFirstCoolText();
																																											addMoreText('Uh oh!');
																																											var timer:FlxTimer = new FlxTimer().start(0.608, function(tmr:FlxTimer) {
																																												deleteFirstCoolText();
																																												deleteFirstCoolText();
																																												addMoreText('Looks like the meth is');
																																												addMoreText('kicking in!');
																																												var timer:FlxTimer = new FlxTimer().start(1.729, function(tmr:FlxTimer) {
																																													var timer:FlxTimer = new FlxTimer().start(0.1, function(tmr:FlxTimer) {
																																														deleteFirstCoolText();
																																														addMoreText(Random.string(15, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"));
																																													}, 25);
																																													var timer:FlxTimer = new FlxTimer().start(1, function(tmr:FlxTimer) {
																																														FlxG.sound.music.volume = 0;
																																														FlxG.sound.music.resume();
																																													});
																																												});
																																											});
																																										});
																																									});
																																								});
																																							});
																																						});
																																					});
																																				});
																																			});
																																		});
																																	});
																																});
																															});
																														});
																													});
																												});
																											});
																										});
																									});
																								});
																							});
																						});
																					});
																				});
																			});
																		});
																	});
																});
															});
														});
													});
												});
											});
										});
									});
								});
							});
						});
					}
					else createCoolText([curWacky[0]]);
				// credTextShit.visible = true;
				case 12:
					if(!skippedIntro) {	
						if(curWacky[0] != 'my name is walter' && curWacky[0] != 'you, me, gas station.') {
							if (curWacky[0] == 'fall.') {
								nowPlaying = true;
								video.resume();
								FlxG.sound.music.volume = 0;
							} else {
								addMoreText(curWacky[1]);
								if(hasAFunny) {
									FlxG.sound.music.volume = 0;
									if(curWacky[0] == 'back with another') {
										FlxG.sound.music.pause();
										funnySound.play();
										var timer:FlxTimer = new FlxTimer().start(1.972, function(timer:FlxTimer) {
											addMoreText('heeeeeeeeeeelp');
											var timer:FlxTimer = new FlxTimer().start(2.56, function(timer:FlxTimer) {
												addMoreText('heeeeelp meeeeeeeeee');
												var timer:FlxTimer = new FlxTimer().start(1.918, function(timer:FlxTimer) {
													addMoreText('heeeeeeeeeeelp');
													FlxG.sound.music.resume();
												});
											});
										});
									}
									else funnySound.play();
								}
							}
						}
					}
				// credTextShit.text += '\nlmao';
				case 13:
					if(FlxG.sound.music.volume == 0 && ClientPrefs.data.musicVolume != 0) {
						if(video != null
							&& video.isSeekable
							&& video.isPlaying
							&& video.bitmapData != null)
								video.stop()
							else if (funnySound != null
								&& funnySound.playing) funnySound.stop();
						FlxG.sound.music.volume = 0.7  * ClientPrefs.data.musicVolume;
					}
					deleteCoolText();
					addMoreText('Den');
				case 14:
					addMoreText('Derek');
				case 15:
					if(FlxG.random.float() <= 0.13) {
						addMoreText('Cornelius John');
						addMoreText('Quavious III');
					} else addMoreText('Dami');
					//addMoreText('Oluwadamilola Ashamu');
					//addMoreText('Ayangade');
				case 16:
					deleteCoolText();
					addMoreText('In', 100);
				case 17:
					skipIntro();
			}
		}
	}

	var skippedIntro:Bool = false;
	var increaseVolume:Bool = false;
	function skipIntro():Void
	{
		if (!skippedIntro)
		{
				remove(ngSpr);
				remove(psychSpr);
				remove(credGroup);
				if(!FlxG.sound.music.playing) FlxG.sound.music.resume();
				if(FlxG.sound.music.volume == 0) FlxG.sound.music.volume = 0.7  * ClientPrefs.data.musicVolume;
				if(funnySound != null && funnySound.playing) funnySound.stop();
				FlxG.camera.flash(FlxColor.WHITE, 4);
				//trace(FlxG.camera.getViewRect().width + ' by ' + FlxG.camera.getViewRect().width);
			skippedIntro = true;
		}
	}
}
