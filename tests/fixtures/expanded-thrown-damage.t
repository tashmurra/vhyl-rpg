#include "expanded-throw-attempt.t"
modify heldThrow target = 'specific' targetEntity = catchProfile;
modify throwAttempt recipient = nil;
modify throwStone weight = 1000;
modify rpgRandom
    die() { self.draws += 1; return self.draws % 2 == 0 ? 4 : 2; }
;
thrownDamage: RpgExpandedThrownDamage id = 'stone-impact' attempt = throwAttempt objectKind = 'fragile'
    defensesResolved = true hitConfirmed = true approved = true evidence = 'The ordinary thrown object hits the specified undefended target';
thrownDamageDuplicate: RpgExpandedThrownDamage id = 'second-impact' attempt = throwAttempt objectKind = 'fragile'
    defensesResolved = true hitConfirmed = true approved = true evidence = 'A second ID cannot reroll the same ordinary impact';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 1180)
        {
            local value = thrownDamage.assess(); event('test.thrown-damage-preview');
            eventValue(value.status); eventValue(value.reason); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 1181 || code == 1182)
        { thrownDamage.resolve(); if (code == 1182) throw new RpgError(); return nil; }
        if (code == 1183)
        {
            event('test.thrown-damage-owned'); eventValue(bleedProfile.thrownDamageRolls.length());
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
            eventValue(thrownDamage.result == nil ? nil : thrownDamage.result.targetDamage);
            eventValue(thrownDamage.result == nil ? nil : thrownDamage.result.objectDamage);
            eventValue(thrownDamage.result == nil ? 0 : thrownDamage.result.targetDice.length());
            eventValue(thrownDamage.result == nil ? 0 : thrownDamage.result.objectDice.length()); return nil;
        }
        if (code == 1184)
        {
            event('test.thrown-damage-duplicate');
            try { eventValue(thrownDamageDuplicate.resolve().status); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        if (code == 1185) { thrownDamage.objectKind = 'durable'; return nil; }
        if (code == 1186) { thrownDamage.objectKind = 'character'; return nil; }
        if (code == 1187) { thrownDamage.damageType = 'cut'; thrownDamage.shapeEvidence = 'The authored cutting edge contacts the target'; return nil; }
        if (code == 1188) { thrownDamage.defensesResolved = nil; return nil; }
        if (code == 1189) { thrownDamage.shapeEvidence = nil; return nil; }
        if (code == 1190) { bleedProfile.st = 28; throwStone.weight = 5000; return nil; }
        return inherited(context);
    }
;
