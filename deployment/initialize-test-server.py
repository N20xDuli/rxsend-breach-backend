#!/usr/bin/env python3
"""Initialize a fresh Linux test installation; never start or overwrite it."""
import argparse
import ipaddress
import json
import os
from pathlib import Path
import re
import secrets
import stat
from datetime import datetime, timezone


def checked_root(value):
    supplied = Path(value).expanduser().absolute()
    resolved = supplied.resolve(strict=True)
    if supplied != resolved or resolved == Path('/') or not resolved.is_dir():
        raise ValueError('Use an existing, non-root installation directory without symlinks.')
    for part in (resolved, *resolved.parents):
        if part.is_symlink():
            raise ValueError('Installation ancestors must not be symlinks.')
    return resolved


def require_local_path(root, relative):
    candidate = root / relative
    if candidate.is_symlink() or candidate.resolve() != candidate:
        raise ValueError(f'Deployment path traverses a symlink: {relative}')
    return candidate


def write_new(path, content):
    descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(descriptor, 'w', encoding='utf-8', newline='\n') as handle:
        handle.write(content)


def ulx_configuration(source):
    match = re.search(r'files\["config\.txt"\]\s*=\s*\[\[(.*?)\]\]', source, re.S)
    if not match:
        raise ValueError('Cannot locate this release\'s ULX default configuration.')
    replacements = {
        'showMotd': '0', 'welcomemessage': '""', 'motdurl': '""',
        'votemapEnabled': '0',
    }
    found = set()
    commands = []
    for raw in match.group(1).splitlines():
        line = raw.split(';', 1)[0].strip()
        if not line:
            continue
        command = line.split(None, 2)
        if len(command) != 3 or command[0] != 'ulx':
            raise ValueError('Unexpected ULX default configuration syntax.')
        if command[1] in replacements:
            line = f'ulx {command[1]} {replacements[command[1]]}'
            found.add(command[1])
        commands.append(line)
    if found != set(replacements):
        raise ValueError('ULX default configuration changed; review before initializing.')
    return '\n'.join(commands) + '\n'


