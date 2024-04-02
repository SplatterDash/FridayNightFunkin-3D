package states;

class JustVideoState extends MusicBeatState
{
    var daVid:String;

    public function new(daVid:String) {
        this.daVid = daVid;
        super();
    }
    
    override function create()
    {
        Main.nowPlaying = true;
        FlxG.addChildBelowMouse(Main.video);
        Main.video.visible = true;
        Main.video.volume = 1;
        Main.video.play(Paths.video(daVid));
        super.create();
    }

    override function update(elapsed:Float) {
        if(!Main.nowPlaying) {
            if(daVid == '20131015_235534') {
                FlxG.save.data.viewedTrailer = true;
                FlxG.save.flush();

                FreeplayState.finalMessage = true;
            }
            FlxG.mouse.enabled = FlxG.mouse.visible = ClientPrefs.data.mouseOnMenu;
            FlxG.sound.playMusic(Paths.music('3dmainmenu'), 1 * ClientPrefs.data.musicVolume);
            MusicBeatState.switchState(new FreeplayState());
        }

        super.update(elapsed);
    }
}