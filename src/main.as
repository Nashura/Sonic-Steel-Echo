package {
    import flash.display.DisplayObject;
    import flash.display.MovieClip;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.geom.Rectangle;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.filters.GlowFilter;
    import flash.utils.getTimer;

    public class BattleDemo extends MovieClip {
        private static const MAX_HP:int = 100;
        private static const CHOICE:int = 50;
        private static const SONIC_ATTACK:int = 51;
        private static const SONIC_HIT:int = 58;
        private static const SONIC_RETURN:int = 110;
        private static const KNUX_ATTACK:int = 111;
        private static const KNUX_HIT:int = 122;
        private static const SONIC_LOSES:int = 190;
        private static const KNUX_LOSES:int = 273;
        private static const KNUX_END:int = 359;
        private static const ATTACK_HIT_AREA:Rectangle = new Rectangle(552.85, 653.05, 240, 240);
        private static const POPUP_MS:int = 850;

        private var attackControl:Sprite;
        private var sonicHP:int = MAX_HP;
        private var knuxHP:int = MAX_HP;
        private var sonicDefeated:Boolean;
        private var damageText:TextField;
        private var popupStart:int;
        private var popupY:Number;

        public function BattleDemo() {
            trace("[BattleDemo v3] loaded. Timeline: " + totalFrames + " frames.");
            addFrameScript(CHOICE - 1, waitForAttack,
                           SONIC_HIT - 1, damageKnux,
                           SONIC_RETURN - 1, finishSonicTurn,
                           KNUX_HIT - 1, damageSonic,
                           SONIC_LOSES - 1, finishKnuxTurn,
                           KNUX_LOSES - 1, stopIfSonicLost,
                           KNUX_END - 1, stop);
            addEventListener(Event.EXIT_FRAME, updateDisplay);
        }

        private function waitForAttack():void {
            stop();
        }

        private function enableAttack():void {
            if (attackControl == null) {
                attackControl = new Sprite();
                attackControl.graphics.beginFill(0, 0);
                attackControl.graphics.drawRect(0, 0, ATTACK_HIT_AREA.width, ATTACK_HIT_AREA.height);
                attackControl.graphics.endFill();
                attackControl.buttonMode = true;
                attackControl.mouseChildren = false;
                attackControl.addEventListener(MouseEvent.CLICK, attack);
            }

            var button:DisplayObject = findNamedChild(this, "attackButton");
            var bounds:Rectangle = button == null ? ATTACK_HIT_AREA : button.getBounds(this);
            attackControl.x = bounds.x;
            attackControl.y = bounds.y;
            attackControl.width = bounds.width;
            attackControl.height = bounds.height;
            addChild(attackControl);
            trace("[BattleDemo v3] Attack ready on frame " + currentFrame);
        }

        private function attack(event:MouseEvent):void {
            removeChild(attackControl);
            trace("[BattleDemo v3] Attack clicked; playing from frame " + SONIC_ATTACK);
            gotoAndPlay(SONIC_ATTACK);
        }

        private function findNamedChild(container:DisplayObjectContainer, name:String):DisplayObject {
            var direct:DisplayObject = container.getChildByName(name);
            if (direct != null) {
                return direct;
            }

            for (var index:int = 0; index < container.numChildren; index++) {
                var child:DisplayObjectContainer = container.getChildAt(index) as DisplayObjectContainer;
                if (child != null) {
                    var match:DisplayObject = findNamedChild(child, name);
                    if (match != null) {
                        return match;
                    }
                }
            }
            return null;
        }

        private function damageKnux():void {
            var loss:int = Math.min(knuxHP, rollDamage(24));
            knuxHP -= loss;
            trace("[BattleDemo v3] Knuckles -" + loss + " HP; remaining: " + knuxHP);
            showDamage(loss, 2915, 820);
        }

        private function damageSonic():void {
            var loss:int = Math.min(sonicHP, rollDamage(23));
            sonicHP -= loss;
            trace("[BattleDemo v3] Sonic -" + loss + " HP; remaining: " + sonicHP);
            showDamage(loss, 900, 820);
        }

        private function rollDamage(baseDamage:int):int {
            return Math.round(baseDamage * (0.75 + Math.random() * 0.5));
        }

        private function finishSonicTurn():void {
            if (knuxHP == 0) {
                gotoAndPlay(KNUX_LOSES);
            } else {
                gotoAndPlay(KNUX_ATTACK);
            }
        }

        private function finishKnuxTurn():void {
            if (sonicHP == 0) {
                sonicDefeated = true;
                return;
            }
            gotoAndStop(CHOICE);
        }

        private function stopIfSonicLost():void {
            if (sonicDefeated) {
                stop();
            }
        }

        private function healthFrame(hp:int):int {
            var percent:Number = hp * 100 / MAX_HP;
            if (percent > 75) return 1;
            if (percent > 50) return 2;
            if (percent > 25) return 3;
            if (percent > 10) return 4;
            return percent > 0 ? 5 : 6;
        }

        private function updateIcon(name:String, hp:int):void {
            var icon:MovieClip = findNamedChild(this, name) as MovieClip;
            if (icon != null && icon.currentFrame != healthFrame(hp)) {
                icon.gotoAndStop(healthFrame(hp));
            } else if (icon != null) {
                icon.stop();
            }
        }

        private function showDamage(loss:int, xPosition:Number, yPosition:Number):void {
            if (damageText == null) {
                damageText = new TextField();
                damageText.autoSize = TextFieldAutoSize.LEFT;
                damageText.defaultTextFormat = new TextFormat("_sans", 110, 0xFF5555, true);
                damageText.filters = [new GlowFilter(0x000000, 1, 10, 10, 6)];
                damageText.selectable = false;
                damageText.mouseEnabled = false;
            }
            damageText.text = "-" + loss;
            damageText.y = yPosition;
            damageText.alpha = 1;
            damageText.x = xPosition - damageText.width / 2;
            popupY = yPosition;
            popupStart = getTimer();
            addChild(damageText);
        }

        private function updateDisplay(event:Event):void {
            if (currentFrame == CHOICE && (attackControl == null || attackControl.parent != this)) {
                enableAttack();
            }
            updateIcon("sonicHealthIcon", sonicHP);
            updateIcon("knuxHealthIcon", knuxHP);
            if (damageText == null || damageText.parent != this) {
                return;
            }
            var progress:Number = (getTimer() - popupStart) / POPUP_MS;
            if (progress >= 1) {
                removeChild(damageText);
                return;
            }
            setChildIndex(damageText, numChildren - 1);
            damageText.y = popupY - 100 * progress;
            damageText.alpha = 1 - progress * progress;
        }
    }
}
