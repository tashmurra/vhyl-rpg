/* Optional adjudication boundary. Include after vhyl-rpg.t.
 * Copyright (c) 2026 John Cunningham. MIT License. */

/** A bounded, data-only question. Hooks are trusted observational game code.
 * Providers never receive objects, callbacks or permission to mutate the world. */
class RpgGmQuestion: object
    id = nil
    policy = '1'
    revision = 0
    prompt = ''
    pending = nil
    answer = nil
    answerStatus = nil
    contextData() { return []; }
    choicesData() { return []; }
    rulingReason(data) { return 'unsupported'; }
;

/** Provider result. ruled data must pass the question's authoritative validator. */
class RpgGmProposal: object
    status = 'needs-input'
    data = []
;

/** Replaceable synchronous authored provider. External inference uses ask/submit
 * across commands instead; do not run network or native inference inside a turn. */
class RpgGmProvider: object
    propose(packet) { return new RpgGmProposal(); }
;

/** Fixed authored ruling, useful for a deterministic game and provider tests. */
class RpgGmAuthoredProvider: RpgGmProvider
    data = []
    propose(packet)
    {
        local proposal = new RpgGmProposal(); proposal.status = 'ruled';
        proposal.data = self.data; return proposal;
    }
;

/** Private provider-boundary assessment; never publish its data to players by default. */
class RpgGmResult: object
    status = 'needs-ruling'
    reason = nil
    packet = nil
    data = nil
;

rpgGmLedger: object serial = 0;

/* Bound nesting, node count and text before traversing untrusted provider data. */
rpgGmDataSize(value, depth)
{
    if (depth > 8) return 100000;
    if (value == nil || value == true || dataType(value) == TypeInt) return 1;
    if (dataType(value) == TypeSString) return value.length() + 1;
    if (dataType(value) != TypeList || value.length() > 128) return 100000;
    local size = 1;
    foreach (local item in value)
    {
        size += rpgGmDataSize(item, depth + 1);
        if (size > 8192) return size;
    }
    return size;
}

/* Separate node bound keeps the scalar-event envelope below the host batch limit. */
rpgGmNodes(value)
{
    if (dataType(value) != TypeList) return 1;
    local count = 1;
    foreach (local item in value) count += rpgGmNodes(item);
    return count;
}

rpgGmSame(left, right)
{
    if (dataType(left) != dataType(right)) return nil;
    if (dataType(left) != TypeList) return left == right;
    if (left.length() != right.length()) return nil;
    for (local i = 1; i <= left.length(); i++)
        if (!rpgGmSame(left[i], right[i])) return nil;
    return true;
}

/** Pure, bounded snapshot. Only explicitly exported facts enter this value.
 * Player assertions belong in prompt, not in the authoritative context list. */
rpgGmDescribe(question)
{
    if (question == nil || !question.ofKind(RpgGmQuestion)
        || dataType(question.id) != TypeSString || question.id == ''
        || dataType(question.policy) != TypeSString || question.policy == ''
        || dataType(question.prompt) != TypeSString) throw new RpgError();
    rpgInteger(question.revision, 0, 2147483646);
    local value = [question.id, question.policy, question.revision,
        question.contextData(), question.choicesData(), question.prompt];
    if (rpgGmDataSize([1, 1, value], 0) > 8192
        || rpgGmNodes([1, 1, value]) > 256) throw new RpgError();
    return value;
}

/** Issue or reuse a pending packet [schema, serial, snapshot]. No casting occurs.
 * Serial numbers are session-local; hosts discard in-flight replies on restore. */
rpgGmAsk(question)
{
    local snapshot = rpgGmDescribe(question);
    if (question.pending != nil && rpgGmSame(question.pending[3], snapshot))
        return question.pending;
    rpgInteger(rpgGmLedger.serial, 0, 2147483646);
    rpgGmLedger.serial += 1;
    question.pending = [1, rpgGmLedger.serial, snapshot];
    question.answer = nil; question.answerStatus = nil;
    return question.pending;
}

/** Accept an external reply only for the exact outstanding snapshot and schema.
 * Invalid, stale and conflicting duplicate replies never replace an accepted ruling. */
rpgGmSubmit(question, packet, status, data)
{
    local result = new RpgGmResult(); result.status = 'blocked';
    if (rpgGmDataSize(packet, 0) > 8192 || rpgGmDataSize(data, 0) > 8192
        || rpgGmNodes(packet) > 256 || rpgGmNodes(data) > 256)
    { result.reason = 'invalid-data'; return result; }
    if (question.pending == nil || !rpgGmSame(packet, question.pending)
        || !rpgGmSame(question.pending[3], rpgGmDescribe(question)))
    { result.reason = 'stale-ruling'; return result; }
    if (!holds(['ruled', 'needs-input', 'unsupported'], status))
    { result.reason = 'invalid-status'; return result; }
    if (status == 'ruled')
    {
        result.reason = question.rulingReason(data);
        if (result.reason != nil) return result;
    }
    else if (!rpgGmSame(data, []))
    { result.reason = 'invalid-data'; return result; }
    if (question.answerStatus != nil)
    {
        if (status != question.answerStatus || !rpgGmSame(data, question.answer))
        { result.reason = 'conflicting-reply'; return result; }
        result.status = 'reused'; result.packet = packet; result.data = data; return result;
    }
    question.answerStatus = status; question.answer = data;
    return rpgGmRead(question);
}

/** Pure retrieval, with a fresh context check even after the reply was accepted. */
rpgGmRead(question)
{
    local result = new RpgGmResult();
    if (question.pending == nil || !rpgGmSame(question.pending[3], rpgGmDescribe(question)))
        return result;
    result.packet = question.pending;
    if (question.answerStatus == nil) return result;
    result.status = question.answerStatus; result.data = question.answer;
    if (result.status == 'ruled')
    {
        result.reason = question.rulingReason(result.data);
        if (result.reason != nil) { result.status = 'blocked'; result.data = nil; }
    }
    return result;
}

/** Explicit authored adjudication. Assessment and casting never call a provider. */
rpgGmResolve(question, provider)
{
    local packet = rpgGmAsk(question);
    local existing = rpgGmRead(question);
    if (existing.status != 'needs-ruling') return existing;
    local proposal = provider.propose(packet);
    if (proposal == nil || !proposal.ofKind(RpgGmProposal)) throw new RpgError();
    return rpgGmSubmit(question, packet, proposal.status, proposal.data);
}

/* Prefix tree of scalar events: list tokens carry length, scalar tokens a value.
 * This uses the existing host event ABI, without native handles or JSON parsing. */
rpgGmEmitData(value)
{
    event('rpg.gm.value');
    if (dataType(value) == TypeList)
    {
        eventValue('list'); eventValue(value.length());
        foreach (local item in value) rpgGmEmitData(item);
    }
    else
    {
        eventValue(value == nil ? 'null' : value == true ? 'bool'
            : dataType(value) == TypeInt ? 'int' : 'string');
        eventValue(value);
    }
    return nil;
}

/** Explicit opt-in host export, never part of player reporting or assessment.
 * Export only to the selected adjudicator; the packet may contain private facts. */
rpgGmPublishRequest(question)
{
    local packet = rpgGmAsk(question);
    event('rpg.gm.request'); eventValue(1);
    rpgGmEmitData(packet);
    event('rpg.gm.end'); return packet;
}
