#!/usr/bin/env python3
"""Local RCON for a systemd-managed test server; no credential CLI arguments."""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import socket
import struct
import time

# Conservative tool guard, not a measured limit for every GMod build. Valve's
# SDK uses a 512-byte CCommand buffer but Tokenize rejects length >= 511:
# https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/tier1/convar.cpp
MAX_COMMAND_BYTES = 510


def packet(identifier, kind, text):
    payload = struct.pack('<ii', identifier, kind) + text.encode('utf-8') + b'\0\0'
    return struct.pack('<i', len(payload)) + payload


def exact(sock, length):
    chunks = bytearray()
    while len(chunks) < length:
        data = sock.recv(length - len(chunks))
        if not data:
            raise ConnectionError('RCON connection closed.')
        chunks.extend(data)
    return bytes(chunks)


def read_packet(sock):
    length = struct.unpack('<i', exact(sock, 4))[0]
    if not 10 <= length <= 4 * 1024 * 1024:
        raise ValueError('Invalid RCON packet size.')
    payload = exact(sock, length)
    if payload[-2:] != b'\0\0':
        raise ValueError('Invalid RCON packet terminator.')
    identifier, kind = struct.unpack('<ii', payload[:8])
    return identifier, kind, payload[8:-2].decode('utf-8', errors='replace')


def rcon(address, port, password, command):
    command_bytes = len(command.encode('utf-8'))
    if command_bytes > MAX_COMMAND_BYTES:
        raise ValueError(
            f'Command is {command_bytes} UTF-8 bytes; this tool allows at most '
            f'{MAX_COMMAND_BYTES}. Use shorter commands or an explicit server-side '
            'script. The command was not sent.'
        )
    with socket.create_connection((address, port), timeout=5) as sock:
        sock.settimeout(10)
        sock.sendall(packet(1, 3, password))
        for _ in range(4):
            identifier, kind, _ = read_packet(sock)
            if kind == 2:
                if identifier != 1:
                    raise ValueError('RCON authentication failed.')
                break
        else:
            raise ValueError('RCON authentication response missing.')
        sock.sendall(packet(2, 2, command))
        if command == 'quit':
            return ''
        sock.sendall(packet(3, 2, 'echo RX_DEPLOYMENT_RCON_END'))
        result = []
        for _ in range(4096):
            identifier, _, text = read_packet(sock)
            if identifier == 3:
                return ''.join(result).rstrip()
            if identifier == 2:
                result.append(text)
        raise ValueError('RCON response exceeded packet limit.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('status', 'command', 'stop'))
    parser.add_argument('command', nargs='?')
    parser.add_argument('--server-root', default='/srv/rxsend/server')
    parser.add_argument('--wait-pid', type=int)
    parser.add_argument('--timeout', type=int, default=60)
    args = parser.parse_args()
    if args.action == 'command' and not args.command:
        parser.error('Supply the console command as one quoted argument.')
    if args.wait_pid is not None and (args.wait_pid <= 1 or args.action != 'stop'):
        parser.error('--wait-pid is only valid for stop and must be greater than 1.')
    if not 1 <= args.timeout <= 120:
        parser.error('--timeout must be 1-120 seconds.')
    spec = importlib.util.spec_from_file_location('rx_deployment', Path(__file__).with_name('run-test-server.py'))
    helper = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(helper)
    root = Path(args.server_root).resolve(strict=True)
    private = root / '.deployment-private'
    config = json.loads(helper.private_text(private / 'deployment.json'))
    if config.get('schema') != 1 or config.get('server_root') != str(root):
        raise ValueError('Deployment identity mismatch.')
    password = helper.private_text(private / 'rcon.secret').strip()
    address = '127.0.0.1' if config['listen_address'] == '0.0.0.0' else config['listen_address']
    command = {'status': 'status', 'stop': 'quit'}.get(args.action, args.command)
    response = rcon(address, config['game_port'], password, command)
    if response:
        print(response)
    if args.action == 'stop' and args.wait_pid:
        deadline = time.monotonic() + args.timeout
        while time.monotonic() < deadline:
            try:
                os.kill(args.wait_pid, 0)
            except ProcessLookupError:
                print('Server exited after quit.')
                return
            time.sleep(0.25)
        raise TimeoutError('Server did not finish shutting down after quit; no process was killed by this tool.')


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, KeyError) as error:
        raise SystemExit(f'Server control failed: {error}')
