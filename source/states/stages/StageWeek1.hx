package states.stages;

import shaders.ColorOverlay;
import lime.system.ThreadPool;
import lime.app.Future;
import flixel.FlxBasic;
import flixel.graphics.frames.FlxFilterFrames;
import states.stages.objects.*;
import objects.Character;
import shaders.BetterBlurShader;
import shaders.OutlineShader;
import openfl.filters.ShaderFilter;
import flixel.FlxSubState;
import flixel.FlxObject;
#if windows
import shaders.Scanlines;
#end
import backend.ClientPrefs;
import openfl.filters.ColorMatrixFilter;

#if VIDEOS_ALLOWED 
#if (hxCodec >= "3.0.0")
import hxcodec.flixel.FlxVideoSprite as VideoHandler;
import hxcodec.flixel.FlxVideo as VideoOverlay;
#elseif (hxCodec >= "2.6.1")
import hxcodec.VideoSprite as VideoHandler;
import hxcodec.VideoHandler as VideoOverlay;
#elseif (hxCodec == "2.6.0")
import VideoSprite as VideoHandler;
import VideoHandler as VideoOverlay;
#else
import vlc.MP4Sprite as VideoHandler; 
import vlc.MP4Handler as VideoOverlay;
#end
#end

	/**
	 * TODO:
	 * - Optimize Videos
	 */
class StageWeek1 extends BaseStage
{
	//Common stage items
	var bg:FlxSprite;
	var gradient:FlxSprite;
	var redacted:Character;
	var bgChars:FlxSprite;
	var fgChars:FlxSprite;
	var hat:FlxSprite;
	var emptyDaHat:Array<String> = ['parkour', 'breadbank'];
	var noCrowd:Array<String> = ['parkour-freerunner-remix', 'twinz-euphoria-remix', 'forreal-overnighter-remix', 'breadbank'];
	var left:Bool = true;
	var noteDance:Bool = false;
	var backArea:FlxSprite;
	var backGraphics:Array<String> = [];

	//TTM specific
	var outlineShaderBF:OutlineShader = null;
	var outlineShaderDad:OutlineShader = null;
	var outlineShaderGF:OutlineShader = null;
	var outlineShaderRedacted:OutlineShader = null;
	var outlineShaderHat:OutlineShader = null;
	var shadersOn:Bool = false;

	//TTM/Phrenic specific
	var lineText:FlxText;
	var lineBox:FlxSprite;

	//Parkour specific
	var overlay:FlxSprite;
	var overlayText:FlxText;
	var theStart:FlxSprite;

	//Mako specific
	var establishMako:Bool = false;
	var makoArrive:BGSprite;

	//Camera specific
	var bottomShutter:FlxSprite;
	var topShutter:FlxSprite;
	var shutterEstablish:Bool = false;
	var blur:BetterBlurShader;
	var filterOn:Bool = false;
	var filter:FlxFilterFrames;
	var scanlines:ShaderFilter;
	var parkourEffects:Bool = false;
	var wordsEstablish:Bool = false;
	var topText:FlxText;
	var bottomText:FlxText;
	var splitted:Bool = false;
	var bfCamPoint:FlxObject;
	var saturationFilter:ColorMatrixFilter;

	//Video specific
	#if VIDEOS_ALLOWED
	var video:VideoHandler;
	var videoIntro:VideoOverlay = null;
	var videoArray:Array<String> = [];
	var videoInit:Bool = false;
	#end

	//BG Mains specific
	var bgBopLeft:BGSprite = null;
	var bgBopRight:BGSprite = null;
	var forBop:Array<Array<String>> = [
		['forreal', '3Den', '3Derek'],
		['20racks', '3Den', '3Dami'],
		['feelin-torpid', '3Dami', '3Derek'],
		['citrus-bliss', '3Den', '3Derek'],
		['twinz', '3Den'],
		['phrenic', '3Den', '3Dami']
	];
	var leftBgBop:Bool = true;
	var rightBgBop:Bool = true;
	var bgYOffset:Map<String, Int> = [
		'3Dami' => 50,
		'3Derek' => 90,
		'3Den' => 50
	];

	//For Torpid stuff
	var sprayCan:FlxSprite;
	var sprayLine:FlxSprite;

	//Misc
	var theGradient:FlxSprite = null;

	var bfOffsetMap:Map<String, Int> = [
		'3DamiPLAYER' => 500,
		'3DerekPLAYER' => 350,
		'3DenPLAYER' => 850,
		'3Aleto' => 300,
	];

	private static var remixList:Array<String> = ["forreal-overnighter-remix", "twinz-euphoria-remix", "parkour-freerunner-remix"];
	var colorArray:Array<Array<Int>> = [
		[40, 84, 203], [103, 154, 221], [187, 71, 107], [246, 140, 246], [118, 234, 154], [157, 20,	84], [175, 140, 186]
	];
	var lightsUp:Bool = false;
	var lightInt:Int;

	override function create()
	{

		if(Paths.formatToSongPath(PlayState.SONG.song) == 'ttm-true-to-musicality') {
			gradient = new FlxSprite(-1360, -975).loadGraphic(Paths.image('stage/gradients', 'shared'));
			gradient.scrollFactor.set(1, 1);
			gradient.active = false;
			gradient.antialiasing = ClientPrefs.data.antialiasing;
			add(gradient);
		}

		bg = new FlxSprite(-1360, -975).loadGraphic(Paths.image('stage/background', 'shared'));
		bg.scrollFactor.set(1, 1);
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.active = false;

		#if VIDEOS_ALLOWED
		if(!ClientPrefs.data.lowQuality) {
			video = new VideoHandler(0, 0);
			video.scrollFactor.set(0, 0);
			video.bitmap.volume = 0;
			add(video);
			video.cameras = [camHUD];
			video.active = false;
		}
		#end

		add(bg);
		if(!remixList.contains(Paths.formatToSongPath(PlayState.SONG.song))) {
			bg.color = FlxColor.BLACK;
			camGame.bgColor = FlxColor.WHITE;
		 } else {
			camGame.bgColor = FlxColor.BLACK;
			bg.color = FlxColor.WHITE;
		}
		if(Paths.formatToSongPath(PlayState.SONG.song) == 'breadbank' && (FlxG.save.data.seenIntro == null || !FlxG.save.data.seenIntro)) bg.alpha = 0;

		#if desktop
		if(ClientPrefs.data.camEffects) scanlines = new ShaderFilter(new Scanlines());
		#end

		if(!ClientPrefs.data.lowQuality) {
			blur = new BetterBlurShader(1.0);
			//blur.blur = 0.1;
		}

		if(PlayState.SONG.gfVersion != "3Redacted") {
			redacted = new Character(825, 175, "3Redacted");
			add(redacted);
		}

		if(Paths.formatToSongPath(PlayState.SONG.song) == 'offwallet') theBopRate = 2;

		defaultCamZoom = Paths.formatToSongPath(PlayState.SONG.song) == 'breadbank' ? 1 : 0.4;
		currentCamZoom = (Paths.formatToSongPath(PlayState.SONG.song) == 'breadbank' || ((Paths.formatToSongPath(PlayState.SONG.song) == 'ttm-true-to-musicality' || Paths.formatToSongPath(PlayState.SONG.song) == 'twinz') && ClientPrefs.data.camEffects)) ? 1 : 0.4;
		boyfriendGroup.x += 200;
		boyfriendGroup.y += 100;
		dadGroup.x -= 100;
		dadGroup.y += 100;
		gfGroup.x += 50;
	}

