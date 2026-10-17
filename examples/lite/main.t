#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-dialogue.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>

yard: Room 'Training Yard'
    desc { return yardSay('A trainer offers a short sparring bout. Try status, hike, rest, treat wounds, or spar. During a bout: attack, defend, recover, or stop. Undo and logical saves work across every activity.'); }
;
yardTrainer: Actor 'trainer' location(yard) vocab = 'trainer';
yardHero: RpgLiteProfile actor = player dx = 12 ht = 12 pointBudget = 100;
yardCoach: RpgLiteProfile actor = yardTrainer dx = 11 ht = 12 iq = 13 pointBudget = 150;
yardBrawling: RpgLiteSkill id = 'brawling' attribute = rpgDX difficulty = 0;
yardAid: RpgLiteSkill id = 'first-aid' attribute = rpgIQ difficulty = 0 defaultPenalty = -4 techLevel = 3;
yardHeroTraining: RpgTraining skill = yardBrawling points = 4;
yardCoachTraining: RpgTraining skill = yardBrawling points = 2;
yardMedicalTraining: RpgTraining skill = yardAid points = 4;
modify yardHero skills = [yardHeroTraining];
modify yardCoach skills = [yardCoachTraining, yardMedicalTraining];
yardPlayer: RpgLiteFighter profile = yardHero;
yardOpponent: RpgLiteFighter profile = yardCoach;
yardBattle: RpgLiteBattle fighters = [yardPlayer, yardOpponent];
yardCare: RpgLiteTreatment patient = yardHero healer = yardCoach skill = yardAid;
yardWalk: RpgLiteJourney profile = yardHero kind = 'hiking';
yardAward: RpgMilestone id = 'yard.practice' points = 2;
yardReceipt: RpgAward profile = yardHero milestone = yardAward;
yardSetup: InitObject
    execute()
    {
        yardPlayer.weapon = rpgLiteMakeWeapon('punch',10); yardPlayer.weapon.ready = true;
        yardOpponent.weapon = rpgLiteMakeWeapon('punch',10); yardOpponent.weapon.ready = true;
        yardHero.equipment = [yardPlayer.weapon]; yardCoach.equipment = [yardOpponent.weapon];
        rpgLiteValidateCharacter(yardHero); rpgLiteValidateCharacter(yardCoach); return nil;
    }
