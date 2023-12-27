package substates;

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
	var loadingFunny:FlxText;

	var loadingFunnies:Array<String> = [
		'3Redacted, canonically, is addicted to prescription drugs.',
		'We don\'t talk about the ice cream incident.',
		'A lot of the 3D atmosphere is inspired by Jet Set Radio Future and Bomb Rush Cyberfunk - two of Note\'s favorite games!',
		'If SplatterDash had his way, a character named Doomi would be in 3D. Too bad Splatter only made the code for this mod.',
		'we ya',
		'If you wear the Turtle Pals Tapes Official Condom (patent pending), could you say that the Hulk is ready to smash?',
		'Everyone who worked on this is a portion of another mod team, which is working on Vs Dami!',
		'If you disrespect 3DinkleSpink, 3Derek will find you.',
		'This mod is not compatible with 3D glasses. Not yet, at least.',
		'Talk to Noer. See if he will show you his money.',
		'We\'re no strangers to love. You know the rules, and so do I. I\'ve no commitments that I\'m thinking of, you wouldn\'t get this from any other guy.',
		'Note is a massive simp for Hideki Naganuma. It\'s why a lot of his songs take a lot of inspiration from songs of Naganuma!',
		'That was just soy sauce. This is bromine!',
		'3Mega dies 3 days after 3D takes place from human spontaneous combustion.',
		'3Redacted has a 20-foot Ball Python named Cornball.',
		'3DinkleSpink dies immedaitely after 3D takes place.',
		'I swear we legitimately started this before the Game Awards (we still <3 you JSR)'
	];

	override public function new() {
		super();
	}

    override function create() {
        excludeLoading = [];

		instance = this;

        if(FlxG.save.data.weekCompleted == null || !FlxG.save.data.weekCompleted || Highscore.getScore('moolah') == 0) {
			for (i in 5...8) excludeLoading.push(i);
		} else if (Highscore.getScore('phrenic') == 0) excludeLoading.push(8);

		var daIntForLoading:Int = -1;
		if(Highscore.getScore(Paths.formatToSongPath(PlayState.SONG.song)) == 0) switch (Paths.formatToSongPath(PlayState.SONG.song))
		{
			case 'feelin-torpid':
				daIntForLoading = 4;

			case 'phrenic':
				daIntForLoading = 8;
		};
		if(daIntForLoading == -1) daIntForLoading = FlxG.random.int(0, 8, excludeLoading);

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

		loadingText = new FlxSprite(0, FlxG.camera.getViewRect().bottom - 350).loadGraphic(Paths.image('loading/text'));
		loadingText.setGraphicSize(Std.int(loadingText.width * 0.5));
		loadingText.screenCenter(X);
		add(loadingText);
		loadingText.cameras = [PlayState.instance.camHUD];

		loadingFunny = new FlxText(0, FlxG.camera.getViewRect().bottom, FlxG.camera.getViewRect().width, loadingScreen.visible ? loadingFunnies[FlxG.random.int(0, loadingFunnies.length - 1)] : "Welcome to the streets, kid..." );
		loadingFunny.setFormat(Paths.font("street soul.ttf"), 48, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		loadingFunny.screenCenter(X);
		loadingFunny.y -= loadingFunny.height;
		add(loadingFunny);
		loadingFunny.cameras = [PlayState.instance.camHUD];

		//loadingStuff.cameras = [camHUD];

		persistentDraw = true;
		persistentUpdate = true;

        super.create();

		pool = new lime.system.ThreadPool(1, 5);
		pool.doWork.add(function(x) {
			PlayState.instance.camHUD.fade(FlxColor.BLACK, 1, true, function() { PlayState.instance.loadAll();});
		});
		pool.onComplete.add(function(result) {
			FlxTween.tween(bg, {alpha: 0}, 1);
			FlxTween.tween(loadingScreen, {alpha: 0}, 1);
			FlxTween.tween(loadingFunny, {alpha: 0}, 1);
			FlxTween.tween(loadingText, {alpha: 0}, 1, {onComplete: function(twn:FlxTween) {
				PlayState.instance.startCallback();
				PlayState.instance.curLoading = false;
				close();
			}});
		});
		pool.queue(0);

    }
}