	override function eventPushed(event:objects.Note.EventNote)
		{
			switch(event.event)
			{
				case 'Explode.':
					lineBox = new FlxSprite(0, FlxG.camera.getViewRect().bottom - 175).makeGraphic(event.value2 == 'phrenic' ? 900 : 500, 32, FlxColor.BLACK);
					lineBox.alpha = 0.4;
					lineBox.visible = false;
					lineBox.cameras = [camHUD];
					lineBox.antialiasing = ClientPrefs.data.antialiasing;
					lineBox.active = false;
					add(lineBox);

					lineText = new FlxText(25, FlxG.camera.getViewRect().bottom - 175, 0, 'michael mothaf--kin jackson');
					lineText.setFormat(Paths.font('Minecraftia-Regular.ttf'), 20, FlxColor.YELLOW, LEFT, OUTLINE, FlxColor.BLACK);
					lineText.visible = false;
					lineText.cameras = [camHUD];
					lineText.antialiasing = ClientPrefs.data.antialiasing;
					lineText.active = false;
					add(lineText);

				case 'Mako Moment':
					if(event.value1.toLowerCase() != 'mako gone' && !establishMako)
						{
							
							//trace(dadGroup.x + " + " + dad.x + " then " + dad.y + " + " + dad.y);
							var number:Float = FlxG.random.float(0, 1);
							makoArrive = new BGSprite(number > 0.83 ? "MAKOCULO" : "repent", dadGroup.x + dad.x - 2150, dadGroup.y + dad.y + 150);
							makoArrive.setGraphicSize(Std.int(gf.width));
							makoArrive.updateHitbox();
							makoArrive.antialiasing = ClientPrefs.data.antialiasing;
							makoArrive.active = false;
							addBehindDad(makoArrive);

							dad.alpha = 0;

							establishMako = true;
						}

				case 'Play Video BG':
					if(ClientPrefs.data.lowQuality) return;
					#if VIDEOS_ALLOWED
					video.active = true;
					video.play(Paths.video('stages/' + event.value1));
					video.setGraphicSize(Std.int(video.width * 2.5));
					video.updateHitbox();
					video.screenCenter();
					video.x -= 700;
					video.y -= 400;
					video.pause();
					video.bitmap.position = 0;
					videoInit = true;
					#end

				case 'Outline Shaders':
					if(ClientPrefs.data.lowQuality || !ClientPrefs.data.camEffects || !ClientPrefs.data.shaders) return;
					var helperColor = FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]);
					outlineShaderBF = new OutlineShader([helperColor.redFloat, helperColor.greenFloat, helperColor.blueFloat]);

					helperColor = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
					outlineShaderDad = new OutlineShader([helperColor.redFloat, helperColor.greenFloat, helperColor.blueFloat]);

					helperColor = FlxColor.fromRGB(gf.healthColorArray[0], gf.healthColorArray[1], gf.healthColorArray[2]);
					outlineShaderGF = new OutlineShader([helperColor.redFloat, helperColor.greenFloat, helperColor.blueFloat]);

					if(redacted != null) {
						helperColor = FlxColor.fromRGB(redacted.healthColorArray[0], redacted.healthColorArray[1], redacted.healthColorArray[2]);
						outlineShaderRedacted = new OutlineShader([helperColor.redFloat, helperColor.greenFloat, helperColor.blueFloat]);
					}

					helperColor = FlxColor.GREEN;
					outlineShaderHat = new OutlineShader([helperColor.redFloat, helperColor.greenFloat, helperColor.blueFloat]);

				case 'Town BG Design':
					if(ClientPrefs.data.lowQuality) return;
					backArea = new FlxSprite(-1360, -975).loadGraphic(Paths.image('stage/${event.value1}', 'shared'));
					backArea.scrollFactor.set(1, 1);
					backArea.setGraphicSize(Std.int(bg.width));
					backArea.updateHitbox();
					backArea.antialiasing = ClientPrefs.data.antialiasing;
					backArea.alpha = 0;
					backArea.active = false;
					insert(0, backArea);

				case 'Parkour Begin':
					if(PlayState.isStoryMode) {
						bg.alpha = 0;
						redacted.alpha = 0;
						hat.alpha = 0;
					}

				case 'Spray Can':
					sprayCan = new FlxSprite(0, 0);
					sprayCan.frames = Paths.getSparrowAtlas('Spraycan', 'shared');
					sprayCan.animation.addByPrefix('flyup', 'Can', 24, false);
					var viewRect:flixel.math.FlxRect = PlayState.instance.camHUD.getViewRect();
					sprayCan.screenCenter();
					sprayCan.y += 350;
					sprayCan.antialiasing = ClientPrefs.data.antialiasing;
					add(sprayCan);
					sprayCan.cameras = [PlayState.instance.camHUD];

					sprayLine = new FlxSprite(0, 0).loadGraphic(Paths.image('graffitiline'));
					sprayLine.active = false;
					sprayLine.screenCenter();
					sprayLine.color = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
					sprayLine.antialiasing = ClientPrefs.data.antialiasing;
					add(sprayLine);
					sprayLine.cameras = [PlayState.instance.camHUD];

					sprayCan.visible = false;
					sprayLine.visible = false;