;
yardSay(text) { event('survey.text'); eventValue(text); "<<text>>\n"; return nil; }
yardStatus()
{
    event('rpg.body'); eventValue(1); eventValue(player);
    eventValue(yardHero.dead ? 'dead' : yardHero.unconscious ? 'unconscious' : yardHero.stunned ? 'stunned' : 'active');
    eventValue(yardHero.hp()); eventValue(yardHero.maxHP); eventValue(yardHero.fp()); eventValue(yardHero.maxEnergy); eventValue(yardHero.shock);
    return nil;
}
yardStop()
{
    yardBattle.finish(); yardHero.developmentOpen = true;
    rpgPublishProgress(rpgAwardMilestone(yardHero,yardAward));
    return yardSay('The trainer stops the bout. Rest or accept treatment; practice points are awarded only once.');
}
yardDo(code)
{
    if (code == 700) return yardStatus();
    if (code == 705 && yardBattle.active) { yardStop(); return yardStatus(); }
    if (yardBattle.active)
    {
        if (!holds([702,703,704],code)) return yardSay('Finish the bout before starting another activity.');
        local request = new RpgLiteManeuver(); request.target = yardOpponent;
        request.kind = code == 702 ? 'attack' : code == 703 ? 'all-out-defense' : 'nothing';
        request.option = code == 703 ? 'dodge' : nil;
        local result = yardBattle.step(yardPlayer,request);
        if (result.status == 'blocked') { yardSay(result.reason); return yardStatus(); }
        yardSay(result.outcome);
        if (yardHero.hp() <= 5 || yardCoach.hp() <= 5 || yardHero.unconscious || yardCoach.unconscious)
        { yardStop(); return yardStatus(); }
        if (yardBattle.current() == yardOpponent)
        {
            local response = new RpgLiteManeuver(); response.target = yardPlayer;
            response.kind = yardCoach.stunned ? 'nothing' : 'attack';
            local reply = yardBattle.step(yardOpponent,response); yardSay(reply.outcome);
        }
        if (yardBattle.seconds >= 12 || yardHero.hp() <= 5 || yardCoach.hp() <= 5
            || yardHero.unconscious || yardCoach.unconscious) yardStop();
    }
    else if (code == 701)
    {
        if (yardBattle.order.length() > 0) return yardSay('The practice bout is over; this trainer offers one per session.');
        if (yardHero.hp() <= 5 || yardHero.fp() <= 0) return yardSay('Recover before sparring.');
        yardBattle.begin(); yardSay('The bout begins. You act first.');
    }
    else if (code == 706)
    { yardWalk.advance(3600); yardSay('You hike for an hour.'); }
    else if (code == 707)
    { rpgLiteRest(yardHero,600,true,true,nil,true); yardSay('Ten quiet minutes pass.'); }
    else if (code == 708)
    { yardCare.advance(1860); yardSay('The trainer completes a first-aid session.'); }
    else if (code == 709)
    { rpgLiteRest(yardHero,86400,true,true,true,true); yardSay('A full day of food, water and rest passes.'); }
    else return yardSay('Start a bout with spar, or try hike, rest and treat wounds.');
    return yardStatus();
}
class YardAction: Action code = 700 exec(context) { return yardDo(self.code); };
yardStatusAction: YardAction code = 700;
yardSparAction: YardAction code = 701;
yardAttackAction: YardAction code = 702;
yardDefendAction: YardAction code = 703;
yardRecoverAction: YardAction code = 704;
yardStopAction: YardAction code = 705;
yardHikeAction: YardAction code = 706;
yardRestAction: YardAction code = 707;
yardTreatAction: YardAction code = 708;
yardDayAction: YardAction code = 709;
yardStatusVerb: Verb code = 700 action = yardStatusAction label = 'yard-status';
yardSparVerb: Verb code = 701 action = yardSparAction label = 'yard-spar';
yardAttackVerb: Verb code = 702 action = yardAttackAction label = 'yard-attack';
yardDefendVerb: Verb code = 703 action = yardDefendAction label = 'yard-defend';
yardRecoverVerb: Verb code = 704 action = yardRecoverAction label = 'yard-recover';
yardStopVerb: Verb code = 705 action = yardStopAction label = 'yard-stop';
yardHikeVerb: Verb code = 706 action = yardHikeAction label = 'yard-hike';
yardRestVerb: Verb code = 707 action = yardRestAction label = 'yard-rest';
yardTreatVerb: Verb code = 708 action = yardTreatAction label = 'yard-treat';
yardDayVerb: Verb code = 709 action = yardDayAction label = 'yard-day';
grammar command(yardStatusCmd): 'status' : Command action = yardStatusAction;
grammar command(yardSparCmd): 'spar' : Command action = yardSparAction;
grammar command(yardAttackCmd): 'attack' : Command action = yardAttackAction;
grammar command(yardDefendCmd): 'defend' : Command action = yardDefendAction;
grammar command(yardRecoverCmd): 'recover' : Command action = yardRecoverAction;
grammar command(yardStopCmd): 'stop' : Command action = yardStopAction;
grammar command(yardHikeCmd): 'hike' : Command action = yardHikeAction;
grammar command(yardRestCmd): 'rest' : Command action = yardRestAction;
grammar command(yardTreatCmd): 'treat' 'wounds' : Command action = yardTreatAction;
grammar command(yardDayCmd): 'rest' 'day' : Command action = yardDayAction;
modify gameMain initialRoom = yard;
startup() { rpgRandom.seed(27); return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args) { if (verb == 700) return yardStatus(); return vhylAct(verb,args); }
