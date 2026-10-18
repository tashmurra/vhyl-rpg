#include "expanded-bleeding.t"
#include <vhyl-rpg-expanded-equipment.t>
acuteScene: RpgExpandedFearContext profile = bleedProfile approved = true evidence = 'An extraordinary threatening apparition';
acuteEvent: RpgExpandedFearAcuteInjury id = 'apparition-collapse' context = acuteScene approved = true
    evidence = 'The recorded fear-table total is thirty-two' dropDestination = bleedRoom;
acuteHeld: RpgLiteItem id = 'lamp' ready = true weight = 100;
acuteInput: object die = 1 drops = 0 knockdowns = 0;
modify rpgRandom
    die() { self.draws += 1; return acuteInput.die; }
;
modify bleedProfile
    onEquipmentDropped(item) { inherited(item); acuteInput.drops += 1; return nil; }
    onKnockdown() { inherited(); acuteInput.knockdowns += 1; return nil; }
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 10500) { bleedProfile.equipment = [acuteHeld]; bleedInput.forcedRoll = 10; return nil; }
        if (code == 10501)
        {
            local value = acuteEvent.assess(); event('test.fear-acute-preview'); eventValue(value.status);
            eventValue(value.reason); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 10502 || code == 10503)
        {
            local value = acuteEvent.apply(); event('test.fear-acute'); eventValue(value.status); eventValue(value.amount);
            if (code == 10503) throw new RpgError(); return nil;
        }
        if (code == 10504)
        {
            event('test.fear-acute-state'); eventValue(bleedProfile.injury); eventValue(bleedProfile.posture);
            eventValue(bleedProfile.expandedWounds.length()); eventValue(acuteHeld.storageLocation == bleedRoom ? 1 : 0);
            eventValue(acuteInput.drops); eventValue(acuteInput.knockdowns); eventValue(bleedProfile.timeElapsed); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 10505) { acuteInput.die = 6; return nil; }
        if (code == 10506) { acuteEvent.dropDestination = nil; return nil; }
        if (code == 10507) { bleedInput.forcedRoll = 11; return nil; }
        return inherited(context);
    }
;
