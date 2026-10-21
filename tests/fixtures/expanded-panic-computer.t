#include "expanded-panic-object.t"
modify panicObject id = 'field-recorder';
modify panicObjectCondition construction = 'unliving' computer = panicComputer
    evidence = 'One non-sentient computer, no separate subsystem or fragility effects';
modify panicObjectWound evidence = 'Resolved destructive impact after protection and unliving injury adjustments';
modify panicObjectOperation evidence = 'The carried recorder is the reachable, unopposed target of the authored panic reaction';
panicComputer: RpgExpandedComputer item = panicObject complexity = 1 powered = true storageMB = 100 copies = [panicSoftware];
panicSoftware: RpgExpandedSoftwareCopy id = 'recorder-program' host = panicComputer complexity = 1
    approved = true evidence = 'A local installed program';
panicRun: RpgExpandedProgramRun id = 'recording-process' host = panicComputer copy = panicSoftware;
panicData: RpgExpandedStoredData id = 'field-log' host = panicComputer reference = 'authored-field-log' sizeMB = 10
    approved = true evidence = 'Ten megabytes of local fictional field records';
panicNewData: RpgExpandedStoredData id = 'new-log' host = panicComputer reference = 'new-authored-record' sizeMB = 1
    approved = true evidence = 'An attempted write after damage';
backupItem: RpgLiteItem id = 'archive-host';
backupHost: RpgExpandedComputer item = backupItem powered = true complexity = 1 storageMB = 100;
backupData: RpgExpandedStoredData id = 'archive-copy' host = backupHost reference = 'authored-field-log' sizeMB = 10
    approved = true evidence = 'An independently retained backup on another machine';
computerFinalWound: RpgExpandedObjectWound id = 'final-recorder-impact' condition = panicObjectCondition amount = 50
    approved = true evidence = 'A later separately resolved destructive impact';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 700) { panicData.store(); backupData.store(); panicRun.start(); return nil; }
        if (code == 701)
        {
            event('test.panic-computer'); eventValue(panicComputer.powered ? 1 : 0); eventValue(panicRun.active ? 1 : 0);
            eventValue(panicComputer.copies.length()); eventValue(panicData.present ? 1 : 0);
            eventValue(panicComputer.used()); eventValue(panicComputer.usedStorageMB());
            eventValue(backupData.present ? 1 : 0); eventValue(backupHost.usedStorageMB());
            eventValue(panicComputer.hardwareFailures.length()); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 702) { panicData.present = true; panicComputer.usedStorageMB(); return nil; }
        if (code == 703) { panicRun.active = true; panicComputer.used(); return nil; }
        if (code == 704) { panicComputer.copies = [panicSoftware]; panicComputer.hardwareAvailable(); return nil; }
        if (code == 705) { panicData.store(); panicRun.start(); return nil; }
        if (code == 706)
        { local value = panicNewData.assess(); event('test.panic-computer-write'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 707)
        { panicComputer.powered = true; event('test.panic-computer-available'); eventValue(panicComputer.hardwareAvailable() ? 1 : 0); return nil; }
        if (code == 708) { panicDice.rolls = [18]; panicObjectWound.amount = 10; panicObjectWound.apply(); return nil; }
        if (code == 709 || code == 710) { objectStress.apply(); if (code == 710) throw new RpgError(); return nil; }
        if (code == 711) { computerFinalWound.apply(); return nil; }
        if (code == 712) { panicComputer.hardwareFailure.cause = 'disabled'; panicComputer.validateHardwareHistory(); return nil; }
        if (code == 713) { event('test.panic-computer-health'); eventValue(panicObjectCondition.health); return nil; }
        if (code == 714) { panicObjectCondition.computer = nil; panicObjectWound.assess(); return nil; }
        if (code == 715) { panicData.reference = 'changed'; extremeFirst.assess(); return nil; }
        return inherited(context);
    }
;
