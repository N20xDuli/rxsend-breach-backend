#!/usr/bin/env python3
"""Validate the initialized instance and exec srcds_run under systemd."""
import ipaddress
import json
import os
from pathlib import Path
import re
import shutil
import socket
import stat
from datetime import datetime, timezone


def private_text(path):
    info = path.stat()
    if path.is_symlink() or not stat.S_ISREG(info.st_mode) or info.st_mode & 0o077 or info.st_uid != os.geteuid():
        raise ValueError(f'Expected a service-owned private file: {path.name}')
    return path.read_text(encoding='utf-8')


def main():
    if os.name != 'posix' or os.geteuid() == 0:
        raise ValueError('Run as the dedicated, unprivileged service user.')
    root = Path(__file__).resolve().parents[2]
    private = root / '.deployment-private'
    # Keep the inherited descriptor open for the lifetime of srcds_run and its
    # child. A second manual launch must not race systemd or reuse this DATA.
    import fcntl
    lock_fd = os.open(private / 'instance.lock', os.O_RDWR | os.O_CREAT | os.O_NOFOLLOW, 0o600)
    try:
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        os.close(lock_fd)
        raise ValueError('This installation already has a running launcher.')
    os.set_inheritable(lock_fd, True)
    config = json.loads(private_text(private / 'deployment.json'))
    if config.get('schema') != 1 or config.get('server_root') != str(root) or config.get('hide_server') is not True:
        raise ValueError('Deployment identity does not match this installation.')
    ipaddress.IPv4Address(config['listen_address'])
    if not isinstance(config['game_port'], int) or not 1024 <= config['game_port'] <= 65535:
        raise ValueError('Invalid game port.')
    if not isinstance(config['max_players'], int) or not 2 <= config['max_players'] <= 16:
        raise ValueError('Invalid test-server capacity.')
    if not re.fullmatch(r'[A-Za-z0-9_-]+', config['map']):
        raise ValueError('Invalid map name.')
    database = json.loads(private_text(root / 'garrysmod/data/rxsend/database.json'))
    assets = json.loads(private_text(root / 'garrysmod/data/rxsend/local_assets.json'))
    if database.get('development') is not False or database.get('backend') != 'sqlite' or assets.get('enabled') is not False:
        raise ValueError('Expected non-development SQLite and normal resource distribution.')
    secret = private_text(private / 'rcon.secret').strip()
    private_cfg = private_text(root / 'garrysmod/cfg/rxsend-test.private.cfg')
    if not re.fullmatch(r'[a-f0-9]{64}', secret) or f'rcon_password "{secret}"' not in private_cfg.splitlines():
        raise ValueError('RCON configuration is inconsistent.')
    if not re.search(r'^sv_password "[A-Za-z0-9_-]{8,64}"$', private_cfg, re.M):
        raise ValueError('A private game password is required.')
    public_cfg = private_text(root / 'garrysmod/cfg/rxsend-test.cfg')
    for required in ('sv_lan 0', 'sv_allowcslua 0', 'sv_cheats 0', 'awarn_auto_punish 0',
                     'breach_legacy_client_sync 0', 'exec rxsend-test.private.cfg'):
        if required not in public_cfg.splitlines():
            raise ValueError('Required test configuration is missing.')
    engine = root / 'srcds_run'
    if engine.is_symlink() or not os.access(engine, os.X_OK):
        raise ValueError('srcds_run is missing or not executable.')
    if not (root / 'garrysmod/maps' / (config['map'] + '.bsp')).is_file():
        raise ValueError('Configured map is absent.')
    # Refuse a conflicting listener instead of relying on engine fallback ports.
    for kind in (socket.SOCK_STREAM, socket.SOCK_DGRAM):
        with socket.socket(socket.AF_INET, kind) as probe:
            if kind == socket.SOCK_STREAM:
                probe.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            probe.bind((config['listen_address'], config['game_port']))
    os.umask(0o077)
    old_log = root / 'garrysmod/console.log'
    if old_log.exists():
        if old_log.is_symlink():
            raise ValueError('Refusing a linked console log.')
        stamp = datetime.now(timezone.utc).strftime('%Y%m%d-%H%M%S-%f')
        shutil.copyfile(old_log, private / 'logs' / f'console-{stamp}.log')
    arguments = [str(engine), '-norestart', '-console', '-game', 'garrysmod',
                 '-ip', config['listen_address'], '-port', str(config['game_port']),
                 '-condebug', '-conclearlog', '+net_usesocketsforloopback', '1',
                 '+hide_server', '1', '+exec', 'rxsend-test.private.cfg',
                 '+servercfgfile', 'rxsend-test.cfg', '+maxplayers', str(config['max_players']),
                 '+gamemode', 'rxsend_breach', '+map', config['map']]
    os.chdir(root)
    os.execv(engine, arguments)


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, KeyError) as error:
        raise SystemExit(f'Test server startup refused: {error}')
