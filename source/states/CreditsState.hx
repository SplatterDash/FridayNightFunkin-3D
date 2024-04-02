package states;

import objects.AttachedSprite;

class CreditsState extends MusicBeatState
{
	var curSelected:Int = -1;

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var iconArray:Array<AttachedSprite> = [];
	private var creditsStuff:Array<Array<String>> = [];

	var bg:FlxSprite;
	var descText:FlxText;
	var intendedColor:FlxColor;
	var colorTween:FlxTween;
	var descBox:AttachedSprite;

	var offsetThing:Float = -75;

	override function create()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		FlxG.mouse.enabled = FlxG.mouse.visible = ClientPrefs.data.mouseOnMenu;

		persistentUpdate = true;
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();
		
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		var defaultList:Array<Array<String>> = [ //Name - Icon name - Description - Link - BG Color
			['3D Team'],
			['DamiNation',          'dami',             'Lead Organizer, Lead Artist, Animator, Voice Actor (3Sylvester, 3Jitterbud)',                                                            'https://twitter.com/DamiNation2020',       '2853cb'],
			['ItsAudity',           'audity',           'Co-Organizer, Lead Animator, UI Artist, Musician (BreadBank, OffWallet, 20Racks, Citrus Bliss, TwinZ, Phrenic), Voice Actor (3Josie)',   'https://twitter.com/ItsAudity',            'bb476b'],
			['No7E',                'no7e',             'Co-Organizer, Loading Screen Artist, Musician (Parkour, TTM [True To Musicality], Feelin\' Torpid)',                                     'https://twitter.com/memory_dancer',        '679add'],
			['Redacted',            'redacted',         'UI Art, Voice Acting (3Redacted)',                                                                                                       'https://twitter.com/ohheyredacted',        'af8cba'],
			['Aletomento',          'aleto',            'UI/In-Game Background Artist',                                                                                                           'https://twitter.com/aletomento',           'ffa500'],
			['MegaFreedom1274',     'megaf',            'Additional Animation, Musician (FORREAL, Game Over [1-Dimensional Remix])',                                                              'https://twitter.com/MegaFreedom1274',      '9d1454'],
			['Noer',                'noer',             'Charting (BreadBank, TTM (True To Musicality), 20Racks, Feelin\' Torpid, Cirtus Bliss, Twin-Z, Twin-Z (Euphoria Remix)), has his money', 'https://twitter.com/ThisIsNoerlol',        '3F9369'],
			['N21',                 'nitro',            'Charting (Parkour, OffWallet, FORREAL, Phrenic, FORREAL (Overnighter Remix), Parkour (FREERUNNER Remix))',                               'https://twitter.com/tswnitro',             '32a852'],
			['SplatterDash',        'splatter',         'Coding, Musician (Gettin\' Freaky (3D Remix), Cash Back Pack, Tea Time (SUGAH Remix), Boombox Blues)',                                   'https://splatterdash.newgrounds.com/',     '006aff'],
			['AsuraTM0',            'asura',            'Editor for the release trailer and trailer for Vs D[GETOUTSAVEUSGETOUTSAVEUS]',                                                          'https://twitter.com/AsuraTM0',             'ffa500'],
			['aar0nPKT',            'aaron',            'Jitterbud chrom',                                                                                                                        'https://twitter.com/AaromKT',              '80ffea'],
			['Mako',                'mako',             'hi guys he\'s mako',                                                                                                                     'https://twitter.com/helloitsmako',         'f692f6'],
			['isketchiguess',       'sketch',           'Created Mako\'s 17Bucks design!',                                                                                                        'https://twitter.com/isketchisuppose',      'fffa75'],
			['LazyGoobster',        'goobster',         'Thank you for allowing us to make the 17 bucks fit of your OC! (and for making Note a happy boi)',                                       'https://twitter.com/LazyGoobster',         'ffffff'],
			['Neon Shikaro',        'neon',             'Beta testing',                                                                                                                           'https://twitter.com/NeonShikaro',          '5ee8d3'],
			['ItsAlibi',            'alibi',            'Beta testing',                                                                                                                           'https://www.drpepper.com/s/',              'b907fa'],
			['KayDoodles',          'kay',              'Fiyoure moral support',                                                                                                                  'https://twitter.com/KayDoodles_',          '89CFF0'],
			['17 Bucks',            'peacock',          'The aesthetic inspiration for this mod, also known as the place where they pea cocks',                                                   'https://gamebanana.com/mods/461390',       'ffffff'],
			[''],
			['Psych Engine Team'],
			['Shadow Mario',		'shadowmario',		'Main Programmer of Psych Engine',								'https://twitter.com/Shadow_Mario_',	'444444'],
			['Riveren',				'riveren',			'Main Artist/Animator of Psych Engine',							'https://twitter.com/riverennn',		'B42F71'],
			[''],
			['Former Engine Members'],
			['shubs',				'shubs',			'Ex-Programmer of Psych Engine',								'https://twitter.com/yoshubs',			'5E99DF'],
			['bb-panzu',			'bb',				'Ex-Programmer of Psych Engine',								'https://twitter.com/bbsub3',			'3E813A'],
			[''],
			['Engine Contributors'],
			['iFlicky',				'flicky',			'Composer of Psync and Tea Time\nMade the Dialogue Sounds',		'https://twitter.com/flicky_i',			'9E29CF'],
			['SqirraRNG',			'sqirra',			'Crash Handler and Base code for\nChart Editor\'s Waveform',	'https://twitter.com/gedehari',			'E1843A'],
			['EliteMasterEric',		'mastereric',		'Runtime Shaders support',										'https://twitter.com/EliteMasterEric',	'FFBD40'],
			['PolybiusProxy',		'proxy',			'.MP4 Video Loader Library (hxCodec)',							'https://twitter.com/polybiusproxy',	'DCD294'],
			['KadeDev',				'kade',				'Fixed some cool stuff on Chart Editor\nand other PRs',			'https://twitter.com/kade0912',			'64A250'],
			['Keoiki',				'keoiki',			'Note Splash Animations and Latin Alphabet',					'https://twitter.com/Keoiki_',			'D2D2D2'],
			['superpowers04',		'superpowers04',	'LUA JIT Fork',													'https://twitter.com/superpowers04',	'B957ED'],
			['Smokey',				'smokey',			'Sprite Atlas Support',											'https://twitter.com/Smokey_5_',		'483D92'],
			[''],
			["Funkin' Crew"],
			['ninjamuffin99',		'ninjamuffin99',	"Programmer of Friday Night Funkin'",							'https://twitter.com/ninja_muffin99',	'CF2D2D'],
			['PhantomArcade',		'phantomarcade',	"Animator of Friday Night Funkin'",								'https://twitter.com/PhantomArcade3K',	'FADC45'],
			['evilsk8r',			'evilsk8r',			"Artist of Friday Night Funkin'",								'https://twitter.com/evilsk8r',			'5ABD4B'],
			['kawaisprite',			'kawaisprite',		"Composer of Friday Night Funkin'",								'https://twitter.com/kawaisprite',		'378FC7']
		];
		// aaaaand psych slipped the default list in the middle of the create function instead of making it a local var because...?
		
