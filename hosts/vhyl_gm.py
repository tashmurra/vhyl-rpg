"""Provider-neutral host contract. Standard library only; no inference or network I/O.

The engine remains authoritative. This bridge validates transport/correlation,
not game permissions. Discard the exchange after reset, restore or undo.
"""
from __future__ import annotations

import json
from typing import Protocol
from uuid import uuid4

SCHEMA = 1
LIMIT = 8192


def data_size(value, depth=0, _remaining=None):
    if _remaining is None:
        _remaining = [256]
    _remaining[0] -= 1
    if _remaining[0] < 0:
        raise ValueError('data node limit')
    if depth > 8:
        raise ValueError('data nesting limit')
    if value is None or value is True:
        return 1
    if type(value) is int and -(2**31) <= value < 2**31:
        return 1
    if type(value) is str:
        value.encode('utf-8')  # Reject unpaired surrogates before native transport.
        return len(value) + 1
    if type(value) is list and len(value) <= 128:
        total = 1
        for item in value:
            total += data_size(item, depth + 1, _remaining)
            if total > LIMIT:
                raise ValueError('data size limit')
        return total
    raise ValueError('unsupported data type')


def validate_packet(packet):
    if data_size(packet) > LIMIT:
        raise ValueError('data size limit')
    if type(packet) is not list or len(packet) != 3 or type(packet[0]) is not int or packet[0] != SCHEMA:
        raise ValueError('packet schema')
    _, serial, snapshot = packet
    if type(serial) is not int or serial < 1:
        raise ValueError('request serial')
    if type(snapshot) is not list or len(snapshot) != 6:
        raise ValueError('snapshot shape')
    identity, policy, revision, context, choices, prompt = snapshot
    if not isinstance(identity, str) or not identity or not isinstance(policy, str) or not policy:
        raise ValueError('request identity')
    if type(revision) is not int or revision < 0 or type(prompt) is not str:
        raise ValueError('revision or prompt')
    return packet


def decode_request(events):
    """Decode exactly one explicit GM export. No ordinary player events are read."""
    rows = [event for event in events if event['id'].startswith('rpg.gm.')]
    if len(rows) < 3 or rows[0] != {'id': 'rpg.gm.request', 'subjects': [], 'values': [SCHEMA]}:
        raise ValueError('missing request boundary')
    if rows[-1] != {'id': 'rpg.gm.end', 'subjects': [], 'values': []} or len(rows) > LIMIT:
        raise ValueError('missing end boundary')
    at = 1
    def value(depth=0):
        nonlocal at
        if depth > 8 or at >= len(rows) - 1:
            raise ValueError('truncated or nested value')
        row = rows[at]; at += 1
        if row['id'] != 'rpg.gm.value' or row.get('subjects') != [] or len(row['values']) != 2:
            raise ValueError('invalid value event')
        kind, item = row['values']
        if kind == 'list':
            if type(item) is not int or not 0 <= item <= 128:
                raise ValueError('list length')
            return [value(depth + 1) for _ in range(item)]
        valid = ((kind == 'null' and item is None) or (kind == 'bool' and item is True)
                 or (kind == 'int' and type(item) is int) or (kind == 'string' and type(item) is str))
        if not valid:
            raise ValueError('scalar type')
        return item
    packet = value()
    if at != len(rows) - 1:
        raise ValueError('trailing data')
    return validate_packet(packet)


def request_document(packet):
    validate_packet(packet)
    identity, policy, revision, context, choices, prompt = packet[2]
    # JSON round-trip makes a detached, data-only copy for a provider.
    return json.loads(json.dumps(dict(schema=SCHEMA, serial=packet[1], question=identity,
        policy=policy, revision=revision, context=context, choices=choices, prompt=prompt)))


def make_reply(request, status, ruling=None):
    return {key: request[key] for key in ('schema', 'epoch', 'serial', 'question', 'policy', 'revision')} | {
        'status': status, 'ruling': [] if ruling is None else ruling}


class Adjudicator(Protocol):
    """An adapter may use authored rules, a local model, or an OS service.

    A slow implementation runs outside the game worker. On completion it returns
    data; it does not roll dice, inspect native handles, or invoke game actions.
    """
    def adjudicate(self, request: dict) -> dict: ...


class AuthoredAdjudicator:
    def __init__(self, rulings):
        self.rulings = rulings

    def adjudicate(self, request):
        ruling = self.rulings.get(request['question'])
        return make_reply(request, 'unsupported' if ruling is None else 'ruled', ruling)


class Exchange:
    """Host correlation, explicitly reset after restore/undo/session replacement.

    The game performs its own fresh-context and permission validation even after
    this validator accepts a reply. No timeouts are converted into approvals.
    """
    def __init__(self, max_pending=128):
        if type(max_pending) is not int or not 1 <= max_pending <= 4096:
            raise ValueError('pending request limit')
        self.max_pending = max_pending
        self.pending = {}
        self.epoch = uuid4().hex

    def reset(self):
        self.pending.clear()
        self.epoch = uuid4().hex

    def forget(self, serial):
        self.pending.pop(serial, None)

    def register(self, packet):
        request = request_document(packet)
        request['epoch'] = self.epoch
        old = self.pending.get(request['serial'])
        if old is not None and old != request:
            raise ValueError('serial collision: reset exchange on session change')
        if old is None and len(self.pending) >= self.max_pending:
            raise ValueError('pending request limit')
        self.pending[request['serial']] = request
        return json.loads(json.dumps(request))

    def validate(self, reply):
        if type(reply) is not dict or set(reply) != {
            'schema','epoch','serial','question','policy','revision','status','ruling'}:
            raise ValueError('reply fields')
        if type(reply['serial']) is not int or type(reply['schema']) is not int or type(reply['revision']) is not int:
            raise ValueError('reply scalar types')
        request = self.pending.get(reply['serial'])
        if request is None or any(reply[k] != request[k] for k in ('schema','epoch','serial','question','policy','revision')):
            raise ValueError('stale reply')
        if reply['status'] not in ('ruled','needs-input','unsupported'):
            raise ValueError('reply status')
        if data_size(reply['ruling']) > LIMIT or (reply['status'] != 'ruled' and reply['ruling'] != []):
            raise ValueError('invalid ruling data')
        return json.loads(json.dumps(reply))

    def parse(self, text):
        if len(text.encode('utf-8')) > 65536:
            raise ValueError('reply bytes limit')
        def pairs(items):
            result = {}
            for key, value in items:
                if key in result:
                    raise ValueError('duplicate JSON key')
                result[key] = value
            return result
        try:
            value = json.loads(text, object_pairs_hook=pairs)
        except RecursionError as error:
            raise ValueError('JSON nesting limit') from error
        return self.validate(value)
