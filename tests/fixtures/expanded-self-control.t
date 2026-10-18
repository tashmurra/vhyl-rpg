#include "expanded-pain.t"
#include <vhyl-rpg-expanded-traits.t>
ratedBehavior: RpgExpandedDisadvantage id = 'rated-behavior' points = -5 controlled = true
    approved = true selfControlRating = 6;
modify bleedProfile traits = [ratedBehavior];
ratedControlInput: object modifier = 0;
ratedTrigger: RpgExpandedSelfControlTrigger id = 'temptation' profile = bleedProfile trait = ratedBehavior
    trigger = 'original-opportunity' evidence = 'The author establishes an applicable occurrence';
ratedDuplicate: RpgExpandedSelfControlTrigger id = 'same-opportunity' profile = bleedProfile trait = ratedBehavior
    trigger = 'original-opportunity' evidence = 'The same occurrence cannot be rerolled under a new request';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 570 || code == 571)
        {
            local value = rpgLiteSelfControl(bleedProfile,ratedBehavior,ratedControlInput.modifier,code == 571);
            event('test.rated-control'); eventValue(value.status); eventValue(value.score);
            eventValue(value.achieved ? 1 : 0); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 572) { ratedBehavior.selfControlRating = 9; return nil; }
        if (code == 573) { ratedBehavior.selfControlRating = 12; return nil; }
        if (code == 574) { ratedBehavior.selfControlRating = 15; return nil; }
        if (code == 575) { ratedBehavior.selfControlRating = 11; return nil; }
        if (code == 576) { bleedProfile.will = 30; return nil; }
        if (code == 577) { ratedControlInput.modifier = -10; return nil; }
        if (code == 578) { ratedBehavior.approved = nil; return nil; }
        if (code == 579)
        { event('test.rated-control-draws'); eventValue(rpgRandom.draws); return nil; }
        if (code == 580) { ratedTrigger.assess(); return nil; }
        if (code == 581 || code == 582)
        { ratedTrigger.resolve(); if (code == 582) throw new RpgError(); return nil; }
        if (code == 583) { ratedTrigger.giveIn = true; return nil; }
        if (code == 584) { ratedDuplicate.resolve(); return nil; }
        if (code == 585)
        {
            event('test.control-trigger'); eventValue(bleedProfile.selfControlTriggers.length());
            eventValue(ratedTrigger.active ? 1 : 0); eventValue(ratedTrigger.check == nil ? nil : ratedTrigger.check.score);
            eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