		for(i in defaultList) {
			creditsStuff.push(i);
		}
	
		for (i in 0...creditsStuff.length)
		{
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(FlxG.width / 2, 300, creditsStuff[i][0], !isSelectable);
			optionText.isMenuItem = true;
			optionText.targetY = i;
			optionText.changeX = false;
			optionText.snapToPosition();
			grpOptions.add(optionText);

			if(isSelectable) {

				var str:String = 'credits/missing_icon';
				if (Paths.image('credits/' + creditsStuff[i][1]) != null) str = 'credits/' + creditsStuff[i][1];
				var icon:AttachedSprite = new AttachedSprite(str);
				icon.xAdd = optionText.width + 10;
				icon.sprTracker = optionText;
	
				// using a FlxGroup is too much fuss!
				iconArray.push(icon);
				add(icon);

				if(curSelected == -1) curSelected = i;
			}
			else optionText.alignment = CENTERED;
		}
		
		descBox = new AttachedSprite();
		descBox.makeGraphic(1, 1, FlxColor.BLACK);
		descBox.xAdd = -10;
		descBox.yAdd = -10;
		descBox.alphaMult = 0.6;
		descBox.alpha = 0.6;
		add(descBox);

		descText = new FlxText(50, FlxG.height + offsetThing - 25, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER/*, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK*/);
		descText.scrollFactor.set();
		//descText.borderSize = 2.4;
		descBox.sprTracker = descText;
		add(descText);

