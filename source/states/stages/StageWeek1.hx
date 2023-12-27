package states.stages;

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
	var bgChars:BGSprite;
	var fgChars:BGSprite;
	var hat:FlxSprite;
	var emptyDaHat:Array<String> = ['parkour', 'breadbank'];
	var noCrowd:Array<String> = ['parkour-freerunner-remix', 'twinz-euphoria-remix', 'moolah-throw-it-back-remix', 'breadbank'];
	var left:Bool = true;
	var noteDance:Bool = false;
	var backArea:FlxSprite;
	var backGraphics:Array<String> = [];

	//TTM specific
	var outlineShaderBF:OutlineShader;
	var outlineShaderDad:OutlineShader;
	var outlineShaderGF:OutlineShader;
	var outlineShaderRedacted:OutlineShader;
	var outlineShaderHat:OutlineShader;
	var shadersOn:Bool = false;

	//TTM/Phrenic specific
	var lineText:FlxText;
	var lineBox:FlxSprite;

	//Parkour specific
	var overlay:FlxSprite;
	var overlayText:FlxText;

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


	var colorArray:Array<Array<Int>> = [
		[40, 84, 203], [103, 154, 221], [187, 71, 107], [246, 140, 246], [118, 234, 154], [157, 20,	84], [175, 140, 186]
	];
	var lightsUp:Bool = false;
	var lightInt:Int;

	override function create()
	{

		if(Paths.formatToSongPath(PlayState.SONG.song) == 'ttm-true-to-musicality') {
			gradient = new FlxSprite(-1150, -800).loadGraphic(Paths.image('stage/gradients', 'shared'));
			gradient.scrollFactor.set(1, 1);
			gradient.setGraphicSize(Std.int(gradient.width * 1.45));
			gradient.updateHitbox();
			add(gradient);
		}

		bg = new FlxSprite(-1150, -800).loadGraphic(Paths.image('stage/background', 'shared'));
		bg.scrollFactor.set(1, 1);
		bg.setGraphicSize(Std.int(bg.width * 1.45));
		bg.updateHitbox();

		#if VIDEOS_ALLOWED
		video = new VideoHandler(0, -150);
		video.scrollFactor.set(0.9, 0.9);
		video.bitmap.volume = 0;
		add(video);
		video.active = false;
		#end

		add(bg);
		bg.color = FlxColor.BLACK;

		#if desktop
		if(ClientPrefs.data.camEffects) scanlines = new ShaderFilter(new Scanlines());
		#end

		if(!ClientPrefs.data.lowQuality) {
			blur = new BetterBlurShader(1.0);
			//blur.blur = 0.1;
		}

		if(PlayState.SONG.gfVersion != "3Redacted") {
			redacted = new Character(900, 200, "3Redacted");
			add(redacted);
		}

		defaultCamZoom = Paths.formatToSongPath(PlayState.SONG.song) == 'breadbank' ? 1 : 0.4;
		currentCamZoom = (Paths.formatToSongPath(PlayState.SONG.song) == 'breadbank' || (Paths.formatToSongPath(PlayState.SONG.song) == 'ttm-true-to-musicality' && ClientPrefs.data.camEffects)) ? 1 : 0.4;
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
					add(lineBox);

					lineText = new FlxText(25, FlxG.camera.getViewRect().bottom - 175, 0, 'michael mothaf--kin jackson');
					lineText.setFormat(Paths.font('Minecraftia-Regular.ttf'), 20, FlxColor.YELLOW, LEFT, OUTLINE, FlxColor.BLACK);
					lineText.visible = false;
					lineText.cameras = [camHUD];
					add(lineText);

				case 'Mako Moment':
					if(event.value1.toLowerCase() != 'mako gone' && !establishMako)
						{
							
							trace(gfGroup.x + " + " + gf.x + " then " + gfGroup.y + " + " + gf.y);
							var number:Float = FlxG.random.float(0, 1);
							makoArrive = new BGSprite(number > 0.83 ? "MAKOCULO" : "repent", gfGroup.x + gf.x - 2400, gfGroup.y + gf.y + 50);
							makoArrive.setGraphicSize(Std.int(gf.width));
							makoArrive.updateHitbox();
							addBehindDad(makoArrive);

							gf.alpha = 0;

							establishMako = true;
						}

				case 'Play Video BG':
					if(ClientPrefs.data.lowQuality) return;
					#if VIDEOS_ALLOWED
					video.active = true;
					video.setGraphicSize(Std.int(video.width * 2));
					video.updateHitbox();
					video.play(Paths.video('stages/' + event.value1));
					video.pause();
					video.bitmap.position = 0;
					videoInit = true;
					#end

				case 'Outline Shaders':
					if(ClientPrefs.data.lowQuality || !ClientPrefs.data.camEffects || !ClientPrefs.data.shaders) return;
					var helperColor = FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]);
					outlineShaderBF = new OutlineShader([helperColor.redFloat, helperColor.greenFloat, helperColor.blueFloat]);

					var helperColor = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
					outlineShaderDad = new OutlineShader([helperColor.redFloat, helperColor.greenFloat, helperColor.blueFloat]);

					var helperColor = FlxColor.fromRGB(gf.healthColorArray[0], gf.healthColorArray[1], gf.healthColorArray[2]);
					outlineShaderGF = new OutlineShader([helperColor.redFloat, helperColor.greenFloat, helperColor.blueFloat]);

					if(redacted != null) {
						var helperColor = FlxColor.fromRGB(redacted.healthColorArray[0], redacted.healthColorArray[1], redacted.healthColorArray[2]);
						outlineShaderRedacted = new OutlineShader([helperColor.redFloat, helperColor.greenFloat, helperColor.blueFloat]);
					}

					var helperColor = FlxColor.GREEN;
					outlineShaderHat = new OutlineShader([helperColor.redFloat, helperColor.greenFloat, helperColor.blueFloat]);

					case 'Town BG Design':
						if(ClientPrefs.data.lowQuality) return;
						backArea = new FlxSprite(-1150, -800).loadGraphic(Paths.image('stage/${event.value1}', 'shared'));
						backArea.scrollFactor.set(1, 1);
						backArea.setGraphicSize(Std.int(bg.width));
						backArea.updateHitbox();
						backArea.alpha = 0;
						insert(0, backArea);
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
							insert(members.indexOf(PlayState.instance.strumLineNotes), bottomShutter);
							bottomShutter.cameras = [camHUD];

							topShutter = new FlxSprite(camHUD.getViewRect().left - 150, camHUD.getViewRect().top - 350).makeGraphic(Std.int(camHUD.getViewRect().width + 300), 350, FlxColor.BLACK);
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
							insert(members.indexOf(PlayState.instance.strumLineNotes), topText);
							topText.cameras = [camHUD];

							bottomText = new FlxText(camHUD.getViewRect().right + 325, camHUD.getViewRect().bottom - 325, 0, 'ON!');
							bottomText.setFormat(Paths.font("aAnotherTag.otf"), 160, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
							bottomText.angle = -15;
							insert(members.indexOf(PlayState.instance.strumLineNotes), bottomText);
							bottomText.cameras = [camHUD];

							wordsEstablish = true;
						}
					}
					if(event.value1.toLowerCase() == "split screen") {
						if(ClientPrefs.data.lowQuality || !ClientPrefs.data.camEffects) return;
						bfCamPoint = new FlxObject(0, 0, 1, 1);
						bfCamPoint.setPosition(boyfriend.getMidpoint().x + 69 - boyfriend.cameraPosition[0] - PlayState.instance.boyfriendCameraOffset[0], boyfriend.getMidpoint().y - 131 + boyfriend.cameraPosition[1] + PlayState.instance.boyfriendCameraOffset[1]);
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
					} else if (event.value1.toLowerCase() == 'breadbank' && event.value2.toLowerCase() != 'outro' && (FlxG.save.data.seenIntro == null || !FlxG.save.data.seenIntro) && videoIntro == null) {
						overlay = new FlxSprite(FlxG.camera.getViewRect().left, FlxG.camera.getViewRect().top).makeGraphic(Std.int(FlxG.camera.getViewRect().width), Std.int(FlxG.camera.getViewRect().height), FlxColor.BLACK);
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
					if(ClientPrefs.data.lowQuality) return;
					if (!backGraphics.contains(event.value1)) Paths.image('stage/${event.value1}', 'shared');
					backGraphics.push(event.value1);
			}
		}

	override function createPost() {
		if(PlayState.SONG.gfVersion == "3Redacted") {
			gfGroup.x += 50;
			gfGroup.y += 100;
		} else if(boyfriend2 != null) {
			redacted.x = 550;
			redacted.y = 180;
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

		hat = new FlxSprite(700, 700).loadGraphic(Paths.image(emptyDaHat.contains(Paths.formatToSongPath(PlayState.SONG.song)) ? "emptyhat" : (PlayState.SONG.song.toLowerCase() == 'offwallet' ? "semifullhat" : "fullhat"), "shared"));
		hat.scrollFactor.set(1, 1);
		add(hat);


		if(PlayState.SONG.song.toLowerCase() == 'parkour')
			{
				overlay = new FlxSprite(FlxG.camera.getViewRect().left, FlxG.camera.getViewRect().top).makeGraphic(Std.int(FlxG.camera.getViewRect().width), Std.int(FlxG.camera.getViewRect().height), FlxColor.BLACK);
				add(overlay);
				overlay.cameras = [camHUD];

				overlayText = new FlxText(0, 0, 0, "Somewhere above\nthe buildings...");
				overlayText.setFormat(Paths.font('vcr.ttf'), 40, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
				overlayText.x = overlay.x + (overlay.width / 2) - (overlayText.width / 2);
				overlayText.y = overlay.y + (overlay.height / 2) - (overlayText.height / 2);
				overlayText.alpha = 0;
				add(overlayText);
				overlayText.cameras = [camHUD];
			} else if (!ClientPrefs.data.lowQuality && !noCrowd.contains(Paths.formatToSongPath(PlayState.SONG.song))) {
				bgChars = new BGSprite('stage/bgChars', -1400, -1025, 1, 1, ['bg']);
				bgChars.setGraphicSize(Std.int(bgChars.width * 2));
				bgChars.updateHitbox();
				addBehindGF(bgChars);
				if(PlayState.SONG.song.toLowerCase() != 'offwallet')
					{
						fgChars = new BGSprite('stage/fgChars', -1100, 725, 1, 1, ['fg']);
						fgChars.setGraphicSize(Std.int(fgChars.width * 2));
						fgChars.updateHitbox();
						add(fgChars);
						//fgChars.cameras = [camGame, splitCam];
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
							@:privateAccess
							if(FlxG.camera._filters == null) FlxG.camera.setFilters([saturationFilter]) else FlxG.camera._filters.push(saturationFilter);
							var timer = new FlxTimer().start((Conductor.stepCrochet * 4) / 1000, function(tmr:FlxTimer) {
								var timer = new FlxTimer().start((Conductor.stepCrochet * 4) / 1000, function(tmr:FlxTimer) {
									var theNewNumb = theNumb + 0.5;
									@:privateAccess
									FlxG.camera._filters.remove(saturationFilter);
									saturationFilter = new ColorMatrixFilter(saturation_filter_matrix(theNewNumb));
									@:privateAccess
									FlxG.camera._filters.push(saturationFilter);
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
											@:privateAccess
											FlxG.camera._filters.remove(saturationFilter);
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
								bfCamPoint.setPosition(bfCamPoint.x - 44, bfCamPoint.y + 36);
								//splitCam.zoom = currentCamZoom;
								PlayState.instance.camZooming = false;
								PlayState.instance.isCameraOnForcedPos = true;
								currentCamZoom = 1;
							}, 1);
						} else {
							bfCamPoint.setPosition(bfCamPoint.x + 44, bfCamPoint.y - 36);
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
					} else if(value1.toLowerCase() == 'flash') {
						if(!ClientPrefs.data.camEffects || !ClientPrefs.data.flashing) return;
						camGame.flash(FlxColor.WHITE, value2 != '' ? Std.parseFloat(value2) : 1);
					} else if(value1.toLowerCase() == 'breadbank') {
						if (value2.toLowerCase() == 'outro') camHUD.fade(FlxColor.BLACK, (Conductor.stepCrochet * 48) / 1000)
							else if(FlxG.save.data.seenIntro == null || !FlxG.save.data.seenIntro) {
								if(!ClientPrefs.data.lowQuality) {
									videoIntro.visible = true;
									videoIntro.resume();
								}
								overlay.visible = true;
								FlxTween.tween(overlay, { alpha: 0 }, 10, {startDelay: 2, onComplete: function(twn:FlxTween) { overlay.kill(); }});
							};
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
						PlayState.instance.camFollow.y = 500;
						PlayState.instance.isCameraOnForcedPos = true;
						camGame.zoom = 2;
						FlxTween.tween(overlayText, { alpha: 1 }, 0.7, {startDelay: 0.3});
						FlxTween.tween(overlayText, { alpha: 0 }, 0.7, { startDelay: 2.7, onComplete: function(twn:FlxTween) {
							overlayText.kill();
						} });
						FlxTween.tween(overlay, { alpha: 0 }, 0.7, { startDelay: 2, onComplete: function(twn:FlxTween) {
							overlay.kill();
						}  });
						FlxTween.tween(camGame, { zoom: 0.4 }, 3, { ease: FlxEase.cubeInOut, startDelay: 2, onComplete: function(twn:FlxTween) {
							PlayState.instance.isCameraOnForcedPos = false;
							//FlxTween.tween(PlayState.instance.camHUD, { alpha: 1 }, 0.7);
						} });
					}

				case 'Mako Moment':
					if(value1.toLowerCase() == 'mako gone') {
						FlxTween.tween(gf, { angle: 1080, alpha: 0 }, 1, {ease: FlxEase.quadIn});
						FlxTween.tween(gfGroup, { y: -330 }, 0.7, {ease: FlxEase.quadIn});
					} else {
						FlxTween.tween(makoArrive, {x: gfGroup.x + gf.x - 500}, 1, {ease: FlxEase.expoOut, onComplete: function(twn:FlxTween) {
							makoArrive.kill();
							gf.alpha = 1;
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
					@:privateAccess
					if(FlxG.camera._filters == null) {
						FlxG.camera.setFilters([scanlines]);				
					} else {
						@:privateAccess
						if(!FlxG.camera._filters.contains(scanlines)) FlxG.camera._filters.push(scanlines) else FlxG.camera._filters.remove(scanlines);
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
						camFollow.setPosition(boyfriend.getMidpoint().x - 500, boyfriend.getMidpoint().y - 100);
						camFollow.x += boyfriend.cameraPosition[0] + boyfriendCameraOffset[0];
						camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];
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
							if(backArea.alpha == 0) {
								backArea.loadGraphic(Paths.image('stage/${backGraphics[0]}', 'shared'));
								backArea.setGraphicSize(Std.int(bg.width));
								backArea.updateHitbox();
							} else backGraphics.remove(value1);
						}});

				case 'SATURATE.':
					if(ClientPrefs.data.lowQuality || !ClientPrefs.data.camEffects) return;
					@:privateAccess
					if(saturationFilter == null || !FlxG.camera._filters.contains(saturationFilter)) {
						saturationFilter = new ColorMatrixFilter(saturation_filter_matrix(Std.parseInt(value1 != '' ? value1 : '2')));
						@:privateAccess
						if(FlxG.camera._filters == null) FlxG.camera.setFilters([saturationFilter]) else FlxG.camera._filters.push(saturationFilter);
					} else FlxG.camera._filters.remove(saturationFilter);
		}
	}

	override function beatHit()
		{
			sys.thread.Thread.create(function() {
				if(PlayState.SONG.gfVersion != "3Redacted") redacted.dance();
				if(bgChars != null) bgChars.dance(true);
				if(fgChars != null) fgChars.dance(true);
			});

			if(noteDance) sys.thread.Thread.create(function() {
				camHUD.angle = left ? 3 : -3;
				camHUD.zoom += 0.1;
				FlxTween.tween(camHUD, {angle: 0, zoom: 1}, (Conductor.stepCrochet * 3) / 1000, {ease: FlxEase.cubeOut});
				left = !left;
			});
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
	}

	override function closeSubState() {
		video.resume();
		if(videoIntro != null) videoIntro.resume();
	}
}