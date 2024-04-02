package states;

import flixel.sound.FlxSound;
import backend.Paths;

class CashBackCutsceneState extends MusicBeatState
{
    var bg:FlxSprite;
    var casette:FlxSprite;
    var sound:FlxSound;
    var silhouette:FlxSprite;
    override public function create()
        {
            bgColor = FlxColor.BLACK;

            bg = new FlxSprite().makeGraphic(Std.int(FlxG.camera.getViewRect().width), Std.int(FlxG.camera.getViewRect().height), FlxColor.fromRGB(20, 20, 20));
            bg.screenCenter();
            bg.active = false;
            bg.alpha = 0;
            add(bg);

            silhouette = new FlxSprite().loadGraphic(Paths.image("cashback_silhouettes", "shared"));
            silhouette.screenCenter();
            silhouette.active = false;
            silhouette.alpha = 0;
            add(silhouette);

            casette = new FlxSprite().loadGraphic(Paths.image("casette", "shared"));
            casette.screenCenter();
            casette.active = false;
            casette.alpha = 0;
            add(casette);

            sound = new FlxSound().loadEmbedded(Paths.sound("cashbackpack_cutscene", "shared"));
            sound.volume *= FlxG.sound.volume * ClientPrefs.data.soundVolume;
            sound.onComplete = function() {
                states.FreeplayState.unlockCash = true;
                FlxG.save.data.cashBackUnlocked = true;
                MusicBeatState.switchState(new states.FreeplayState());
                FlxG.sound.playMusic(Paths.music('3dmainmenu'), 1 * ClientPrefs.data.musicVolume);
            }
            FlxG.sound.list.add(sound);

            super.create();

            sound.play();
            var timer = new FlxTimer().start(0.5, function(tmr:FlxTimer) {
                casette.active = true;
                FlxTween.tween(casette, {alpha: 1}, 5);
            });
        }

    var startFadeIn:Bool = false;
    var startBgChange:Bool = false;

    override public function update(elapsed:Float) {
        super.update(elapsed);
        if(casette.active) {
            casette.scale.add(0.0001, 0.0001);
            casette.screenCenter();
        }

        if(sound.time >= 30297 && !startFadeIn) {
            startFadeIn = true;
            silhouette.active = true;
            FlxTween.tween(silhouette, { alpha: 1 }, 8.833);
        }

        if(sound.time >= 39122 && !startBgChange) {
            startBgChange = true;
            bg.active = true;
            FlxTween.tween(bg, { alpha: 1 }, 1.280);
        }

        if(sound.time >= 40402) {
            casette.alpha = 0;
            casette.active = false;

            silhouette.alpha = 0;
            silhouette.active = false;

            bg.alpha = 0;
            bg.active = false;
        }
    }
}