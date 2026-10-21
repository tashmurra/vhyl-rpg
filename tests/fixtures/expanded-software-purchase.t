#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-equipment.t>
#include <vhyl-rpg-expanded-technology.t>
purchaseRoom: Room 'Software Shop';
purchaseRules: RpgExpandedRules;
purchaseUser: RpgExpandedProfile rules = purchaseRules money = 1000;
purchaseItem: RpgLiteItem;
purchaseHost: RpgExpandedComputer item = purchaseItem complexity = 2 powered = true;
purchasePackage: RpgLiteItem id = 'accounts-documentation' cost = 100 weight = 0;
purchaseCopy: RpgExpandedSoftwareCopy id = 'accounts' host = purchaseHost complexity = 2 approved = true evidence = 'Authorized host copy';
purchaseRequest: RpgExpandedSoftwarePurchase profile = purchaseUser item = purchasePackage copy = purchaseCopy
    available = true permitted = true evidence = 'Sale includes documentation and delivery to this host';
purchaseRun: RpgExpandedProgramRun id = 'first-instance' host = purchaseHost copy = purchaseCopy;
purchaseSecondRun: RpgExpandedProgramRun id = 'second-instance' host = purchaseHost copy = purchaseCopy;
purchaseInput: object code = 0;
class SoftwarePurchaseAction: Action
    exec(context)
    {
        local code = purchaseInput.code;
        if (code == 3) purchaseUser.money = 99;
        if (code == 4) purchaseRequest.permitted = nil;
        if (code == 5) { purchaseRun.start(); purchaseSecondRun.start(); return nil; }
        if (code == 6) { purchaseHost.copies = []; return nil; }
        if (code == 7) purchaseRequest.evidence = 'Retargeted authorization';
        if (code == 8) purchaseHost.copies = [purchaseCopy];
        local value = code == 2 ? purchaseRequest.assess() : purchaseRequest.acquire();
        event('test.software-purchase'); eventValue(value.status); eventValue(value.reason); eventValue(value.money);
        if (code == 1) throw new RpgError(); return nil;
    }
;
purchaseAction: SoftwarePurchaseAction;
purchaseVerb: Verb code = 2093 action = purchaseAction label = 'purchase software';
modify gameMain initialRoom = purchaseRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
turn(tokens) { return rpgDispatchTurn(tokens); }
act(verb,args)
{
    if (verb == 2093) { purchaseInput.code = args[1]; return rpgDispatchAction(verb,[]); }
    if (verb == 2094)
    {
        event('test.software-purchase-state'); eventValue(purchaseUser.money); eventValue(purchaseUser.equipment.length());
        eventValue(purchaseHost.copies.length()); eventValue(purchaseHost.runs.length());
        eventValue(purchaseRequest.claimed ? 1 : 0); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    return rpgDispatchAction(verb,args);
}
