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
computerRoom: Room 'Control Room';
computerItem: RpgLiteItem;
computerHost: RpgExpandedComputer item = computerItem complexity = 2 powered = true storageMB = 100
    copies = [computerFull,computerSmall,computerLarge];
computerFull: RpgExpandedSoftwareCopy dataSharing = true id = 'full' host = computerHost complexity = 2 approved = true evidence = 'Installed copy';
computerSmall: RpgExpandedSoftwareCopy id = 'small' host = computerHost complexity = 1 approved = true evidence = 'Installed copy';
computerLarge: RpgExpandedSoftwareCopy id = 'large' host = computerHost complexity = 3 approved = true evidence = 'Installed copy';
computerRun: RpgExpandedProgramRun id = 'primary' host = computerHost copy = computerFull;
computerNext: RpgExpandedProgramRun id = 'next' host = computerHost copy = computerFull;
terminalUser: RpgLiteProfile;
terminalOtherItem: RpgLiteItem;
terminalOther: RpgExpandedComputer item = terminalOtherItem complexity = 1 powered = true storageMB = 100 copies = [receiverCopy];
terminalUnknown: RpgExpandedComputer item = terminalOtherItem complexity = 1 powered = true;
computerTerminal: RpgExpandedTerminal controller = terminalUser hosts = [computerHost,terminalOther]
    current = computerHost powered = true;
terminalSwitch: RpgExpandedTerminalSwitch id = 'other-host' terminal = computerTerminal target = terminalOther
    evidence = 'Authorized local terminal connection';
terminalBack: RpgExpandedTerminalSwitch id = 'original-host' terminal = computerTerminal target = computerHost
    evidence = 'Return to original connected host';
terminalSame: RpgExpandedTerminalSwitch id = 'same-host' terminal = computerTerminal target = computerHost
    evidence = 'Already selected host';
computerData: RpgExpandedStoredData id = 'first-data' host = computerHost reference = 'authored-log'
    sizeMB = 10 approved = true evidence = 'Available log with declared size';
computerBulk: RpgExpandedStoredData id = 'bulk-data' host = computerHost reference = 'authored-charts'
    sizeMB = 90 approved = true evidence = 'Available charts with declared size';
computerOverflow: RpgExpandedStoredData id = 'extra-data' host = computerHost reference = 'authored-note'
    sizeMB = 1 approved = true evidence = 'Available note with declared size';
computerRefill: RpgExpandedStoredData id = 'replacement-data' host = computerHost reference = 'replacement-log'
    sizeMB = 10 approved = true evidence = 'Another log with declared size';
computerLink: RpgExpandedComputerLink id = 'local-link' first = computerHost second = terminalOther
    compatible = true mediumAvailable = true addressKnown = true credentialsSatisfied = true
    evidence = 'Compatible hosts with a known local connection and credentials';
receiverCopy: RpgExpandedSoftwareCopy id = 'receiver' host = terminalOther complexity = 1
    approved = true dataSharing = true evidence = 'Installed sharing program';
receiverRun: RpgExpandedProgramRun id = 'receiver-process' host = terminalOther copy = receiverCopy;
computerTransfer: RpgExpandedDataTransfer id = 'copy-log' dataId = 'received-log' link = computerLink
    source = computerData target = terminalOther senderProgram = computerRun receiverProgram = receiverRun
    copyApproved = true uninterrupted = true durationSeconds = 3 evidence = 'Authorized three-second log copy';
transferClockFault: object enabled = nil;
modify rpgLedger
    afterAdvance(previousSeconds)
    {
        inherited(previousSeconds);
        if (transferClockFault.enabled) computerLink.credentialsSatisfied = nil;
        return nil;
    }
