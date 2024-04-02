package states;

import flixel.FlxSubState;

import flixel.effects.FlxFlicker;
import lime.app.Application;
import flixel.addons.transition.FlxTransitionableState;

class FlashingState extends MusicBeatState
{
	public static var leftState:Bool = false;

	var warnText:FlxText;
	override function create()
	{
		super.create();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		warnText = new FlxText(0, 0, FlxG.width,
			"Hey bro, before you get into the city's chaos, 3D contains some flashing lights and rapid camera movements that might not be favorable for people with epilepsy or motion sickness!\n\nIf that ain't your style, press ENTER to disable them now.\n\nOtherwise, press ESCAPE to keep them on and ignore this message.\n\nYou can also go to the options menu at any time to disable them in the Visuals/UI settings!",
			32);
		warnText.setFormat(Paths.font('vcr.ttf'), 40, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);
		add(warnText);
	}

	override function update(elapsed:Float)
	{
		if(!leftState) {
			var back:Bool = controls.BACK;
			if (controls.ACCEPT || back) {
				leftState = true;
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				if(!back) {
					ClientPrefs.data.flashing = false;
					ClientPrefs.data.camEffects = false;
					ClientPrefs.saveSettings();
					FlxG.sound.play(Paths.sound('confirmMenu'), 1 * ClientPrefs.data.soundVolume);
					FlxTween.tween(warnText, {alpha: 0}, 1, {
						onComplete: function (twn:FlxTween) {
							MusicBeatState.switchState(new TitleState());
						}
					});
				} else {
					ClientPrefs.data.flashing = true;
					ClientPrefs.data.camEffects = true;
					ClientPrefs.saveSettings();
					FlxG.sound.play(Paths.sound('confirmMenu'), 1 * ClientPrefs.data.soundVolume);
					FlxFlicker.flicker(warnText, 1, 0.1, false, true, function(flk:FlxFlicker) {
						new FlxTimer().start(0.5, function (tmr:FlxTimer) {
							MusicBeatState.switchState(new TitleState());
						});
					});
				}
			}
		}
		super.update(elapsed);
	}
}
