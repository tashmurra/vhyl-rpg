#include "expanded-persistent-dressing.t"
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code < 240 || code > 258) return inherited(context);
        local entry = new RpgExpandedPoisonEntry(); entry.patient = bleedProfile;
        entry.approved = true; entry.evidence = 'Resolved contact and protection facts for this fixture';
        entry.route = 'blood';
        if (code == 241 || code == 242 || code == 243) entry.persistentWoundReached = true;
        if (code == 242 || code == 243) entry.method = 'spray';
        if (code == 243) entry.vulnerableAreaHit = true;
        if (code >= 244 && code <= 246)
        {
            entry.method = 'area'; entry.inArea = true;
            entry.sealed = code == 244; entry.filteredLungs = code >= 245; entry.protectedVision = code == 246;
        }
        if (code == 247 || code == 248)
        { entry.route = 'contact'; entry.method = 'weapon'; entry.skinContact = true; entry.unclad = true; entry.unarmored = code == 248; }
        if (code == 249 || code == 250)
        { entry.route = 'digestive'; entry.swallowed = true; entry.forcedSwallow = true; entry.headOrNeckHeldSeconds = code == 249 ? 9 : 10; }
        if (code >= 251 && code <= 253)
        {
            entry.route = 'respiratory'; entry.inhaled = true; entry.holdingBreath = true; entry.improvisedMask = true;
            if (code >= 252) bleedProfile.stunned = true;
            entry.noBreathing = code == 253;
        }
        if (code >= 254 && code <= 256)
        { entry.route = 'sense'; entry.sensePresent = code != 254; entry.senseProtected = code == 255; }
        if (code == 257)
        { entry.route = 'follow-up'; entry.method = 'weapon'; entry.penetrationKind = 'piercing'; entry.wound = bleedWound; }
        if (code == 258) entry.openWoundContact = true;
        local value = entry.assess(); event('test.poison-entry'); eventValue(value.status);
        eventValue(value.exposed ? 1 : 0); eventValue(value.viaPersistentWound ? 1 : 0); eventValue(value.resistanceModifier);
        eventValue(bleedProfile.injury); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
    }
;
