#include "expanded-peg-support.t"
#include <vhyl-rpg-expanded-equipment.t>
modify fallInjury dropDestination = bleedRoom;
crutchLeftArm: RpgExpandedBodyPart id = 'support-arm' kind = 'arm' profile = bleedProfile;
crutchLeftHand: RpgExpandedBodyPart id = 'support-hand' kind = 'hand' profile = bleedProfile parent = crutchLeftArm;
crutchRightArm: RpgExpandedBodyPart id = 'free-arm' kind = 'arm' profile = bleedProfile;
crutchRightHand: RpgExpandedBodyPart id = 'free-hand' kind = 'hand' profile = bleedProfile parent = crutchRightArm;
crutchItem: RpgLiteItem id = 'crutch' ready = true bodySupports = [crutchLeftHand];
modify bleedProfile dx = 14 equipment = [crutchItem]
    bodyParts = [fallArm,fallHand,fallOtherArm,fallOtherHand,crutchLeftArm,crutchLeftHand,crutchRightArm,crutchRightHand];
crutchSupport: RpgExpandedCrutchSupport profile = bleedProfile part = fallArm item = crutchItem
    hands = [crutchLeftHand] fitted = true terrainSuitable = true approved = true
    evidence = 'The authored fitted crutch arrangement uses this hand on a suitable route';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 980 || code == 981)
        { crutchSupport.activate(); if (code == 981) throw new RpgError(); return nil; }
        if (code == 982)
        {
            event('test.crutch-support'); eventValue(bleedProfile.injury);
            eventValue(bleedProfile.mobilitySupport == crutchSupport ? 1 : 0);
            try { eventValue(bleedProfile.move()); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(bleedProfile.supportReserved(crutchLeftHand) ? 1 : 0);
            eventValue(bleedProfile.supportReserved(crutchRightHand) ? 1 : 0);
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 983) { crutchSupport.part = fallHand; fallInjury.location = 'foot'; fallInjury.bodyPart = fallHand; return nil; }
        if (code == 984) { crutchItem.ready = nil; return nil; }
        if (code == 985) { crutchLeftHand.disabled = true; return nil; }
        if (code == 986) { crutchSupport.deactivate(); return nil; }
        return inherited(context);
    }
;
