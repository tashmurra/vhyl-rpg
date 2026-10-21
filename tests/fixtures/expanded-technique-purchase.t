#include "expanded-learning-bar.t"
modify learningBar mitigated = true;
modify bleedRules techniques = true;
modify bleedProfile contributions = [purchaseTechnique];
purchaseTechnique: RpgExpandedTechnique
    id = 'focused-action' owner = bleedProfile skill = learningSkill penalty = -3 hard = true
;
purchaseFirst: RpgExpandedTechniquePurchase
    id = 'focused-first' profile = bleedProfile technique = purchaseTechnique targetPoints = 2
    approved = true evidence = 'Approved difficulty, default and cap for a specific practiced action'
    practicedAction = 'Focused application' distinctFromCoreAction = true
;
purchaseNext: RpgExpandedTechniquePurchase
    id = 'focused-next' profile = bleedProfile technique = purchaseTechnique targetPoints = 3
    approved = true evidence = 'Further approved practice of the same action'
    practicedAction = 'Focused application' distinctFromCoreAction = true
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 3400 || code == 3401 || code == 3402 || code == 3403)
        {
            local value = code == 3400 ? purchaseFirst.assess()
                : code == 3403 ? purchaseNext.apply() : purchaseFirst.apply();
            event('test.technique-purchase'); eventValue(value.status); eventValue(value.reason); eventValue(value.points);
            if (code == 3402) throw new RpgError(); return nil;
        }
        if (code == 3404)
        {
            event('test.technique-purchase-state'); eventValue(purchaseTechnique.points);
            eventValue(bleedProfile.unspentPoints); eventValue(bleedProfile.developmentRevision);
            eventValue(bleedProfile.techniquePurchases.length()); eventValue(purchaseTechnique.score());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 3405) { purchaseFirst.targetPoints = 1; return nil; }
        if (code == 3406) { purchaseFirst.targetPoints = 5; return nil; }
        if (code == 3407) { purchaseFirst.distinctFromCoreAction = nil; return nil; }
        if (code == 3408) { learningBar.mitigated = nil; return nil; }
        if (code == 3409) { bleedRules.techniques = nil; return nil; }
        if (code == 3410) { purchaseTechnique.hard = nil; purchaseFirst.targetPoints = 1; return nil; }
        if (code == 3411) { learningTraining.points = 2; return nil; }
        if (code == 3412) { bleedProfile.unspentPoints = 1; return nil; }
        if (code == 3413)
        {
            event('test.technique-disabled-score');
            try { purchaseTechnique.score(); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
