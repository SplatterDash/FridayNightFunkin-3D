package options;

class GameplaySettingsSubState extends BaseOptionsMenu
{
	var theDescriptions:Array<String> = [
		'Feeling bored of the current FNF style? Choose a cool gameplay mode here!\nThis description will change as you change this setting!',
		'Perfections only! Get anything less and it\'s an instant death wish!',
		'Go for Shits only! If you get anything higher, you\'ll lose health - perfects are an instant kill!',
		'One of three items will spin like a record throughout the game: the individual arrows, the whole player strumline, or the whole gameplay/HUD camera.',
		'At random points, the game will cut the instrumental of the track. If you miss when the instrumental is muted, you lose half of a full bar\'s worth of health!',
		'The player notes will fade before making it to the strum line, making them harder to hit. Points will be increased if you can hit them!',
		'The player\'s side will be completely invisible. Points will be increased for hits!'
	];
	var curModesOption:Int = 0;

	public function new()
	{
		title = 'Gameplay Settings';
		rpcTitle = 'Gameplay Settings Menu'; //for Discord Rich Presence

		var option:Option = new Option('Music Volume',
			'Changes the volume of all in-game music.\nTo change the volume of both the music and SFX, use the master Flixel volume settings (hit - and +).',
			'musicVolume',
			'percent');
		option.changeValue = 0.05;
		option.onChange = onChangeVolume;
		addOption(option);

		var option:Option = new Option('SFX Volume',
			'Changes the volume of all in-game sound effects.\nTo change the volume of both the music and SFX, use the master Flixel volume settings (hit - and +).',
			'soundVolume',
			'percent');
		option.changeValue = 0.05;
		option.onChange = onChangeVolume;
		addOption(option);

		//I'd suggest using "Downscroll" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Downscroll', //Name
			'If checked, notes go Down instead of Up, simple enough.', //Description
			'downScroll', //Save data variable name
			'bool'); //Variable type
		addOption(option);

		var option:Option = new Option('Middlescroll',
			'If checked, your notes get centered.',
			'middleScroll',
			'bool');
		addOption(option);

		var option:Option = new Option('Opponent Notes',
			'If unchecked, opponent notes get hidden.',
			'opponentStrums',
			'bool');
		addOption(option);

		var option:Option = new Option('Ghost Tapping',
			"If checked, you won't get misses from pressing keys\nwhile there are no notes able to be hit.",
			'ghostTapping',
			'bool');
		addOption(option);
		
		var option:Option = new Option('Auto Pause',
			"If checked, the game automatically pauses if the screen isn't on focus.",
			'autoPause',
			'bool');
		addOption(option);
		option.onChange = onChangeAutoPause;

		var option:Option = new Option('Disable Reset Button',
			"If checked, pressing Reset won't do anything.",
			'noReset',
			'bool');
		addOption(option);

		var option:Option = new Option('Hitsound Volume',
			'Funny notes does \"Tick!\" when you hit them."',
			'hitsoundVolume',
			'percent');
		addOption(option);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.onChange = onChangeHitsoundVolume;

		var option:Option = new Option('Rating Offset',
			'Changes how late/early you have to hit for a "Sick!"\nHigher values mean you have to hit later.',
			'ratingOffset',
			'int');
		option.displayFormat = '%vms';
		option.scrollSpeed = 20;
		option.minValue = -30;
		option.maxValue = 30;
		addOption(option);

		var option:Option = new Option('Sick! Hit Window',
			'Changes the amount of time you have\nfor hitting a "Sick!" in milliseconds.',
			'sickWindow',
			'int');
		option.displayFormat = '%vms';
		option.scrollSpeed = 15;
		option.minValue = 15;
		option.maxValue = 45;
		addOption(option);

		var option:Option = new Option('Good Hit Window',
			'Changes the amount of time you have\nfor hitting a "Good" in milliseconds.',
			'goodWindow',
			'int');
		option.displayFormat = '%vms';
		option.scrollSpeed = 30;
		option.minValue = 15;
		option.maxValue = 90;
		addOption(option);

		var option:Option = new Option('Bad Hit Window',
			'Changes the amount of time you have\nfor hitting a "Bad" in milliseconds.',
			'badWindow',
			'int');
		option.displayFormat = '%vms';
		option.scrollSpeed = 60;
		option.minValue = 15;
		option.maxValue = 135;
		addOption(option);

		var option:Option = new Option('Safe Frames',
			'Changes how many frames you have for\nhitting a note earlier or late.',
			'safeFrames',
			'float');
		option.scrollSpeed = 5;
		option.minValue = 2;
		option.maxValue = 10;
		option.changeValue = 0.1;
		addOption(option);

		var option:Option = new Option('Gameplay Modes',
			'Feeling bored of the current FNF style? Choose a cool gameplay mode here!\nThis description will change as you change this setting!',
			'gameplaySpice',
			'string',
			['None', 'Perfection Run', 'Oops! All Shit!', 'Record Player', 'Karaoke Night', 'Ghost Notes', 'Blind Side']);
		curModesOption = option.curOption;
		/**option.onChange = function() {
			theDescriptions[curModesOption];
		}**/
		addOption(option);

		super();
	}

	function onChangeHitsoundVolume()
	{
		FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.data.hitsoundVolume * ClientPrefs.data.soundVolume);
	}

	function onChangeAutoPause()
	{
		FlxG.autoPause = ClientPrefs.data.autoPause;
	}

	function onChangeVolume()
	{
		FlxG.sound.defaultMusicGroup.volume = ClientPrefs.data.musicVolume;
		FlxG.sound.defaultSoundGroup.volume = ClientPrefs.data.soundVolume;
		FlxG.sound.play(Paths.sound('scrollMenu'), 1 * ClientPrefs.data.soundVolume);
	}
}