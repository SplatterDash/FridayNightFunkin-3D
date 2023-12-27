package states;

class IllegalCopyState extends MusicBeatState {
    var onText:Bool = false;
    override function create() {
        super.create();

        FlxG.sound.music.stop();
        FlxG.sound.play(backend.Paths.sound('illegalcopy'), 1.5);
        var tmr = new flixel.util.FlxTimer().start(5, function(tmr:FlxTimer) {
            var text = new FlxText(0, 0, FlxG.width,
                "It seems that you are playing a non-official copy of FNF:3D.\n\nYou are being redirected for your safety, both to prevent you from getting hacked and to prevent the host program from potentially profitting off of downloadable freeware.\n\nPress ENTER to be redirected to the official FNF:3D GameBanana page.",
                40);
            text.setFormat(backend.Paths.font('vcr.ttf'), 40, FlxColor.WHITE, CENTER);
            text.screenCenter();
            add(text);
            onText = true;
        });
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if(onText && FlxG.keys.justPressed.ENTER) {
            FlxG.openURL("https://gamebanana.com/mods/309789");
            lime.system.System.exit(0);
        }
    }
}