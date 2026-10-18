#include "expanded-sensory-memory.t"
#include <vhyl-dialogue.t>
modify player rpgProfile = crossPhysician;
memoryPreviewAction: RpgExpandedSensoryMemoryAction attempt = memoryAttempt operation = 'preview';
memoryResolveAction: RpgExpandedSensoryMemoryAction attempt = memoryAttempt;
memoryRollbackAction: RpgExpandedSensoryMemoryAction attempt = memoryAttempt
    perform(actor) { inherited(actor); throw new RpgError(); }
;
memoryPreviewVerb: Verb code = 28210 action = memoryPreviewAction label = 'assess-memory';
memoryResolveVerb: Verb code = 28211 action = memoryResolveAction label = 'resolve-memory';
memoryRollbackVerb: Verb code = 28212 action = memoryRollbackAction label = 'rollback-memory';
grammar command(memoryPreviewCmd): 'assess' 'memory' : Command action = memoryPreviewAction;
grammar command(memoryResolveCmd): 'resolve' 'memory' : Command action = memoryResolveAction;
grammar command(memoryRollbackCmd): 'rollback' 'memory' : Command action = memoryRollbackAction;
memoryGuide: Actor 'guide' location(healthRoom) vocab = 'guide';
memoryConversation: Conversation id = 'sensory-memory' target = memoryGuide choices = [memoryPreviewChoice,memoryResolveChoice,memoryRollbackChoice];
class MemoryRouteChoice: DialogueChoice
    memoryAction = nil
    selected(context) { return self.memoryAction.perform(context.asker); }
;
memoryPreviewChoice: MemoryRouteChoice id = 'preview' labelId = 'memory.preview' memoryAction = memoryPreviewAction;
memoryResolveChoice: MemoryRouteChoice id = 'resolve' labelId = 'memory.resolve' memoryAction = memoryResolveAction;
memoryRollbackChoice: MemoryRouteChoice id = 'rollback' labelId = 'memory.rollback' memoryAction = memoryRollbackAction;
memoryPreviewLabel: Message id = 'memory.preview' text = 'Assess the memorization';
memoryResolveLabel: Message id = 'memory.resolve' text = 'Attempt the memorization';
memoryRollbackLabel: Message id = 'memory.rollback' text = 'Exercise memorization rollback';
modify PhysicianFixtureAction
    exec(context)
    {
        if (healthInput.code == 28201) { player.rpgProfile = nil; return nil; }
        if (healthInput.code == 28202) { player.rpgProfile = beggingObserver; return nil; }
        if (healthInput.code == 28203)
        { memoryPreviewAction.attempt = memoryRetry; memoryResolveAction.attempt = memoryRetry; memoryRollbackAction.attempt = memoryRetry; return nil; }
        return inherited(context);
    }
;
