package options;

import lime.system.System;
import lime.app.Application;

class EraseSaveSubState extends MusicBeatSubstate
{
    var bg:FlxSprite;
	var alphabetArray:Array<Alphabet> = [];
    var yesText:Alphabet;
	var noText:Alphabet;
    var onYes:Bool = false;

    public function new()
        {    
            super();
            FlxG.mouse.enabled = FlxG.mouse.visible = ClientPrefs.data.mouseOnMenu;
    
            bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
            bg.alpha = 0;
            bg.scrollFactor.set();
            add(bg);
    
            var text:Alphabet = new Alphabet(0, 90, "You are about to reset\nyour save file.", true);
            text.screenCenter(X);
            text.alignment = CENTERED;
            text.x += (FlxG.camera.getViewRect().width / 2) - 150;
            alphabetArray.push(text);
            text.alpha = 0;
            add(text);
            var text:Alphabet = new Alphabet(0, text.y + 180, "Are you sure?", true);
            text.alignment = LEFT;
            text.scale.set(1.1, 1.1);
            text.screenCenter(X);
            alphabetArray.push(text);
            text.alpha = 0;
            add(text);
            var text:Alphabet = new Alphabet(0, text.y + 180, "This will reset all unlocks and scores.\nThis cannot be undone!", true);
            text.scaleX = 0.6;
            text.scaleY = 0.6;
            text.alignment = CENTERED;
            text.screenCenter(X);
            text.x += (FlxG.camera.getViewRect().width / 2) - 150;
            alphabetArray.push(text);
            text.alpha = 0;
            add(text);
    
            yesText = new Alphabet(0, text.y + 150, 'Yes', true);
            yesText.screenCenter(X);
            yesText.x -= 200;
            add(yesText);
            noText = new Alphabet(0, text.y + 150, 'No', true);
            noText.screenCenter(X);
            noText.x += 200;
            add(noText);
            updateOptions();
        }

        override function update(elapsed:Float)
            {
                bg.alpha += elapsed * 1.5;
                if(bg.alpha > 0.6) bg.alpha = 0.6;
        
                for (i in 0...alphabetArray.length) {
                    var spr = alphabetArray[i];
                    spr.alpha += elapsed * 2.5;
                }
        
                if(controls.UI_LEFT_P || controls.UI_RIGHT_P) {
                    FlxG.sound.play(Paths.sound('scrollMenu'), 1 * ClientPrefs.data.soundVolume);
                    onYes = !onYes;
                    updateOptions();
                }
                if(FlxG.mouse.enabled && ((FlxG.mouse.overlaps(yesText) && !onYes) || (FlxG.mouse.overlaps(noText) && onYes))) {
                    onYes = FlxG.mouse.overlaps(yesText) ? true : false;
                    updateOptions();
                }
                if(controls.BACK) {
                    FlxG.sound.play(Paths.sound('cancelMenu'), 1 * ClientPrefs.data.soundVolume);
                    close();
                } else if(controls.ACCEPT || (FlxG.mouse.enabled && FlxG.mouse.justPressed)) {
                    if(onYes) {
                        FlxG.sound.play(Paths.sound('confirmMenu'), 1 * ClientPrefs.data.soundVolume);
                        FlxG.save.erase();
                        lime.system.System.exit(0);
                    }
                    FlxG.sound.play(Paths.sound('cancelMenu'), 1 * ClientPrefs.data.soundVolume);
                    close();
                }
                super.update(elapsed);
            }

        function updateOptions() {
            var scales:Array<Float> = [0.75, 1];
            var alphas:Array<Float> = [0.6, 1.25];
            var confirmInt:Int = onYes ? 1 : 0;
    
            yesText.alpha = alphas[confirmInt];
            yesText.scale.set(scales[confirmInt], scales[confirmInt]);
            noText.alpha = alphas[1 - confirmInt];
            noText.scale.set(scales[1 - confirmInt], scales[1 - confirmInt]);
        }
}