				case 'CBP Gradient':
					theGradient = new FlxSprite(bg.x, bg.y).loadGraphic(Paths.image('stage/thegradient', 'shared'));
					theGradient.setGraphicSize(Std.int(bg.width));
					theGradient.updateHitbox();
					theGradient.alpha = 0.4;
					theGradient.active = false;
					insert(members.indexOf(bg), theGradient);
					theGradient.color = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
					theGradient.visible = false;
			}
		}

	override function eventPushedUnique(event:objects.Note.EventNote)
		{
			switch(event.event)
			{
				case 'Mainline Camera Zooms':
					if(event.value1.toLowerCase() == 'parkour like') {
						if(!ClientPrefs.data.camEffects) return;
						if(!shutterEstablish)
						{
							bottomShutter = new FlxSprite(camHUD.getViewRect().left - 150, camHUD.getViewRect().bottom).makeGraphic(Std.int(camHUD.getViewRect().width + 300), 350, FlxColor.BLACK);
							bottomShutter.active = false;
							insert(members.indexOf(PlayState.instance.strumLineNotes), bottomShutter);
							bottomShutter.cameras = [camHUD];

							topShutter = new FlxSprite(camHUD.getViewRect().left - 150, camHUD.getViewRect().top - 350).makeGraphic(Std.int(camHUD.getViewRect().width + 300), 350, FlxColor.BLACK);
							topShutter.active = false;
							insert(members.indexOf(PlayState.instance.strumLineNotes), topShutter);
							topShutter.cameras = [camHUD];

							shutterEstablish = true;
						}
						if(event.value2.toLowerCase() == 'sharlie' && !wordsEstablish) {
							if(ClientPrefs.data.lowQuality) return;
							topText = new FlxText(camHUD.getViewRect().left - 375, camHUD.getViewRect().top + 275, 0, 'GAME');
							topText.setFormat(Paths.font("aAnotherTag.otf"), 160, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
							topText.x -= topText.width;
							topText.angle = -15;
							topText.antialiasing = ClientPrefs.data.antialiasing;
							topText.active = false;
							insert(members.indexOf(PlayState.instance.strumLineNotes), topText);
							topText.cameras = [camHUD];

							bottomText = new FlxText(camHUD.getViewRect().right + 325, camHUD.getViewRect().bottom - 325, 0, 'ON!');
							bottomText.setFormat(Paths.font("aAnotherTag.otf"), 160, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
							bottomText.angle = -15;
							bottomText.antialiasing = ClientPrefs.data.antialiasing;
							bottomText.active = false;
							insert(members.indexOf(PlayState.instance.strumLineNotes), bottomText);
							bottomText.cameras = [camHUD];

							wordsEstablish = true;
						}
					}
					if(event.value1.toLowerCase() == "split screen" && bfCamPoint == null) {
						if(ClientPrefs.data.lowQuality || !ClientPrefs.data.camEffects) return;
						bfCamPoint = new FlxObject(0, 0, 1, 1);
						bfCamPoint.setPosition(boyfriend.getMidpoint().x - boyfriend.cameraPosition[0] - PlayState.instance.boyfriendCameraOffset[0] - 150, boyfriend.getMidpoint().y - 141 + boyfriend.cameraPosition[1] + PlayState.instance.boyfriendCameraOffset[1]);
						add(bfCamPoint);
						splitCam.active = true;
						splitCam.follow(bfCamPoint, LOCKON, 0);
						splitCam.snapToTarget();
						splitCam.zoom = currentCamZoom;

						#if VIDEOS_ALLOWED
						video.cameras = [camGame, splitCam];
						#end
						bg.cameras = [camGame, splitCam];
						boyfriendGroup.cameras = [camGame, splitCam];
						if(PlayState.SONG.gfVersion == "3Redacted") gfGroup.cameras = [camGame, splitCam] else redacted.cameras = [camGame, splitCam];
						if(bgChars != null) bgChars.cameras = [camGame, splitCam];
						if(fgChars != null) fgChars.cameras = [camGame, splitCam];
						hat.cameras = [camGame, splitCam];
						if(bgBopLeft != null) bgBopLeft.cameras = [camGame, splitCam];
						if(bgBopRight != null) bgBopRight.cameras = [camGame, splitCam];
					} else if ((event.value1.toLowerCase() == 'breadbank' && event.value2.toLowerCase() != 'outro' && (FlxG.save.data.seenIntro == null || !FlxG.save.data.seenIntro) && videoIntro == null)) {
						overlay = new FlxSprite(FlxG.camera.getViewRect().left, FlxG.camera.getViewRect().top).makeGraphic(Std.int(FlxG.camera.getViewRect().width), Std.int(FlxG.camera.getViewRect().height), FlxColor.BLACK);
						overlay.active = false;
						add(overlay);
						overlay.cameras = [camHUD];
						
						if(!ClientPrefs.data.lowQuality) {
							videoIntro = new VideoOverlay();
							videoIntro.height = FlxG.camera.getViewRect().height;
							videoIntro.width = FlxG.camera.getViewRect().width;
							videoIntro.x = FlxG.camera.getViewRect().left;
							videoIntro.y = FlxG.camera.getViewRect().top;
							videoIntro.onEndReached.add(function() {
								videoIntro.stop();
								videoIntro.visible = false;
							});
							videoIntro.volume = 0;
							videoIntro.play(Paths.video('stages/intro'));
							videoIntro.pause();
						}
					} else if (event.value1.toLowerCase() == 'twinz' || event.value1.toLowerCase() == 'fade in') {
						overlay = new FlxSprite(FlxG.camera.getViewRect().left, FlxG.camera.getViewRect().top).makeGraphic(Std.int(FlxG.camera.getViewRect().width), Std.int(FlxG.camera.getViewRect().height), FlxColor.BLACK);
						overlay.active = false;
						add(overlay);
						overlay.cameras = [camHUD];
						overlay.visible = true;
					} else if (event.value1.toLowerCase() == 'regular zoom' && event.strumTime == 0) {
						if(!ClientPrefs.data.camEffects) return;
						var theItems = event.value2.split(',');
						if(theItems.length < 2) currentCamZoom = Std.parseFloat(theItems[0].trim());
					} else if (event.value1.toLowerCase() == '20racks') {
						if(!ClientPrefs.data.camEffects) return else currentCamZoom = 0.01;
					}

				case 'Play Video BG':
					if(ClientPrefs.data.lowQuality) return;
					#if VIDEOS_ALLOWED
					videoArray.push(event.value1);
					#end

				case 'Town BG Design':
					if(ClientPrefs.data.lowQuality || event.value1 == '') return;
					if (!backGraphics.contains(event.value1)) Paths.image('stage/${event.value1}', 'shared');
					backGraphics.push(event.value1);

				case 'BG to Main':
					if(event.value1.toLowerCase() != 'left'
						&& event.value1.toLowerCase() != 'right'
					&& event.value1.toLowerCase() != 'gf'
					&& event.value1.toLowerCase() != 'boyfriend'
					&& (event.value1.toLowerCase() != 'boyfriend2' || (event.value1.toLowerCase() == 'boyfriend2' && boyfriend2 == null))
					&& event.value1.toLowerCase() != 'dad')
						return;
					if(ClientPrefs.data.lowQuality) return;
					switch(event.value1.toLowerCase()) {
						case 'dad':
							if(dad.visible) {
								dad.x -= 2000;
								dad.visible = false;
							}
						case 'gf':
							if(gf.visible) {
								gf.x += 2000;
								gf.visible = false;
							}
						case 'boyfriend':
							if(boyfriend.visible) {
								boyfriend.x += 2000;
								boyfriend.visible = false;
							}
						case 'boyfriend2':
							if(boyfriend2 != null && boyfriend2.visible) {
								boyfriend2.x += 2000;
								boyfriend2.visible = false;
							}
					}

				case "BunBeats":
					if(ClientPrefs.data.lowQuality) return;
							topText = new FlxText(0, camHUD.getViewRect().top + 10, 0, 'BUN');
							topText.setFormat(Paths.font("DonGraffiti.otf"), 160, FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]), CENTER, OUTLINE, FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
							topText.screenCenter(X);
							topText.antialiasing = ClientPrefs.data.antialiasing;
							topText.active = false;
							insert(members.indexOf(PlayState.instance.strumLineNotes), topText);
							topText.cameras = [camHUD];
							topText.visible = false;

							bottomText = new FlxText(0, camHUD.getViewRect().bottom - 10, 0, 'BEATS');
							bottomText.setFormat(Paths.font("DonGraffiti.otf"), 160, FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]), CENTER, OUTLINE, FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
							bottomText.screenCenter(X);
							bottomText.antialiasing = ClientPrefs.data.antialiasing;
							bottomText.active = false;
							insert(members.indexOf(PlayState.instance.strumLineNotes), bottomText);
							bottomText.y -= bottomText.height;
							bottomText.cameras = [camHUD];
							bottomText.visible = false;
			}
		}

	override function createPost() {
		if(PlayState.SONG.gfVersion == "3Redacted") {
			gfGroup.x += 50;
			gfGroup.y += 125;
		} else if(boyfriend2 != null) {
			redacted.x = 550;
			redacted.y = 130;
		}
		if(Paths.formatToSongPath(PlayState.SONG.song) == 'twinz' || Paths.formatToSongPath(PlayState.SONG.song) == 'twinz-euphoria-remix')
			gf.flipX = true
		else if (Paths.formatToSongPath(PlayState.SONG.song) == 'phrenic') {
			gf.x += 200;
			//gf.y += 50;
			redacted.x -= 600;
			//redacted.y -= 100;
			gf.flipX = false;
		} else if(Paths.formatToSongPath(PlayState.SONG.song) == 'citrus-bliss' /**|| Paths.formatToSongPath(PlayState.SONG.song) == 'full-house'**/) {
			gfGroup.x += 650;
			gfGroup.y += 200;
			gf.flipX = false;
			gf.cameraPosition[0] *= -1;
			gf.cameraPosition[0] -= 100;
			gf.cameraPosition[0] -= 100;
		}

		boyfriend.cameraPosition = [boyfriend.cameraPosition[0] - 100, boyfriend.cameraPosition[1] - 150];
		gf.cameraPosition = [gf.cameraPosition[0] + 100, gf.cameraPosition[1] - 50];
		dad.cameraPosition = [dad.cameraPosition[0] + 200, dad.cameraPosition[1] - 150];

		#if VIDEOS_ALLOWED
		video.kill();
		video.bitmap.onEndReached.add(function() {
			video.stop();
			video.visible = false;
			if(videoArray.length > 0) {
				video.play(Paths.video('stages/' + videoArray[0]));
				video.pause();
				video.bitmap.position = 0;
			} else video.destroy();
		});
		#end

		if(!remixList.contains(Paths.formatToSongPath(PlayState.SONG.song)) || Paths.formatToSongPath(PlayState.SONG.song) == 'breadbank') {
			hat = new FlxSprite(700, 700).loadGraphic(Paths.image(emptyDaHat.contains(Paths.formatToSongPath(PlayState.SONG.song)) ? "emptyhat" : (PlayState.SONG.song.toLowerCase() == 'offwallet' ? "semifullhat" : "fullhat"), "shared"));
			hat.scrollFactor.set(1, 1);
			hat.antialiasing = ClientPrefs.data.antialiasing;
			hat.active = false;
			add(hat);
		}


		if(PlayState.SONG.song.toLowerCase() == 'parkour')
			{
				overlay = new FlxSprite(FlxG.camera.getViewRect().left, FlxG.camera.getViewRect().top).makeGraphic(Std.int(FlxG.camera.getViewRect().width), Std.int(FlxG.camera.getViewRect().height), FlxColor.BLACK);
				overlay.active = false;
				add(overlay);
				overlay.cameras = [camHUD];

				if(PlayState.isStoryMode) {
					theStart = new FlxSprite().loadGraphic(Paths.image('theoriginal', 'shared'));
					theStart.setGraphicSize(0, camHUD.viewHeight);
					theStart.x = overlay.x + (overlay.width / 2) - (theStart.width / 2);
					theStart.y = overlay.y + (overlay.height / 2) - (theStart.height / 2);
					theStart.active = false;
					theStart.alpha = 0;
					add(theStart);
					theStart.cameras = [camHUD];
				}

				overlayText = new FlxText(0, 0, 0, "Somewhere above\nthe buildings...");
				overlayText.setFormat(Paths.font('vcr.ttf'), 40, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
				overlayText.x = overlay.x + (overlay.width / 2) - (overlayText.width / 2);
				overlayText.y = overlay.y + (overlay.height / 2) - (overlayText.height / 2);
				overlayText.alpha = 0;
				overlayText.active = false;
				add(overlayText);
				overlayText.cameras = [camHUD];
			} else if (!ClientPrefs.data.lowQuality && !noCrowd.contains(Paths.formatToSongPath(PlayState.SONG.song))) {
				bgChars = new FlxSprite(-1150, -1025);
				bgChars.frames = Paths.getSparrowAtlas('stage/bgCharacters');
				bgChars.animation.addByPrefix('bg', 'bg', 24, false);
				bgChars.setGraphicSize(Std.int(bgChars.width * 2));
				bgChars.updateHitbox();
				bgChars.antialiasing = ClientPrefs.data.antialiasing;
				if(Paths.formatToSongPath(PlayState.SONG.song) == 'citrus-bliss') addBehindDad(bgChars) else addBehindGF(bgChars);
				if(PlayState.SONG.song.toLowerCase() != 'offwallet')
					{
						fgChars = new FlxSprite(-950, 725);
						fgChars.frames = Paths.getSparrowAtlas('stage/fgChars');
						fgChars.animation.addByPrefix('fg', 'fg', 24, false);
						fgChars.setGraphicSize(Std.int(fgChars.width * 2));
						fgChars.updateHitbox();
						fgChars.antialiasing = ClientPrefs.data.antialiasing;
						add(fgChars);
						//fgChars.cameras = [camGame, splitCam];
					}
			}

		if(!ClientPrefs.data.lowQuality) 
			{
				for(member in forBop) if(Paths.formatToSongPath(PlayState.SONG.song) == member[0]) {
					bgBopLeft = new BGSprite('stage/${member[1]}', redacted != null ? redacted.x - 350 : gf.x - 350, redacted != null ? redacted.y + bgYOffset.get(member[1]) : gf.y + bgYOffset.get(member[1]) + 25, 1, 1, member[1] == '3Den' ? ['moveLeft', 'moveRight', 'cue'] : ['move']);
					if(member[1] == '3Dami') bgBopLeft.flipX = true;
					bgBopLeft.setGraphicSize(Std.int(bgBopLeft.width * (member[1] == '3Dami' ? 1.6 : 1.4)));
					bgBopLeft.updateHitbox();
					bgBopLeft.antialiasing = ClientPrefs.data.antialiasing;
					insert(game.members.indexOf(redacted != null ? redacted : gfGroup), bgBopLeft);
					if(member.length == 3) {
						bgBopRight = new BGSprite('stage/${member[2]}', redacted != null ? redacted.x + redacted.width - 300 : gf.x + gf.width - 300, redacted != null ? redacted.y + bgYOffset.get(member[2]) : gf.y + bgYOffset.get(member[2]) - 25, 1, 1, member[2] == '3Derek' ? ['move', 'cue'] : ['move']);
						if(member[2] == '3Derek') bgBopRight.flipX = true;
						bgBopRight.setGraphicSize(Std.int(bgBopRight.width * (member[2] == '3Dami' ? 1.6 : 1.3)));
						bgBopRight.updateHitbox();
						bgBopRight.antialiasing = ClientPrefs.data.antialiasing;
						insert(game.members.indexOf(redacted != null ? redacted : gfGroup), bgBopRight);
					}
				}
			}
	}

	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
		{
			switch(eventName)
			{
				case 'Explode.':
					if(value2 == 'phrenic') {
						if(value1 == 'true') {
							dad.alpha = 1;
						} else {
							dad.alpha = 0;
						}
						lineText.text = '<Server> SylvS3Xter has ${value1 == 'true' ? 'joined the game' : 'been kicked by sickenaleto. Reason: kys'}';
						lineBox.visible = true;
						lineText.visible = true;
						var timer = new FlxTimer().start(5, function(tmr:FlxTimer) {
							FlxTween.tween(lineText, { alpha: 0 }, 1, {onComplete: function(twn:FlxTween) {
								lineText.visible = false;
								lineText.alpha = 1;
							}});
							FlxTween.tween(lineBox, { alpha: 0 }, 1, {onComplete: function(twn:FlxTween) {
								lineBox.visible = false;
								lineBox.alpha = 0.4;
							}});
						});
					} else {
						if(value1 == 'true') {
							gf.alpha = 1;
						} else {
							gf.alpha = 0;
						}
						lineText.text = '<Server> no7e has ${value1 == 'true' ? 'joined' : 'left'} the game';
						lineBox.visible = true;
						lineText.visible = true;
						var timer = new FlxTimer().start(5, function(tmr:FlxTimer) {
							FlxTween.tween(lineText, { alpha: 0 }, 1, {onComplete: function(twn:FlxTween) {
								lineText.visible = false;
								lineText.alpha = 1;
							}});
							FlxTween.tween(lineBox, { alpha: 0 }, 1, {onComplete: function(twn:FlxTween) {
								lineBox.visible = false;
								lineBox.alpha = 0.4;
							}});
						});
					}
				
				case 'Mainline Camera Zooms':
					if(value1.toLowerCase() == 'end.') {
						FlxTween.tween(camHUD, { alpha: 0 }, 1, {onComplete: function(twn:FlxTween) {
							bg.scrollFactor.set(1, 1);
						}});
						FlxTween.tween(bg, {y: -950}, 12, {ease: FlxEase.cubeInOut});
						FlxTween.tween(camGame, {zoom: 2, y: 750}, 12, {ease: FlxEase.cubeInOut, onComplete: function(twn:FlxTween) {
							PlayState.instance.camZooming = false;
							FlxG.camera.fade(FlxColor.BLACK, 3);
						}});
					}
					else if (value1.toLowerCase() == 'parkour like') {
						if(!ClientPrefs.data.camEffects) return;
						if(value2.toLowerCase() == 'sharlie') {
							if(ClientPrefs.data.lowQuality) return;
							FlxG.camera.filtersEnabled = true;
							camGame.zoom += 0.15;
							currentCamZoom += 0.15;
							saturationFilter = new ColorMatrixFilter(saturation_filter_matrix(1.5));
							var theNumb:Float = 1.5;
							//@:privateAccess
							if(FlxG.camera.filters == null) FlxG.camera.filters = [saturationFilter] else FlxG.camera.filters.push(saturationFilter);
							var timer = new FlxTimer().start((Conductor.stepCrochet * 4) / 1000, function(tmr:FlxTimer) {
								var timer = new FlxTimer().start((Conductor.stepCrochet * 4) / 1000, function(tmr:FlxTimer) {
									var theNewNumb = theNumb + 0.5;
									//@:privateAccess
									FlxG.camera.filters.remove(saturationFilter);
									saturationFilter = new ColorMatrixFilter(saturation_filter_matrix(theNewNumb));
									//@:privateAccess
									FlxG.camera.filters.push(saturationFilter);
									bottomShutter.y -= 25;
									topShutter.y += 25;
									camGame.zoom += 0.15;
									currentCamZoom += 0.15;
									theNumb = theNewNumb;
								}, 3);
							}, 1);
							FlxTween.tween(bottomShutter, {y: bottomShutter.y - 150}, (Conductor.stepCrochet * 24) / 1000, {onComplete: function(twn:FlxTween) {
								FlxTween.tween(bottomShutter, {angle: -15}, (Conductor.stepCrochet * 2) / 1000, { ease: FlxEase.cubeOut, onComplete: function(twn:FlxTween) {
									FlxTween.tween(bottomText, {x: bottomText.x - 900, y: bottomText.y + 150}, (Conductor.stepCrochet * 2) / 1000, {startDelay: (Conductor.stepCrochet * 2) / 1000, ease:FlxEase.circOut, onComplete: function(twn:FlxTween) {
										FlxTween.tween(bottomText, {x: bottomText.x - 900, y: bottomText.y + 150}, (Conductor.stepCrochet * 2) / 1000, {ease:FlxEase.circIn, onComplete: function(twn:FlxTween) {
											currentCamZoom = defaultCamZoom;
											//@:privateAccess
											FlxG.camera.filters.remove(saturationFilter);
											FlxG.camera.filtersEnabled = false;
											FlxTween.tween(bottomShutter, {angle: 0, y: bottomShutter.y + 150}, (Conductor.stepCrochet * 2) / 1000, {ease: FlxEase.cubeOut});
										}});
									}});
								}});
							}});
							FlxTween.tween(topShutter, {y: topShutter.y + 150}, (Conductor.stepCrochet * 24) / 1000, {onComplete: function(twn:FlxTween) {
								FlxTween.tween(topShutter, {angle: -15}, (Conductor.stepCrochet * 2) / 1000, { ease: FlxEase.cubeOut, onComplete: function(twn:FlxTween) {
									FlxTween.tween(topText, {x: topText.x + 900, y: topText.y - 250}, (Conductor.stepCrochet * 2) / 1000, {ease:FlxEase.circOut, onComplete: function(twn:FlxTween) {
										FlxTween.tween(topText, {x: topText.x + 900, y: topText.y - 250}, (Conductor.stepCrochet * 2) / 1000, {startDelay: (Conductor.stepCrochet * 2) / 1000, ease:FlxEase.circIn, onComplete: function(twn:FlxTween) {
											camGame.flash(FlxColor.WHITE, 1);
											FlxTween.tween(topShutter, {angle: 0, y: topShutter.y - 150}, (Conductor.stepCrochet * 2) / 1000, {ease: FlxEase.cubeOut});
										}});
									}});
								}});
							}});
						} else if (value2.toLowerCase() == 'offwallet') {
							if(!parkourEffects) {
								FlxTween.tween(bottomShutter, {y: bottomShutter.y - 100}, 0.8, {ease: FlxEase.cubeOut});
								FlxTween.tween(topShutter, {y: topShutter.y + 100}, 0.8, {ease: FlxEase.cubeOut});
							} else {
								FlxTween.tween(bottomShutter, {y: bottomShutter.y + 100}, 0.8, {ease: FlxEase.cubeOut});
								FlxTween.tween(topShutter, {y: topShutter.y - 100}, 0.8, {ease: FlxEase.cubeOut});
							}
							parkourEffects = !parkourEffects;
						} else {
							if(ClientPrefs.data.lowQuality || !ClientPrefs.data.camEffects) return;
							if(parkourEffects) {
								gf.alpha = 1;
								if(PlayState.instance.gfTrail != null) PlayState.instance.gfTrail.alpha = 1;
								FlxTween.tween(camGame, { zoom: defaultCamZoom }, (Conductor.stepCrochet * 2) / 1000, {ease:FlxEase.cubeOut, onComplete: function(twn:FlxTween) {
									currentCamZoom = defaultCamZoom;
								}});													
								FlxTween.tween(bottomShutter, {angle: 0, y: bottomShutter.y + 100}, 0.4, {ease: FlxEase.cubeOut});
								FlxTween.tween(topShutter, {y: topShutter.y - 100, angle: 0}, 0.4, {ease: FlxEase.cubeOut});
								FlxTween.tween(camGame, { zoom: 1 }, (Conductor.stepCrochet * 4) / 1000, { startDelay: (Conductor.stepCrochet * 28) / 1000, ease: FlxEase.expoIn, onComplete: function(twn:FlxTween) { for (strum in opponentStrums.members) strum.alpha = 1; }});
							} else {
								FlxTween.tween(camGame, { zoom: 0.8 }, (Conductor.stepCrochet * 6) / 1000, {ease:FlxEase.expoIn, onComplete: function(twn:FlxTween) {
									camGame.flash(FlxColor.WHITE, 1);
									currentCamZoom = 0.8;
									gf.alpha = 0;
									for (strum in opponentStrums.members) strum.alpha = 0;
									if(PlayState.instance.gfTrail != null) PlayState.instance.gfTrail.alpha = 0;
									FlxTween.tween(bottomShutter, {y: bottomShutter.y - 100, angle: -15}, 0.8, {ease: FlxEase.cubeOut});
									FlxTween.tween(topShutter, {y: topShutter.y + 100, angle: -15}, 0.8, {ease: FlxEase.cubeOut});
								}});
							}
							parkourEffects = !parkourEffects;
						}
					}
					else if (value1.toLowerCase() == "split screen") {
						if(!ClientPrefs.data.camEffects || ClientPrefs.data.lowQuality) return;
						if(!splitted) {
							splitCam.alpha = 1;
							var timer = new FlxTimer().start((Conductor.stepCrochet * 2) / 1000, function(tmf:FlxTimer) {
								bfCamPoint.setPosition(bfCamPoint.x + 60, bfCamPoint.y + 40);
								camFollow.setPosition(camFollow.x + 60, camFollow.y);
								PlayState.instance.camZooming = false;
								PlayState.instance.isCameraOnForcedPos = true;
								currentCamZoom = 1;
							}, 1);
						} else {
							bfCamPoint.setPosition(bfCamPoint.x - 60, bfCamPoint.y - 40);
							camFollow.setPosition(camFollow.x - 60, camFollow.y);
							camGame.zoom = defaultCamZoom;
							currentCamZoom = defaultCamZoom;
							PlayState.instance.isCameraOnForcedPos = false;
							//PlayState.instance.camZooming = true;
							var tmr = new FlxTimer().start((Conductor.stepCrochet * 14) / 1000, function(tmr:FlxTimer) {
								splitCam.active = false;
								splitCam.alpha = 0;
							}, 1);
						}
						splitted = !splitted;
					} else if(value1.toLowerCase() == 'regular zoom') {
						if(!ClientPrefs.data.camEffects) return;
						var stuffArray:Array<String> = [];
						if(value2 != '') {
							if(value2.contains(',')) stuffArray = value2.split(',') else stuffArray.push(value2);
							for(item in stuffArray) item.trim();
						}
						var newZoom = stuffArray.length > 0 ? Std.parseFloat(stuffArray[0]) : defaultCamZoom;
						currentCamZoom = newZoom;
						PlayState.instance.cameraTwn = FlxTween.tween(camGame, { zoom: newZoom + ((Paths.formatToSongPath(PlayState.SONG.song) == 'breadbank' && PlayState.SONG.notes[curSection].mustHitSection != true) ? 0.3 : 0) }, stuffArray.length > 1 ? Std.parseFloat(stuffArray[1]) : 1, { ease: FlxEase.cubeOut, onComplete: function (twn:FlxTween) {
							PlayState.instance.cameraTwn = null;
						}});
					} else if(value1.toLowerCase() == 'regular rotate') {
						if(!ClientPrefs.data.camEffects) return;
						var stuffArray:Array<String> = [];
						if(value2 != '') {
							if(value2.contains(',')) stuffArray = value2.split(',') else stuffArray.push(value2);
							for(item in stuffArray) item.trim();
						}
						var newRotation = stuffArray.length > 0 ? Std.parseFloat(stuffArray[0]) : 0;
						PlayState.instance.cameraTwn = FlxTween.tween(camGame, { angle: newRotation }, stuffArray.length > 1 ? Std.parseFloat(stuffArray[1]) : 1, { ease: FlxEase.cubeOut, onComplete: function (twn:FlxTween) {
							PlayState.instance.cameraTwn = null;
						}});
					} else if(value1.toLowerCase() == 'flash') {
						if(!ClientPrefs.data.camEffects || !ClientPrefs.data.flashing) return;
						camGame.flash(FlxColor.WHITE, value2 != '' ? Std.parseFloat(value2) : 1);
					} else if(value1.toLowerCase() == 'breadbank') {
						if (value2.toLowerCase() == 'outro') camHUD.fade(FlxColor.BLACK, (Conductor.stepCrochet * 48) / 1000)
							else if(FlxG.save.data.seenIntro == null || !FlxG.save.data.seenIntro) {
								if(!ClientPrefs.data.lowQuality) {
									videoIntro.visible = true;
									videoIntro.resume();
									videoIntro.volume = 0;
								}
								overlay.visible = true;
								FlxTween.tween(overlay, { alpha: 0 }, 10, {startDelay: 2, onComplete: function(twn:FlxTween) { overlay.kill(); }});
							};
					} else if(value1.toLowerCase() == 'twinz') {
						FlxTween.tween(overlay, { alpha: 0 }, (Conductor.stepCrochet * 120) / 1000, { onComplete: function(twn:FlxTween) { overlay.kill(); }});
						if(!ClientPrefs.data.camEffects || ClientPrefs.data.lowQuality) return;
						PlayState.instance.isCameraOnForcedPos = true;
						camFollow.setPosition(900, -250);
						camGame.snapToTarget();
						FlxTween.tween(camFollow, { y: 500 }, (Conductor.stepCrochet * 240) / 1000, { ease: FlxEase.cubeOut, onComplete: function(twn:FlxTween) {
							PlayState.instance.isCameraOnForcedPos = false;
						}});
						PlayState.instance.cameraTwn = FlxTween.tween(camGame, {zoom: 0.4}, (Conductor.stepCrochet * 128) / 1000, { ease: FlxEase.cubeOut, onComplete: function(twn:FlxTween) {
							PlayState.instance.cameraTwn = null;
							currentCamZoom = 0.4;
						}});
					} else if(value1.toLowerCase() == 'fade in') {
						FlxTween.tween(overlay, { alpha: 0 }, value2 != '' ? Std.parseFloat(value2) : 1, { onComplete: function(twn:FlxTween) { overlay.kill(); }});
					} else if (value1.toLowerCase() == 'ttm begin') {
						if(!ClientPrefs.data.camEffects) return;
						PlayState.instance.isCameraOnForcedPos = true;
						camFollow.setPosition(-500, 0);
						camGame.snapToTarget();
						boyfriend.alpha = 0;
						gf.alpha = 0;
						dad.alpha = 0;
						redacted.alpha = 0;
						if(bgChars != null) bgChars.alpha = 0;
						if(fgChars != null) fgChars.alpha = 0;
						currentCamZoom = 1;
						camGame.fade(FlxColor.BLACK, (Conductor.stepCrochet * 12) / 1000, true, function() {
							var tmr = new FlxTimer().start((Conductor.stepCrochet * 60) / 1000, function(tmr:FlxTimer) {
								camGame.fade(FlxColor.BLACK, (Conductor.stepCrochet * 12) / 1000, false, function() {
									camGame.fade(FlxColor.BLACK, (Conductor.stepCrochet * 12) / 1000, true);
								});
							}, 1);
						});
						FlxTween.tween(camFollow, { x: 500 }, (Conductor.stepCrochet * 84) / 1000, { onComplete: function(twn:FlxTween) {
							camFollow.setPosition(900, -250);
							camGame.snapToTarget();
							boyfriend.alpha = 1;
							gf.alpha = 1;
							dad.alpha = 1;
							redacted.alpha = 1;
							if(bgChars != null) bgChars.alpha = 1;
							if(fgChars != null) fgChars.alpha = 1;
							FlxTween.tween(camFollow, { y: 500 }, (Conductor.stepCrochet * 44) / 1000, { ease: FlxEase.cubeOut, onComplete: function(twn:FlxTween) {
								PlayState.instance.isCameraOnForcedPos = false;
							}});
							PlayState.instance.cameraTwn = FlxTween.tween(camGame, {zoom: 0.4}, (Conductor.stepCrochet * 44) / 1000, { ease: FlxEase.cubeOut, onComplete: function(twn:FlxTween) {
								PlayState.instance.cameraTwn = null;
								currentCamZoom = 0.4;
							}});
						}});
					} else if(value1.toLowerCase() == '20racks') {
						if(!ClientPrefs.data.camEffects) return;
							PlayState.instance.cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 0.4, angle: (ClientPrefs.data.camEffects ? 4320 : 0)}, (Conductor.stepCrochet * 48) / 1000, {onComplete: function(twn:FlxTween) {
								FlxG.camera.angle = 0;
								PlayState.instance.cameraTwn = null;
								currentCamZoom = 0.4;
						}});
					} else {
						PlayState.instance.camFollow.x = 900;
						PlayState.instance.camFollow.y = 650;
						camGame.zoom = currentCamZoom = 0.6;
						PlayState.instance.isCameraOnForcedPos = true;
						if(PlayState.isStoryMode) {
							FlxTween.tween(overlayText, { alpha: 1 }, 0.7, {startDelay: 0.3});
							FlxTween.tween(overlayText, { alpha: 0 }, 0.7, { startDelay: 2.7, onComplete: function(twn:FlxTween) {
								overlayText.kill();
							} });
							FlxTween.tween(overlay, { alpha: 0 }, 1, { startDelay: 3.7, onComplete: function(twn:FlxTween) {
								overlay.kill();
							}  });
							FlxTween.tween(theStart, { alpha: 1 }, 1, { startDelay: 1.5, onComplete: function(twn:FlxTween) {
								FlxTween.tween(theStart, { alpha: 0 }, 1, { startDelay: 1.2, onComplete: function(twn:FlxTween) {
									PlayState.instance.isCameraOnForcedPos = false;
								}});
							} });
						} else FlxTween.tween(overlay, { alpha: 0 }, 4.1, {onComplete: function(twn:FlxTween) {
							overlay.kill();
							PlayState.instance.isCameraOnForcedPos = false;
						}  });
					}

				case 'Mako Moment':
					if(value1.toLowerCase() == 'mako gone') {
						FlxTween.tween(dad, { angle: 1080, alpha: 0 }, 1, {ease: FlxEase.quadIn});
						FlxTween.tween(dadGroup, { y: -330 }, 0.7, {ease: FlxEase.quadIn});
					} else {
						FlxTween.tween(makoArrive, {x: dadGroup.x + dad.x - 500}, 1, {ease: FlxEase.expoOut, onComplete: function(twn:FlxTween) {
							makoArrive.kill();
							dad.alpha = 1;
						}});
					}

				case 'BG Lights':
					if(!ClientPrefs.data.flashing || !ClientPrefs.data.camEffects) return;
					lightsUp = value1.toLowerCase() == 'on' ? true : false;
					filterOn = value1.toLowerCase() == 'on' ? true : false;
					if(!lightsUp) {
						camGame.bgColor = FlxColor.WHITE;
						bg.shader = null;
					} else {
						bg.shader = blur;
					}

				case 'Add Camera Zoom':
					if(lightsUp && ClientPrefs.data.camEffects) {
						camGame.bgColor = FlxColor.fromRGB(colorArray[lightInt][0], colorArray[lightInt][1], colorArray[lightInt][2]);
						if(lightInt == colorArray.length - 1) lightInt = 0 else lightInt++;
					}

				case 'Scanline Moment':
					if(ClientPrefs.data.lowQuality || !ClientPrefs.data.camEffects) return;
					//@:privateAccess
					if(FlxG.camera.filters == null) FlxG.camera.filters = [scanlines] else {
						//@:privateAccess
						if(!FlxG.camera.filters.contains(scanlines)) FlxG.camera.filters.push(scanlines) else FlxG.camera.filters.remove(scanlines);
					}
					FlxG.camera.filtersEnabled = true;

				case 'Play Video BG':
					if(ClientPrefs.data.lowQuality) return;
					video.revive();
					video.visible = true;
					video.bitmap.volume = 0;
					videoArray.shift();
					//var tmr = new FlxTimer().start(5, function(tmr:FlxTimer) {
						sys.thread.Thread.create(() -> { video.resume(); });
						if(Paths.formatToSongPath(PlayState.SONG.song) == 'feelin-torpid') {
							var timer = new FlxTimer().start((Conductor.stepCrochet * 260) / 1000, function(tmr:FlxTimer) {
								FlxTween.tween(video, { alpha: 0 }, Conductor.stepCrochet / 1000, { onComplete: function(twn:FlxTween) { video.stop(); }});
							}, 1);
						}
					//}, 1);
					

				case 'Change BG Color':
					if(!ClientPrefs.data.flashing) return;
					var input:Array<String> = [];
					if(value1 != '') input = value1.split(',');
					bg.color = (value1 != '') ? FlxColor.fromRGB(Std.parseInt(input[0].trim()), Std.parseInt(input[1].trim()), Std.parseInt(input[2].trim())) : FlxColor.BLACK;
					if(bg.color == FlxColor.WHITE) {
						camGame.bgColor = FlxColor.BLACK;
						if(gradient != null) gradient.alpha = 0;
					 } else if (bg.color == FlxColor.BLACK) {
						camGame.bgColor = FlxColor.WHITE;
						if(gradient != null) gradient.alpha = 1;
					 }

				case 'Pulse BG Color':
					if(!ClientPrefs.data.flashing) return;
					var original = bg.color;
					if(value1 == '') return;
					var newCol = value1.split(',');
					bg.color = FlxColor.fromRGB(Std.parseInt(newCol[0].trim()), Std.parseInt(newCol[1].trim()), Std.parseInt(newCol[2].trim()));
					FlxTween.color(bg, value2 != '' ? Std.parseFloat(value2) : Conductor.stepCrochet / 1000, bg.color, original);

				case 'Camera Snap To':
					if(!ClientPrefs.data.camEffects) return;
					switch(value1.toLowerCase())
					{
					case "bf":
						camFollow.setPosition(boyfriend.getMidpoint().x - bfOffsetMap[boyfriend.curCharacter], boyfriend.getMidpoint().y - 100);
						camFollow.x += boyfriend.cameraPosition[0] + boyfriendCameraOffset[0];
						camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];
						PlayState.instance.isCameraOnForcedPos = true;
						camGame.snapToTarget();
						return;
					case "bf2":
						if(boyfriend2 == null) return;
						camFollow.setPosition(boyfriend2.getMidpoint().x - bfOffsetMap[boyfriend2.curCharacter], boyfriend2.getMidpoint().y - 100);
						camFollow.x += boyfriend2.cameraPosition[0] + boyfriendCameraOffset[0];
						camFollow.y += boyfriend2.cameraPosition[1] + boyfriendCameraOffset[1];
						PlayState.instance.isCameraOnForcedPos = true;
						camGame.snapToTarget();
						return;
					case "gf":
						camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y - 100);
						camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
						camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
						PlayState.instance.isCameraOnForcedPos = true;
						camGame.snapToTarget();
						return;
					case "dad":
						if(dad.curCharacter == '3Redacted') {
							camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
							camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
							camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
						} else {
							camFollow.setPosition(dad.getMidpoint().x - 50, dad.getMidpoint().y - 50);
							camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
							camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
						}
						PlayState.instance.isCameraOnForcedPos = true;
						camGame.snapToTarget();
						return;
					default:
						if (value1 == '') {
							PlayState.instance.isCameraOnForcedPos = false;
							return;
						}
						var coords = value1.split(',');
						camFollow.setPosition(Std.parseFloat(coords[0].trim()), Std.parseFloat(coords[1].trim()));
						PlayState.instance.isCameraOnForcedPos = true;
						camGame.snapToTarget();
						return;
					}

				case 'Outline Shaders':
					if(ClientPrefs.data.lowQuality || !ClientPrefs.data.camEffects || !ClientPrefs.data.shaders) return;
					if(shadersOn) {
						boyfriend.shader = null;
						dad.shader = null;
						gf.shader = null;
						redacted.shader = null;
						hat.shader = null;

						if(bgChars != null) bgChars.visible = true;
						if(fgChars != null) fgChars.visible = true;

						bg.alpha = 1;
						
						shadersOn = false;
					} else {
						boyfriend.shader = outlineShaderBF;
						dad.shader = outlineShaderDad;
						gf.shader = outlineShaderGF;
						redacted.shader = outlineShaderRedacted;
						hat.shader = outlineShaderHat;

						if(bgChars != null) bgChars.visible = false;
						if(fgChars != null) fgChars.visible = false;

						bg.alpha = 0.4;
						
						shadersOn = true;
					}

				case "Dancing HUD":
					if(ClientPrefs.data.lowQuality || !ClientPrefs.data.camEffects) return;
					noteDance = !noteDance;

				case "Rotate Notes":
					if(ClientPrefs.data.lowQuality || !ClientPrefs.data.camEffects) return;
					for (note in opponentStrums.members) FlxTween.tween(note, {angle: 360}, (Conductor.stepCrochet * 4) / 1000, {startDelay: (0.05 * (opponentStrums.members.indexOf(note) + ((ClientPrefs.data.middleScroll && opponentStrums.members.indexOf(note) >= 2) ? 0.2 : 0))), ease: FlxEase.cubeInOut, onComplete: function(twn:FlxTween) { note.angle = 0; }});
					for (note in playerStrums.members) FlxTween.tween(note, {angle: 360}, (Conductor.stepCrochet * 4) / 1000, {startDelay: (0.05 * (playerStrums.members.indexOf(note) + (ClientPrefs.data.middleScroll ? 2 : 4))), ease: FlxEase.cubeInOut, onComplete: function(twn:FlxTween) { note.angle = 0; }});

				case 'Town BG Design':
					if(ClientPrefs.data.lowQuality) return;
						FlxTween.tween(backArea, {alpha: (value1 != '' ? 1 : 0)}, value2 != '' ? Std.parseFloat(value2) : 0.01, {onComplete: function(twn:FlxTween) {
							if(backArea.alpha == 0 && backGraphics.length != 0) {
								backArea.loadGraphic(Paths.image('stage/${backGraphics[0]}', 'shared'));
								backArea.setGraphicSize(Std.int(bg.width));
								backArea.updateHitbox();
							} else backGraphics.remove(value1);
						}});

				case 'SATURATE.':
					if(ClientPrefs.data.lowQuality || !ClientPrefs.data.camEffects) return;
					@:privateAccess
					if(saturationFilter == null || !FlxG.camera.filters.contains(saturationFilter)) {
						saturationFilter = new ColorMatrixFilter(saturation_filter_matrix(Std.parseInt(value1 != '' ? value1 : '2')));
						@:privateAccess
						if(FlxG.camera.filters == null) FlxG.camera.filters = [saturationFilter] else FlxG.camera.filters.push(saturationFilter);
					} else FlxG.camera.filters.remove(saturationFilter);

				case 'Parkour Begin':
					if(PlayState.isStoryMode) {
						bg.alpha = 1;
						redacted.alpha = 1;
						hat.alpha = 1;
					}

				case 'BG to Main':
					if(value1.toLowerCase() != 'left'
						&& value1.toLowerCase() != 'right'
						&& value1.toLowerCase() != 'gf'
						&& value1.toLowerCase() != 'boyfriend'
						&& (value1.toLowerCase() != 'boyfriend2' || (value2.toLowerCase() == 'boyfriend2' && boyfriend2 == null))
						&& value1.toLowerCase() != 'dad')
							return;
						if(ClientPrefs.data.lowQuality) return;
					switch(value1.trim().toLowerCase())
					{
						case 'left':
							if(bgBopLeft == null
								|| (bgBopLeft.alive && value2.trim().toLowerCase() == 'in')
								|| (!bgBopLeft.alive && value2.trim().toLowerCase() == 'out')) return;
							if(value2.toLowerCase() == 'in') {
								bgBopLeft.revive();
								FlxTween.tween(bgBopLeft, { x: bgBopLeft.x + 2000 }, 1.3, { ease: FlxEase.cubeOut, onComplete:function(twn:FlxTween) {
									leftBgBop = true;
								}});
							} else if(value2.toLowerCase() == 'out') {
								leftBgBop = false;
								bgBopLeft.animation.play('cue');
								FlxTween.tween(bgBopLeft, { x: bgBopLeft.x - 2000 }, 1.3, {ease: FlxEase.cubeIn, startDelay: 0.5, onComplete:function(twn:FlxTween) {
									bgBopLeft.kill();
								}});
							} else return;

						case 'right':
							if(bgBopRight == null
								|| (bgBopRight.alive && value2.trim().toLowerCase() == 'in')
								|| (!bgBopRight.alive && value2.trim().toLowerCase() == 'out')) return;
							if(value2.toLowerCase() == 'in') {
								bgBopRight.revive();
								FlxTween.tween(bgBopRight, { x: bgBopRight.x - 2000 }, 1.3, { ease: FlxEase.cubeOut, onComplete:function(twn:FlxTween) {
									rightBgBop = true;
								}});
							} else if(value2.toLowerCase() == 'out') {
								rightBgBop = false;
								bgBopRight.animation.play('cue');
								FlxTween.tween(bgBopRight, { x: bgBopRight.x + 2000 }, 1.3, {ease: FlxEase.cubeIn, startDelay: 0.5, onComplete:function(twn:FlxTween) {
									bgBopRight.kill();
								}});
							} else return;

						case 'gf':
							if(gf == null
								|| (gf.visible && value2.trim().toLowerCase() == 'in')
								|| (!gf.visible && value2.trim().toLowerCase() == 'out')) return;
							if(value2.toLowerCase() == 'in') {								
								gf.visible = true;
								FlxTween.tween(gf, { x: gf.x - 2000 }, 1.3, { ease: FlxEase.cubeOut});
							} else if(value2.toLowerCase() == 'out') {
								FlxTween.tween(gf, { x: gf.x + 2000 }, 1.3, {ease: FlxEase.cubeIn, startDelay: 0.5, onComplete:function(twn:FlxTween) {
									gf.visible = false;
								}});
							} else return;

						case 'dad':
							if(dad == null
								|| (dad.visible && value2.trim().toLowerCase() == 'in')
								|| (!dad.visible && value2.trim().toLowerCase() == 'out')) return;
							if(value2.toLowerCase() == 'in') {
								dad.visible = true;
								FlxTween.tween(dad, { x: dad.x - 2000 }, 1.3, { ease: FlxEase.cubeOut});
							} else if(value2.toLowerCase() == 'out') {
								FlxTween.tween(dad, { x: dad.x + 2000 }, 1.3, {ease: FlxEase.cubeIn, startDelay: 0.5, onComplete:function(twn:FlxTween) {
									dad.visible = false;
								}});
							} else return;

						case 'boyfriend':
							if(boyfriend == null
								|| (boyfriend.visible && value2.trim().toLowerCase() == 'in')
								|| (!boyfriend.visible && value2.trim().toLowerCase() == 'out')) return;
							if(value2.toLowerCase() == 'in') {
								boyfriend.visible = true;
								FlxTween.tween(boyfriend, { x: boyfriend.x - 2000 }, 1.3, { ease: FlxEase.cubeOut});
							} else if(value2.toLowerCase() == 'out') {
								FlxTween.tween(boyfriend, { x: boyfriend.x + 2000 }, 1.3, {ease: FlxEase.cubeIn, startDelay: 0.5, onComplete:function(twn:FlxTween) {
									boyfriend.visible = false;
								}});
							} else return;

						case 'boyfriend2':
							if(boyfriend2 == null
								|| (boyfriend2.visible && value2.trim().toLowerCase() == 'in')
								|| (!boyfriend2.visible && value2.trim().toLowerCase() == 'out')) return;
							if(value2.toLowerCase() == 'in') {
								boyfriend2.visible = true;
								FlxTween.tween(boyfriend2, { x: boyfriend2.x - 2000 }, 1.3, { ease: FlxEase.cubeOut});
							} else if(value2.toLowerCase() == 'out') {
								FlxTween.tween(boyfriend2, { x: boyfriend2.x + 2000 }, 1.3, {ease: FlxEase.cubeIn, startDelay: 0.5, onComplete:function(twn:FlxTween) {
									boyfriend2.visible = false;
								}});
							} else return;
					}
					
				case 'Spray Can':
					if(ClientPrefs.data.lowQuality || !ClientPrefs.data.camEffects) return;
					if(value1.toLowerCase() == 'burst') {
						sprayCan.shader = new ColorOverlay(FlxColor.WHITE, 1.0);
						sprayLine.visible = true;
						FlxTween.tween(sprayCan, { alpha: 0 }, 0.5, { onComplete:function(twn:FlxTween) { sprayCan.kill(); }});
					} else if(value1.toLowerCase() == 'dry') FlxTween.tween(sprayLine, { alpha: 0 }, 1, { onComplete: function(twn:FlxTween) { sprayLine.kill(); }})
						else {
							sprayCan.visible = true;
							sprayCan.animation.play('flyup');
						}

				case 'BunBeats':
					if(ClientPrefs.data.lowQuality) return;
					if(value1.toLowerCase() == 'bun') topText.visible = true else if(value1.toLowerCase() == 'beats') bottomText.visible = true else {
						FlxTween.tween(topText, {y: topText.y - 300 }, 0.9, { ease: FlxEase.circOut, onComplete: function(twn:FlxTween) {topText.kill();}});
						FlxTween.tween(bottomText, {y: bottomText.y + 300 }, 0.9, { ease: FlxEase.circOut, onComplete: function(twn:FlxTween) {bottomText.kill();}});
					}

				case 'CBP Gradient':
					theGradient.visible = !theGradient.visible;
		}
	}

	override function sectionHit() {
		if(sprayLine != null && sprayLine.visible) {
			var bfColor:FlxColor = FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]);
			var dadColor:FlxColor = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
			if(PlayState.SONG.notes[curSection].mustHitSection && sprayLine.color != bfColor) FlxTween.color(sprayLine, 0.7, sprayLine.color, bfColor) else if(!PlayState.SONG.notes[curSection].mustHitSection && sprayLine.color != dadColor) FlxTween.color(sprayLine, 0.7, sprayLine.color, dadColor);
		}
	}

	var theBopRate:Float = 1;
	override function beatHit()
		{
			if(curBeat % theBopRate == 0) {
				//sys.thread.Thread.create(function() {
					if(PlayState.SONG.gfVersion != "3Redacted") redacted.dance();
				//});

				//sys.thread.Thread.create(function() {
					if(bgChars != null) bgChars.animation.play('bg', true);
					if(fgChars != null) fgChars.animation.play('fg', true);
				//});

				if(noteDance) {
					camHUD.angle = left ? 3 : -3;
					camHUD.zoom += 0.1;
					FlxTween.tween(camHUD, {angle: 0, zoom: 1}, (Conductor.stepCrochet * 3) / 1000, {ease: FlxEase.cubeOut});
					left = !left;
				}

				//sys.thread.Thread.create(function() {
					if(bgBopLeft != null && leftBgBop) bgBopLeft.dance();
					if(bgBopRight != null && rightBgBop) bgBopRight.dance();
				//});

				if(theGradient != null && theGradient.visible) {
					theGradient.alpha = 0.75;
					FlxTween.tween(theGradient, {alpha: 0.3}, 0.2, {startDelay: 0.1});
				}
			}
		}

		static var RWGT = 0.3086;
		static var GWGT = 0.6094;
		static var BWGT = 0.0820;

		static public function saturation_filter_matrix(s: Float)
		{
			var b = (1 - s) * RWGT;
			var a = b + s;
			var d = (1 - s) * GWGT;
			var e = d + s;
			var g = (1 - s) * BWGT;
			var i = g + s;
		
			return [    a, d, g, 0, 0,
						b, e, g, 0, 0,
						b, d, i, 0, 0,
						0, 0, 0, 1, 0 ];
		}

	override function openSubState(SubState:FlxSubState) {
		video.pause();
		if(videoIntro != null) videoIntro.pause();
		if(Paths.formatToSongPath(PlayState.SONG.song) == 'feelin-torpid' && (boyfriend != null && boyfriend.curCharacter == '3DenPLAYER'))
			boyfriend.playAnim('dead');
	}

	override function onFocus() {
		if(video != null && paused) video.pause();
		if(videoIntro != null && paused) videoIntro.pause();
	}

	override function closeSubState() {
		video.resume();
		if(videoIntro != null) videoIntro.resume();
		if(Paths.formatToSongPath(PlayState.SONG.song) == 'feelin-torpid' && (boyfriend != null && boyfriend.curCharacter == '3DenPLAYER'))
			boyfriend.dance();
	}
}