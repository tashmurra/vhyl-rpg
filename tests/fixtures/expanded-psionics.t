#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-psionics.t>
powerRoom: Room 'Quiet Observatory';
modify gameMain initialRoom = powerRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
act(verb,args)
{
    if (verb == 2230)
    {
        local profile = new RpgExpandedProfile();
        local power = new RpgExpandedPsionicPower(); power.id = 'remote-sense';
        power.abilityIds = ['danger-sense']; power.powerModifier = -10;
        power.approved = true; power.evidence = 'Campaign permits this sensory family';
        local talent = new RpgExpandedPsionicTalent(); talent.id = 'remote-sense-talent'; talent.power = power;
        talent.level = args[1]; talent.aboveFourApproved = args[2] != 0;
        talent.approved = true; talent.evidence = 'Owned sensory potential'; talent.active = args[3] != 0;
        profile.traits = [talent];
        if (args[4] == 1) profile.traits = [];
        if (args[4] == 2) { power.broad = true; power.talentPoints = 10; }
        if (args[4] == 3) { power.broad = true; power.talentPoints = 10; power.customTalentPriceApproved = true; }
        if (args[4] == 4) { power.allowsTalent = nil; power.talentPoints = 0; }
        try
        {
        local cost = profile.traits.length() == 0 ? 0 : talent.creationCost();
        local bonus = rpgExpandedPsionicTalentBonus(profile,power);
        local eligibility = rpgExpandedPsionicLatentEligibility(profile,power,args[5]);
        event('test.psionic-talent'); eventValue(cost); eventValue(bonus); eventValue(eligibility.status);
        eventValue(eligibility.reason); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        catch (RpgExpandedError error) { event('test.psionic-reject'); eventValue(error.reason); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); }
    }
    return nil;
}
