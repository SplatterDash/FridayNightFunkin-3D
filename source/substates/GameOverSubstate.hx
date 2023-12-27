package substates;

import states.MainMenuState;

import objects.Character;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;

import states.FreeplayState;

class GameOverSubstate extends MusicBeatSubstate
{
	public var deathSprite:FlxSprite;
	var camFollow:FlxObject;
	var updateCamera:Bool = false;
	var playingDeathSound:Bool = false;
	var appear:Bool = false;
	var deathChar:FlxSprite;
	var doSecret:Bool = false;

	var stageSuffix:String = "";

	public static var characterName:String = '3dami';
	public static var deathSoundName:String = 'dami_loss_sfx';
	public static var delayAnimation:Float = 3.073;
	public static var lineLocation:String = '3dami';

	public static var instance:GameOverSubstate;
	var deathSound:FlxSound;
	var deathLine:FlxSound;

	public static function resetVariables() {
		characterName = '3dami';
		deathSoundName = 'dami_loss_sfx';
		delayAnimation = 2.573;
		lineLocation = '3dami';

		var _song = PlayState.SONG;
		if(_song != null)
		{
			if(_song.gameOverChar != null && _song.gameOverChar.trim().length > 0) characterName = _song.gameOverChar;
			if(_song.gameOverSound != null && _song.gameOverSound.trim().length > 0) deathSoundName = _song.gameOverSound;
			if(_song.delayAnimation != null && _song.delayAnimation > 0) delayAnimation = _song.delayAnimation;
			if(_song.gameOverEnd != null && _song.gameOverEnd.trim().length > 0) lineLocation = _song.gameOverEnd;
		}
	}

	override function create()
	{
		instance = this;
		PlayState.instance.callOnScripts('onGameOverStart', []);

		super.create();
	}

	public function new(x:Float, y:Float, camX:Float, camY:Float)
	{
		super();

		PlayState.instance.setOnScripts('inGameOver', true);

		Conductor.songPosition = 0;

		/**boyfriend = new Character(x, y, characterName, true);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		add(boyfriend);**/

		var exclude:Array<Int> = [];
		if(characterName == '3den') {
			if(FlxG.save.data.denSecrets == null) {
				FlxG.save.data.denSecrets = 'first';
				FlxG.save.flush();
			}
			exclude = (FlxG.save.data.denSecrets == 'first' ? [3, 4] : (FlxG.save.data.denSecrets == 'second' ? [2, 4] : [2, 3]));
		}

		//FlxG.sound.play()
		deathLine = new FlxSound().loadEmbedded(Paths.sound(lineLocation.toLowerCase() + '/gameover-' + FlxG.random.int(1, 4, exclude)), false, true);
		//deathLine.group = null;
		if(deathLine.length >= 60000) {
			doSecret = true;
			deathLine.onComplete = function() {
				FlxG.sound.music.volume = 1;
				FlxG.camera.zoom = 0.8;
				FlxG.camera.y += 150;
				var curSecret:String = FlxG.save.data.denSecrets;
				FlxG.save.data.denSecrets = (curSecret == 'third' ? 'first' : (curSecret == 'first' ? 'second' : 'third'));
				FlxG.save.flush();
				endBullshit();
			}
		} else deathLine.onComplete = function () {
			if(!isEnding)
				{
					FlxG.sound.music.fadeIn(4, 0.2, 1);
				}
		};
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;
		FlxG.camera.bgColor = FlxColor.BLACK;
		FlxG.camera.zoom = 0.8;

		//boyfriend.playAnim('firstDeath');

		deathSprite = new FlxSprite(0, 0);
		deathSprite.frames = Paths.getSparrowAtlas('retry', 'shared');
		deathSprite.animation.addByPrefix('firstDeath', 'retry', 24, false);
		deathSprite.animation.addByIndices('deathLoop', 'retry', [7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22], "", 24, true);
		deathSprite.scrollFactor.set();
		deathSprite.setGraphicSize(Std.int(deathSprite.width * 0.8));
		deathSprite.updateHitbox();
		deathSprite.screenCenter(X);
		add(deathSprite);
		deathSprite.visible = false;
		deathSprite.color = FlxColor.fromRGB(PlayState.instance.boyfriend.healthColorArray[0], PlayState.instance.boyfriend.healthColorArray[1], PlayState.instance.boyfriend.healthColorArray[2]);

		deathChar = new FlxSprite(0, 0);
		deathChar.frames = Paths.getSparrowAtlas('gameover', 'shared');
		deathChar.animation.addByPrefix('deathBeat', characterName.toLowerCase() + '-death', 12, false);
		deathChar.animation.addByPrefix('getUp', characterName.toLowerCase() + '-revive', 12, false);
		deathChar.scrollFactor.set();
		deathChar.setGraphicSize(Std.int(deathChar.width * 0.35));
		deathChar.updateHitbox();
		deathChar.screenCenter(X);
		add(deathChar);
		deathChar.visible = false;
		deathChar.animation.play('deathBeat');

		deathSound = FlxG.sound.play(Paths.sound(deathSoundName), 1 * ClientPrefs.data.soundVolume);
	}