		bg.color = CoolUtil.colorFromString(creditsStuff[curSelected][4]);
		intendedColor = bg.color;
		changeSelection();
		super.create();
	}

	var quitting:Bool = false;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if(!quitting)
		{
			if(creditsStuff.length > 1)
			{
				var shiftMult:Int = 1;
				if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

				var upP = controls.UI_UP_P;
				var downP = controls.UI_DOWN_P;

				if (upP)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
				}
				if (downP)
				{
					changeSelection(shiftMult);
					holdTime = 0;
				}

				if(FlxG.mouse.enabled && FlxG.mouse.wheel != 0) changeSelection(-FlxG.mouse.wheel * shiftMult);

				if(controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					}
				}
			}

			if((controls.ACCEPT || (FlxG.mouse.enabled && FlxG.mouse.justPressed)) && (creditsStuff[curSelected][3] == null || creditsStuff[curSelected][3].length > 4)) {
				CoolUtil.browserLoad(creditsStuff[curSelected][3]);
			}
			if (controls.BACK)
			{
				if(colorTween != null) {
					colorTween.cancel();
				}
				FlxG.sound.play(Paths.sound('cancelMenu'), 1 * ClientPrefs.data.soundVolume);
				MusicBeatState.switchState(new MainMenuState());
				quitting = true;
			}
		}
		
		for (item in grpOptions.members)
		{
			if(!item.bold)
			{
				var lerpVal:Float = FlxMath.bound(elapsed * 12, 0, 1);
				if(item.targetY == 0)
				{
					var lastX:Float = item.x;
					item.screenCenter(X);
					item.x = FlxMath.lerp(lastX, item.x - 70, lerpVal);
				}
				else
				{
					item.x = FlxMath.lerp(item.x, 200 + -40 * Math.abs(item.targetY), lerpVal);
				}
			}
		}
		super.update(elapsed);
	}

	var moveTween:FlxTween = null;
	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4 * ClientPrefs.data.soundVolume);
		do {
			curSelected += change;
			if (curSelected < 0)
				curSelected = creditsStuff.length - 1;
			if (curSelected >= creditsStuff.length)
				curSelected = 0;
		} while(unselectableCheck(curSelected));

		var newColor:FlxColor = CoolUtil.colorFromString(creditsStuff[curSelected][4]);
		//trace('The BG color is: $newColor');
		if(newColor != intendedColor) {
			if(colorTween != null) {
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
		}

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			if(!unselectableCheck(bullShit-1)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
				}
			}
		}

		descText.text = creditsStuff[curSelected][2];
		descText.y = FlxG.height - descText.height + offsetThing - 60;

		if(moveTween != null) moveTween.cancel();
		moveTween = FlxTween.tween(descText, {y : descText.y + 75}, 0.25, {ease: FlxEase.sineOut});

		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();
	}

	private function unselectableCheck(num:Int):Bool {
		return creditsStuff[num].length <= 1;
	}
}