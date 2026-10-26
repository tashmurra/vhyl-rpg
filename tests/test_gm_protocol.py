import importlib.util
import json
from pathlib import Path
import unittest

path = Path(__file__).resolve().parents[1] / 'hosts/vhyl_gm.py'
spec = importlib.util.spec_from_file_location('vhyl_gm', path)
gm = importlib.util.module_from_spec(spec); spec.loader.exec_module(gm)

class GmProtocolTests(unittest.TestCase):
    def setUp(self):
        self.packet = [1, 7, ['cast', 'magic-1', 2, [['light', True]], [['redirect']], 'redirect light']]
        self.exchange = gm.Exchange()
        self.request = self.exchange.register(self.packet)

    def test_detached_correlation_and_reset(self):
        self.request['context'].append('untrusted edit')
        reply = gm.make_reply(self.request, 'ruled', ['redirect','subtle',0,'Reason'])
        self.assertEqual(self.exchange.validate(reply), reply)
        self.assertNotIn('untrusted edit', self.exchange.pending[7]['context'])
        self.exchange.reset()
        with self.assertRaises(ValueError): self.exchange.validate(reply)
        self.exchange.register(self.packet)
        with self.assertRaises(ValueError): self.exchange.validate(reply)

    def test_pending_bound(self):
        exchange = gm.Exchange(max_pending=1)
        exchange.register(self.packet)
        with self.assertRaises(ValueError): exchange.register([1, 8, self.packet[2]])
        exchange.forget(7)
        exchange.register([1, 8, self.packet[2]])

    def test_bad_reply_cannot_inject_fields_types_or_values(self):
        good = gm.make_reply(self.request, 'ruled', [])
        for field, value in [('schema', True), ('serial', True), ('revision', 3),
                             ('policy','other'), ('question','other'), ('status','approved')]:
            with self.subTest(field=field), self.assertRaises(ValueError):
                self.exchange.validate(good | {field:value})
        with self.assertRaises(ValueError): self.exchange.validate(good | {'code':'run me'})
        for value in [{'callback':'anything'}, [False], [[None]*128, [None]*128], ['x'*9000], [[[[[[[[[[]]]]]]]]]]]:
            with self.assertRaises(ValueError): self.exchange.validate(good | {'ruling':value})
        with self.assertRaises(ValueError): self.exchange.parse(json.dumps(good)[:-1] + ',"schema":1}')
        with self.assertRaises(ValueError): self.exchange.validate(good | {'status':'unsupported','ruling':[1]})
        with self.assertRaises(ValueError): self.exchange.parse('[' * 2000 + '0' + ']' * 2000)
        with self.assertRaises(ValueError): self.exchange.validate(good | {'ruling':[chr(0xD800)]})

    def test_authored_provider_and_unknown(self):
        p = gm.AuthoredAdjudicator({'cast':['redirect','subtle',0,'Known']})
        self.assertEqual(self.exchange.validate(p.adjudicate(self.request))['status'],'ruled')
        self.assertEqual(gm.AuthoredAdjudicator({}).adjudicate(self.request)['status'],'unsupported')

    def test_scalar_event_transport(self):
        def event(name,values): return dict(id=name,subjects=[],values=values)
        rows=[event('rpg.gm.request',[1])]
        def emit(v):
            kind = 'null' if v is None else 'bool' if v is True else 'list' if type(v) is list else 'int' if type(v) is int else 'string'
            rows.append(event('rpg.gm.value',[kind,len(v) if type(v) is list else v]))
            if type(v) is list:
                for item in v: emit(item)
        emit(self.packet); rows.append(event('rpg.gm.end',[]))
        self.assertEqual(gm.decode_request(rows),self.packet)
        with self.assertRaises(ValueError): gm.decode_request(rows[:-2]+rows[-1:])
        with self.assertRaises(ValueError): gm.decode_request(rows+rows)
        with self.assertRaises(ValueError): gm.decode_request(rows[:-1]+[event('rpg.gm.value',['int',4])]+rows[-1:])