	public var startedDeath:Bool = false;
	var isFollowingAlready:Bool = false;
	public var canExit:Bool = true;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		PlayState.instance.callOnScripts('onUpdate', [elapsed]);

		@:privateAccess
		//trace(deathLine._time);
		if(doSecret && (deathLine.time >= 60000)) {
			canExit = false;
			FlxTween.tween(FlxG.camera, { y: FlxG.camera.y - 150}, 2, { ease: FlxEase.cubeInOut });
		}

		if (controls.ACCEPT && canExit)
		{
			endBullshit();
		}

		if (controls.BACK && canExit)
		{
			#if desktop DiscordClient.resetClientID(); #end
			if(deathSound.playing) deathSound.stop();
			FlxG.sound.music.stop();
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;
			PlayState.chartingMode = false;
			PlayState.loadedFull = false;

			if (PlayState.isStoryMode)
				MusicBeatState.switchState(new MainMenuState());
			else
				MusicBeatState.switchState(new FreeplayState());

			FlxG.sound.playMusic(Paths.music('3dmainmenu'), 0.7 * ClientPrefs.data.musicVolume);
			PlayState.instance.callOnScripts('onGameOverConfirm', [false]);
		}

		if(deathSound.time >= (delayAnimation * 1000) && !appear) {
			appear = true;
			var timer = new FlxTimer().start(1, function(tmr:FlxTimer) { deathSprite.visible = true; deathSprite.animation.play('firstDeath'); }, 1);
			deathChar.visible = true;
		}

		if (!canExit && !isEnding) {
			if(deathSprite.alpha > 0) deathSprite.alpha -= 0.001;
			if(FlxG.sound.music.volume > 0) FlxG.sound.music.volume -= 0.0001;
			FlxG.camera.zoom += 0.0000001;
		}
		
		if (deathSprite.animation.curAnim != null && appear)
		{
			if (deathSprite.animation.curAnim.name == 'firstDeath' && deathSprite.animation.curAnim.finished && startedDeath)
				deathSprite.animation.play('deathLoop');

			if(deathSprite.animation.curAnim.name == 'firstDeath')
			{
				/**if(boyfriend.animation.curAnim.curFrame >= 12 && !isFollowingAlready)
				{
					FlxG.camera.follow(camFollow, LOCKON, 0);
					updateCamera = true;
					isFollowingAlready = true;
				}**/

				if (deathSprite.animation.curAnim.finished && !playingDeathSound)
				{
					startedDeath = true;
					playingDeathSound = true;
					coolStartDeath(0.2);

					deathLine.play(false, 0.0);
				}
			}
		}
		
		if(updateCamera) FlxG.camera.followLerp = FlxMath.bound(elapsed * 0.6 / (FlxG.updateFramerate / 60), 0, 1);
		else FlxG.camera.followLerp = 0;

		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
		PlayState.instance.callOnScripts('onUpdatePost', [elapsed]);
	}

	var isEnding:Bool = false;

	function coolStartDeath(?volume:Float = 1):Void
	{
		Conductor.set_bpm(80);
		FlxG.sound.playMusic(Paths.music('deaththeme3d'), volume * ClientPrefs.data.musicVolume);
		deathChar.animation.play('deathBeat');
	}

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			//boyfriend.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			if(deathSound.playing) deathSound.stop();
			if(deathLine.playing) deathLine.stop();
			FlxG.sound.music.volume = 1 * ClientPrefs.data.musicVolume;
			FlxG.sound.play(Paths.music('gameOverEnd'), 1 * ClientPrefs.data.soundVolume);
			deathSprite.color = FlxColor.WHITE;
			deathChar.animation.play('getUp');
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					FlxG.camera.bgColor = FlxColor.WHITE;
					Conductor.set_bpm(PlayState.SONG.bpm);
					MusicBeatState.resetState();
				});
			});
			PlayState.instance.callOnScripts('onGameOverConfirm', [true]);
		}
	}

	override function beatHit()
		{
			if(!isEnding && (deathChar.animation.curAnim != null && deathChar.animation.curAnim.name == 'deathBeat')) deathChar.animation.play('deathBeat');
		}

	override function destroy()
	{
		instance = null;
		super.destroy();
	}
}
