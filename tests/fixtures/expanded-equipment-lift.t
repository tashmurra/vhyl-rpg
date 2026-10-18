#include "expanded-bleeding.t"
#include <vhyl-rpg-expanded-equipment.t>
#include <vhyl-rpg-expanded-exploration.t>
liftCrate: RpgLiteItem id = 'crate' weight = 6000 storageLocation = bleedRoom;
modify bleedProfile equipment = [liftCrate];
liftOperation: RpgExpandedEquipmentLift id = 'crate-pickup' profile = bleedProfile item = liftCrate
    sourceLocation = bleedRoom freeHands = 2 accessible = true approved = true
    evidence = 'An owned stored crate within reach, with both hands free';
liftArm: RpgExpandedBodyPart id = 'arm' kind = 'arm' profile = bleedProfile;
liftHand: RpgExpandedBodyPart id = 'hand' kind = 'hand' parent = liftArm profile = bleedProfile;
liftInput: object interrupt = nil;
modify rpgLedger
    afterAdvance(previousSeconds)
    {
        inherited(previousSeconds);
        if (liftInput.interrupt) liftCrate.weight = 9000;
        return nil;
    }
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 740)
        { local value = liftOperation.assess(); event('test.lift-preview'); eventValue(value.status); eventValue(value.reason); eventValue(value.seconds); return nil; }
        if (code == 741 || code == 742)
        { liftOperation.apply(); if (code == 742) throw new RpgError(); return nil; }
        if (code == 743)
        {
            event('test.lift-owned'); eventValue(liftCrate.storageLocation == nil ? 1 : 0);
            eventValue(bleedProfile.loadHundredths()); eventValue(bleedProfile.liftingReceipts.length());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); eventValue(liftCrate.weight); return nil;
        }
        if (code == 744) { liftOperation.mode = 'one-hand'; return nil; }
        if (code == 745) { liftOperation.freeHands = 0; return nil; }
        if (code == 746) { liftInput.interrupt = true; return nil; }
        if (code == 747)
        { bleedProfile.bodyParts = [liftArm,liftHand]; liftOperation.mode = 'one-hand'; liftCrate.weight = 3000;
          liftOperation.hands = [liftHand]; liftHand.disabled = true; return nil; }
        if (code == 748) { liftHand.disabled = nil; return nil; }
        return inherited(context);
    }
;
