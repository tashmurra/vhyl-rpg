#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-traits.t>
#include <vhyl-rpg-expanded-fright.t>
frightRoom: Room 'Crypt';
frightRules: RpgExpandedRules;
frightHero: RpgExpandedProfile actor = player rules = frightRules pointBudget = 1000 disadvantageLimit = 500;
frightSituation: RpgFrightSituation;
frightInput: object code = 0 args = [];
frightLast: object result = nil panic = nil valid = nil reason = nil;

/* Add an approved trait: negative points make a disadvantage with optional self-control. */
frightTrait(id, level, points, rating)
{
    local trait = points < 0 ? new RpgExpandedDisadvantage() : new RpgExpandedTrait();
    trait.id = id; trait.level = level; trait.points = points; trait.approved = true;
    if (points < 0 && rating != 0) trait.selfControlRating = rating;
    return trait;
}

class FrightTestAction: Action
    exec(context)
    {
        local a = frightInput.args; local code = frightInput.code; local s = frightSituation;
        if (code == 1) rpgRandom.seed(a[2]);
        else if (code == 2)
        { frightHero.iq = a[2]; frightHero.ht = a[3]; frightHero.hpAdjustment = a[4]; frightHero.willAdjustment = a[5]; }
        else if (code == 3) frightHero.traits = frightHero.traits + [frightTrait(a[2], a[3], a[4], a[5])];
        else if (code == 4)
        {
            local bodies = [nil, 'prepared', 'peaceful', 'violent', 'mutilated', 'bones'];
            local views = ['present', 'distant', 'remote', 'dream'];
            s.monster = a[2]; s.count = a[3]; s.body = bodies[a[4] + 1]; s.mutilation = a[5];
            s.dependent = a[6] != 0; s.inCombat = a[7] != 0; s.touched = a[8] != 0;
            s.viewing = views[a[9] + 1]; s.isolated = a[10] != 0; s.dark = a[11] != 0; s.alone = a[12] != 0;
            s.experienced = a[13] != 0; s.briefing = a[14]; s.physicalDanger = a[15] != 0;
            s.charging = a[16] != 0; s.swornFoe = a[17] != 0; s.strange = a[18] != 0;
            s.modifier = a[19]; s.threat = a[20] == '' ? nil : a[20];
        }
        else if (code == 5) frightLast.result = rpgFrightCheck(frightHero, s);
        else if (code == 6) frightLast.result = rpgFrightApply(frightHero, a[2], a[3]);
        else if (code == 7) { rpgSpendTime(a[2]); rpgLiteHealthTime(frightHero, a[2]); }
        else if (code == 8)
            rpgFrightAcquire(frightHero, frightHero.frightPending[a[2]], [frightTrait(a[3], 1, a[4], a[5])]);
        else if (code == 9)
            rpgFrightAcquire(frightHero, frightHero.frightPending[a[2]], [frightHero.trait(a[3])]);
        else if (code == 10) frightLast.panic = rpgFrightPanicReaction(frightHero);
        else if (code == 11) frightHero.frightEpisode.medicalCare = true;
        else if (code == 12) { rpgFrightCheck(frightHero, s); throw new RpgError(); }
        else if (code == 13) frightHero.traits = [];
        else if (code == 14)
        {
            frightLast.valid = nil; frightLast.reason = nil;
            try { rpgLiteValidateTraits(frightHero); frightLast.valid = true; }
            catch (RpgLiteCharacterError error) { frightLast.reason = error.reason; }
        }
        else if (code == 15)
        {
            frightLast.reason = nil;
            try { rpgFrightModifier(frightHero, s); }
            catch (RpgExpandedError error) { frightLast.reason = error.reason; }
        }
        else if (code == 16)
        {
            rpgFrightEnd(frightHero);
            frightHero.injury = 0; frightHero.fatigue = 0; frightHero.shock = 0; frightHero.posture = 'standing';
            frightHero.unconscious = nil; frightHero.stunned = nil; frightHero.frightPending = [];
            frightHero.lingeringPenalty = 0; frightHero.lingeringSeconds = 0; frightHero.iq = 10; frightHero.ht = 10;
        }
        return nil;
    }
;
frightAction: FrightTestAction;
frightVerb: Verb code = 700 action = frightAction label = 'fright-test';
startup() { return vhylStart(); }
modify gameMain initialRoom = frightRoom;
act(verb, args)
{
    if (verb == 700) { frightInput.code = args[1]; frightInput.args = args; return vhylAct(700, []); }
    local hero = frightHero; local episode = hero.frightEpisode;
    if (verb == 990)
    {
        event('test.fright-state'); eventValue(hero.iq); eventValue(hero.ht); eventValue(hero.hp());
        eventValue(hero.fp()); eventValue(hero.stunned); eventValue(hero.unconscious); eventValue(hero.posture);
        eventValue(hero.panicked); eventValue(hero.retching); eventValue(hero.fearSeconds > 0);
        eventValue(episode == nil ? nil : episode.kind); eventValue(episode == nil ? nil : episode.fixed);
        eventValue(episode == nil ? nil : episode.clock); eventValue(episode == nil ? nil : episode.recovery);
        eventValue(episode == nil ? nil : episode.interval); eventValue(episode == nil ? nil : episode.score);
        eventValue(episode == nil ? nil : episode.elapsed); eventValue(episode == nil ? nil : episode.days);
        eventValue(hero.lingeringPenalty); eventValue(hero.lingeringSeconds); eventValue(hero.frightPending.length());
        eventValue(hero.traits.length()); eventValue(rpgRandom.state); eventValue(rpgRandom.draws);
        eventValue(rpgLedger.seconds); eventValue(rpgLiteCharacterCost(hero, nil));
        return nil;
    }
    if (verb == 991)
    {
        local r = frightLast.result;
        event('test.fright-result'); eventValue(r.status); eventValue(r.reason);
        eventValue(r.check == nil ? nil : r.check.roll); eventValue(r.score);
        eventValue(r.check == nil ? nil : r.check.margin); eventValue(r.tableRoll); eventValue(r.total);
        eventValue(r.row); eventValue(r.fatigue); eventValue(r.injury); eventValue(r.panicRoll);
        eventValue(r.acquisitions.length()); eventValue(r.modifier);
        return nil;
    }
    if (verb == 992)
    {
        event('test.fright-score'); eventValue(rpgFrightModifier(hero, frightSituation));
        eventValue(rpgFrightModifiedWill(hero, frightSituation)); eventValue(rpgFrightScore(hero, frightSituation));
        return nil;
    }
    if (verb == 993)
    {
        foreach (local item in hero.frightPending)
        { event('test.fright-pending'); eventValue(item.kind); eventValue(item.points); eventValue(item.row); }
        event('test.fright-pending-end'); return nil;
    }
    if (verb == 994)
    {
        local trait = hero.trait(args[1]);
        event('test.fright-trait'); eventValue(trait == nil ? nil : trait.selfControlRating);
        eventValue(trait == nil ? nil : trait.creationCost()); eventValue(trait == nil ? nil : trait.acquiredInPlay);
        return nil;
    }
    if (verb == 995)
    {
        event('test.fright-last'); eventValue(frightLast.panic); eventValue(frightLast.valid); eventValue(frightLast.reason);
        return nil;
    }
    return vhylAct(verb, args);
}
