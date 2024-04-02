package substates;

import flixel.FlxBasic;
import lime.system.ThreadPool;
import backend.Highscore;
import flixel.addons.util.FlxAsyncLoop;

class LoadingSubstate extends MusicBeatSubstate {

	public static var instance:LoadingSubstate;
    public var excludeLoading:Array<Int>;
	var bg:FlxSprite;
	var loadingScreen:FlxSprite;
	var loadingText:FlxSprite;
	public var pool:ThreadPool;

	override public function new() {
		super();
	}

    override function create() {
        excludeLoading = [];

		instance = this;

        if(FlxG.save.data.weekCompleted == null || !FlxG.save.data.weekCompleted) 
			excludeLoading = [7, 8, 9, 10, 11, 12, 13, 14]
		else if(Highscore.getScore('citrus-bliss') == 0)
			excludeLoading = [10, 11, 12, 13, 14]
		else if (FlxG.save.data.cashBackUnlocked == null || !FlxG.save.data.cashBackUnlocked)
			excludeLoading = [11, 12, 13, 14];

		var daIntForLoading:Int = -1;
		if(Highscore.getScore(Paths.formatToSongPath(PlayState.SONG.song)) == 0) switch (Paths.formatToSongPath(PlayState.SONG.song))
		{
			case 'feelin-torpid':
				daIntForLoading = 4;

			case 'citrus-bliss':
				daIntForLoading = 10;

			case 'phrenic':
				daIntForLoading = 5;
		};
		if(daIntForLoading == -1) daIntForLoading = FlxG.random.int(0, 14, excludeLoading);

		bg = new FlxSprite().makeGraphic(Std.int(FlxG.camera.getViewRect().width), Std.int(FlxG.camera.getViewRect().height), FlxColor.BLACK);
		bg.screenCenter();
		add(bg);

        loadingScreen = new FlxSprite().loadGraphic(Paths.image('loading/loading-' + daIntForLoading));
		loadingScreen.screenCenter();
		add(loadingScreen);
		loadingScreen.cameras = [PlayState.instance.camHUD];
		if((FlxG.save.data.seenIntro == null || !FlxG.save.data.seenIntro) && Paths.formatToSongPath(PlayState.SONG.song) == 'breadbank') {
			loadingScreen.visible = false;
			PlayState.instance.skipCountdown = true;
		}

		loadingText = new FlxSprite(FlxG.camera.getViewRect().right, FlxG.camera.getViewRect().bottom).loadGraphic(Paths.image('loading/text'));
		loadingText.x -= loadingText.graphic.width;
		loadingText.y -= loadingText.graphic.height;
		add(loadingText);
		loadingText.cameras = [PlayState.instance.camHUD];

		persistentDraw = true;
		persistentUpdate = true;

        super.create();

		pool = new lime.system.ThreadPool(1, 8);
		pool.doWork.add(function(x) {
			PlayState.instance.camHUD.fade(FlxColor.BLACK, 1, true, function() { PlayState.instance.loadAll();});
		});
		pool.onComplete.add(function(result) {
			FlxTween.tween(bg, {alpha: 0}, 1);
			FlxTween.tween(loadingScreen, {alpha: 0}, 1);
			FlxTween.tween(loadingText, {alpha: 0}, 1, {onComplete: function(twn:FlxTween) {
				PlayState.instance.startCallback();
				PlayState.instance.curLoading = false;
				close();
			}});
		});
		pool.queue(0);

    }
}