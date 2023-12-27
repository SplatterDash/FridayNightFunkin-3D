package states;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.effects.FlxFlicker;

import backend.Highscore;
import backend.Song;

class IntroState extends MusicBeatState
{
    var text:FlxText;

    override function create()
        {
        super.create();

        var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

        var textBack:FlxSprite = new FlxSprite(FlxG.camera.getViewRect().left, FlxG.camera.getViewRect().top + 50)
        .makeGraphic(Std.int(FlxG.camera.getViewRect().width), Std.int(FlxG.camera.getViewRect().height - 100), FlxColor.BLACK);
        textBack.alpha = 0.5;
        add(textBack);

        text = new FlxText(0, 0, FlxG.camera.getViewRect().width,
        'Sup bro, welcome to 3D!\n\nThis is inspired by the style of 17 Bucks, created by a group of friends just wanting to have some fun.\nThere is only one difficulty in this mod, so try to beat everything as best as you can!\nAnd don\'t forget - there\'s a bunch of easter eggs to find too. For example, try typing \'${states.TitleState.easterEggKeys[FlxG.random.int(0, states.TitleState.easterEggKeys.length - 1)].toLowerCase()}\' on the title screen!\nBut for now, let\'s go through a tutorial to show you just how we do it here at 3D.\n\nPress ENTER to continue!');
        text.setFormat("VCR OSD Mono", 30, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        text.screenCenter();
        add(text);
        }

        override function update(elapsed:Float) {
            if(controls.ACCEPT || FlxG.keys.justPressed.ENTER) {
                FlxG.sound.play(Paths.sound('confirmMenu'), 1 * ClientPrefs.data.soundVolume);
                if(ClientPrefs.data.flashing) FlxFlicker.flicker(text, 1, 0.1, false, true, function(flk:FlxFlicker) {
                    new FlxTimer().start(0.5, function (tmr:FlxTimer) {
                       startTutorial();
                    });
                }) else FlxTween.tween(text, { alpha: 0 }, 1, { onComplete: function(twn:FlxTween) { startTutorial(); }});
            }
        }

        private function startTutorial() {
            persistentUpdate = false;
            var songLowercase:String = Paths.formatToSongPath('breadbank');
            var poop:String = Highscore.formatSong('breadbank');
            PlayState.SONG = Song.loadFromJson(poop, songLowercase);
            PlayState.isStoryMode = false;
            PlayState.theFirstTutorial = true;
            FlxG.sound.music.stop();
            LoadingState.loadAndSwitchState(new PlayState());
        }
}