def initialize(args):
    if os.name != 'posix' or not hasattr(os, 'geteuid'):
        raise ValueError('Linux is required.')
    if os.geteuid() == 0:
        raise ValueError('Run initialization as the dedicated service user, not root.')
    os.umask(0o077)
    root = checked_root(args.server_root)
    if root.stat().st_uid != os.geteuid():
        raise ValueError('The service user must own ServerRoot.')
    ipaddress.IPv4Address(args.listen_address)
    if not 1024 <= args.game_port <= 65535:
        raise ValueError('Game port must be between 1024 and 65535.')
    if not 2 <= args.max_players <= 16 or not 1 <= args.minimum_players <= args.max_players:
        raise ValueError('Use 2-16 slots and a valid minimum-player count.')
    if not re.fullmatch(r'[A-Za-z0-9._-]{1,100}', args.release_id):
        raise ValueError('Invalid release identifier.')
    if not re.fullmatch(r'[A-Za-z0-9_-]+', args.map):
        raise ValueError('Invalid map name.')
    if not args.hostname or len(args.hostname) > 100 or re.search(r'[";\x00-\x1f]', args.hostname):
        raise ValueError('Invalid hostname.')
    if (root / '.git').exists():
        raise ValueError('Initialize an independent release, not the source checkout.')
    for relative in ('srcds_run', 'garrysmod/lua/rxsend/database.lua',
                     'garrysmod/lua/rxsend/local_assets.lua',
                     'garrysmod/gamemodes/rxsend_breach/gamemode/shared.lua',
                     f'garrysmod/maps/{args.map}.bsp'):
        if not require_local_path(root, relative).is_file():
            raise ValueError(f'Missing release file: {relative}')
    if not os.access(root / 'srcds_run', os.X_OK):
        raise ValueError('srcds_run is not executable.')
    data = require_local_path(root, 'garrysmod/data')
    if data.exists() and (not data.is_dir() or any(data.iterdir())):
        raise ValueError('DATA is not empty; refusing to replace existing state.')
    for relative in ('.deployment-private', 'garrysmod/sv.db', 'garrysmod/sv.db-wal',
                     'garrysmod/sv.db-shm', 'garrysmod/sv.db-journal',
                     'garrysmod/cfg/rxsend-test.cfg', 'garrysmod/cfg/rxsend-test.private.cfg'):
        if require_local_path(root, relative).exists():
            raise ValueError(f'Existing state or deployment configuration: {relative}')
    cfg = require_local_path(root, 'garrysmod/cfg')
    ulx_source = require_local_path(root, 'garrysmod/addons/[admin]_ulx_ulib/lua/ulx/data.lua')
    ulx_config = ulx_configuration(ulx_source.read_text(encoding='utf-8-sig'))
    if args.game_password_file:
        password_path = Path(args.game_password_file)
        file_stat = password_path.stat()
        if password_path.is_symlink() or not stat.S_ISREG(file_stat.st_mode) or file_stat.st_mode & 0o077:
            raise ValueError('Password input must be a private regular file (0600).')
        game_password = password_path.read_text(encoding='utf-8').strip()
    else:
        game_password = secrets.token_urlsafe(18)
    if not re.fullmatch(r'[A-Za-z0-9_-]{8,64}', game_password):
        raise ValueError('Game password must be 8-64 letters, digits, dash or underscore.')

    private = root / '.deployment-private'
    private.mkdir(mode=0o700)
    (private / 'logs').mkdir(mode=0o700)
    (data / 'rxsend').mkdir(mode=0o700, parents=True)
    (data / 'ulx').mkdir(mode=0o700)
    cfg.mkdir(mode=0o700, exist_ok=True)
    write_new(data / 'rxsend/database.json', '{"development":false,"backend":"sqlite"}\n')
    write_new(data / 'rxsend/local_assets.json', '{"enabled":false}\n')
    write_new(data / 'ulx/config.txt', ulx_config)
    write_new(data / 'ulx/adverts.txt', '')
    write_new(data / 'ulx/banmessage.txt',
              '你已被本服务器封禁。\n\n执行管理员：{{BANNED_BY}}\n封禁原因：{{REASON}}\n剩余时间：{{TIME_LEFT}}\n')
    write_new(data / 'ulx/banreasons.txt', '刷屏\n恶意破坏\n辱骂玩家\n作弊\n违反服务器规则\n')
    write_new(data / 'ulx/gimps.txt', '我会遵守服务器规则。\n')
    rcon_password = secrets.token_hex(32)
    write_new(private / 'rcon.secret', rcon_password + '\n')
    write_new(private / 'join-details.json', json.dumps({
        'password': game_password, 'listen_address': args.listen_address,
        'internal_game_port': args.game_port,
        'note': 'The provider public UDP mapping must be verified separately.',
    }, ensure_ascii=False, indent=2) + '\n')
    write_new(cfg / 'rxsend-test.private.cfg',
              f'rcon_password "{rcon_password}"\nsv_password "{game_password}"\n')
    write_new(cfg / 'rxsend-test.cfg', f'''// Restricted test installation.
hostname "{args.hostname}"
sv_lan 0
sv_allowcslua 0
sv_cheats 0
sv_hibernate_think 1
sv_timeout 120
sv_logecho 1
log on
net_usesocketsforloopback 1
breach_legacy_client_sync 0
awarn_auto_punish 0
br_min_players {args.minimum_players}
br_time_countdown 119
br_time_preparing 60
br_time_round 780
br_time_round_big 1170
br_time_round_event 300
br_time_postround 30
sv_allowdownload 1
sv_allowupload 0
sv_downloadurl ""
exec rxsend-test.private.cfg
''')
    configuration = dict(schema=1, server_root=str(root), release_id=args.release_id,
                         created_utc=datetime.now(timezone.utc).isoformat(),
                         listen_address=args.listen_address, game_port=args.game_port,
                         max_players=args.max_players, minimum_players=args.minimum_players,
                         map=args.map, hostname=args.hostname, hide_server=True)
    write_new(private / 'deployment.json', json.dumps(configuration, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({'initialized': True, 'server_root': str(root), 'release_id': args.release_id,
                      'internal_game_port': args.game_port, 'slots': args.max_players,
                      'join_details_file': str(private / 'join-details.json')}, ensure_ascii=False))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--server-root', default='/srv/rxsend/server')
    parser.add_argument('--game-port', type=int, required=True)
    parser.add_argument('--release-id', required=True)
    parser.add_argument('--listen-address', default='0.0.0.0')
    parser.add_argument('--max-players', type=int, default=16)
    parser.add_argument('--minimum-players', type=int, default=2)
    parser.add_argument('--map', default='rxsend_site19-1')
    parser.add_argument('--hostname', default='RXSend 收容突破 · 测试服')
    parser.add_argument('--game-password-file')
    args = parser.parse_args()
    try:
        initialize(args)
    except (OSError, ValueError) as error:
        parser.exit(1, f'Initialization refused: {error}\n')


if __name__ == '__main__':
    main()