;
computerInput: object code = 0;
class ComputerAction: Action
    exec(context)
    {
        local code = computerInput.code;
        if (code >= 80)
        {
            if (code == 80)
            { computerLink.connect(); computerData.store(); computerRun.start(); receiverRun.start(); return nil; }
            if (code == 84) computerTransfer.copyApproved = nil;
            if (code == 85) receiverRun.stop();
            if (code == 86) terminalOther.storageMB = 9;
            if (code == 87) computerLink.credentialsSatisfied = nil;
            if (code == 88) computerData.remove();
            if (code == 89) { computerTransfer.result.delivery.remove(); return nil; }
            if (code == 90) computerTransfer.evidence = 'Changed transfer';
            if (code == 91) transferClockFault.enabled = true;
            local transferred = code == 83 ? computerTransfer.assess() : computerTransfer.apply();
            event('test.transfer-operation'); eventValue(transferred.status); eventValue(transferred.reason); eventValue(transferred.seconds);
            if (code == 82) throw new RpgError(); return nil;
        }
        if (code >= 60)
        {
            if (code == 63 || code == 64)
            {
                event('test.link-disconnect'); eventValue(computerLink.disconnect());
                if (code == 64) throw new RpgError(); return nil;
            }
            if (code == 65) computerLink.compatible = nil;
            if (code == 66) computerLink.mediumAvailable = nil;
            if (code == 67) computerLink.addressKnown = nil;
            if (code == 68) computerLink.credentialsSatisfied = nil;
            if (code == 69) terminalOther.powered = nil;
            if (code == 70) computerLink.evidence = 'Changed endpoints';
            if (code == 71) { computerLink.credentialsSatisfied = nil; return nil; }
            if (code == 72) { computerLink.credentialsSatisfied = true; return nil; }
            local linked = code == 62 ? computerLink.assess() : computerLink.connect();
            event('test.link-operation'); eventValue(linked.status); eventValue(linked.reason);
            if (code == 61) throw new RpgError(); return nil;
        }
        if (code >= 40)
        {
            if (code == 45 || code == 46 || code == 49)
            {
                event('test.data-remove'); eventValue(code == 49 ? computerBulk.remove() : computerData.remove());
                if (code == 46) throw new RpgError(); return nil;
            }
            if (code == 47) computerData.sizeMB = 11;
            if (code == 50) computerHost.powered = nil;
            local record = code == 43 ? computerBulk : code == 44 || code == 50 ? computerOverflow
                : code == 48 ? computerRefill : computerData;
            local stored = code == 42 ? record.assess() : record.store();
            event('test.data-operation'); eventValue(stored.status); eventValue(stored.reason);
            if (code == 41) throw new RpgError(); return nil;
        }
        if (code >= 20)
        {
            if (code == 25) terminalSwitch.target = terminalUnknown;
            if (code == 26) terminalOther.powered = nil;
            if (code == 27) terminalSwitch.evidence = 'Changed evidence';
            if (code == 28) { computerTerminal.validate(); return nil; }
            local request = code == 23 ? terminalBack : code == 24 ? terminalSame : terminalSwitch;
            local switched = code == 22 ? request.assess() : request.apply();
            event('test.terminal-operation'); eventValue(switched.status); eventValue(switched.reason); eventValue(switched.seconds);
            if (code == 21) throw new RpgError(); return nil;
        }
        if (code == 3 || code == 4)
        {
            event('test.computer-stop'); eventValue(computerRun.stop());
            if (code == 4) throw new RpgError(); return nil;
        }
        if (code == 5)
        {
            for (local index = 1; index <= 10; index += 1)
            {
                local process = new RpgExpandedProgramRun(); process.id = index;
                process.host = computerHost; process.copy = computerSmall; process.start();
            }
            return nil;
        }
        if (code == 6) computerNext.copy = computerSmall;
        if (code == 7) computerNext.copy = computerLarge;
        if (code == 8) computerHost.powered = nil;
        if (code == 9) computerRun.id = 'changed';
        local request = code == 6 || code == 7 || code == 10 ? computerNext : computerRun;
        local value = code == 2 ? request.assess() : request.start();
        event('test.computer-operation'); eventValue(value.status); eventValue(value.reason);
        if (code == 1) throw new RpgError(); return nil;
    }
;
computerAction: ComputerAction;
computerVerb: Verb code = 2080 action = computerAction label = 'program';
modify gameMain initialRoom = computerRoom;
startup() { return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args)
{
    if (verb == 2080) { computerInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 2087)
    {
        event('test.transfer-state'); eventValue(computerHost.usedStorageMB()); eventValue(terminalOther.usedStorageMB());
        eventValue(computerHost.used()); eventValue(terminalOther.used()); eventValue(computerLink.transfers.length());
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
        eventValue(computerTransfer.result != nil && computerTransfer.result.delivery.present ? 1 : 0); return nil;
    }
    if (verb == 2086)
    {
        event('test.link-state'); eventValue(computerLink.connected ? 1 : 0); eventValue(computerLink.usable() ? 1 : 0);
        eventValue(computerHost.links.length()); eventValue(terminalOther.links.length());
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2083)
    {
        event('test.data-state'); eventValue(computerHost.usedStorageMB()); eventValue(computerHost.data.length());
        eventValue(computerData.present ? 1 : 0); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
        eventValue(computerHost.used()); return nil;
    }
    if (verb == 2085)
    { event('test.reference-data'); eventValue(rpgExpandedReferenceDataMB(args[1])); return nil; }
    if (verb == 2084)
    { event('test.storage-units'); eventValue(rpgExpandedStorageMB(args[1],args[2])); return nil; }
    if (verb == 2082)
    {
        event('test.terminal-state'); eventValue(computerTerminal.current == computerHost ? 'original' : 'other');
        eventValue(computerTerminal.switches.length()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
        eventValue(computerHost.used()); return nil;
    }
    if (verb == 2081)
    {
        event('test.computer-state'); eventValue(computerHost.used()); eventValue(computerHost.capacity());
        eventValue(computerHost.runs.length()); eventValue(computerRun.active ? 1 : 0);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    return vhylAct(verb,args);
}
