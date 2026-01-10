#!/usr/bin/env python3
"""
pi_codesign.py - Standalone PixInsight code signing tool

Signs PixInsight scripts (.js, .scp) and XML files (.xri) using Ed25519.

Usage:
    # Using pre-extracted JSON keys (from DumpKeys.js):
    ./pi_codesign.py --keys ~/.pi_signing_keys.json <files...>

    # Keys file format (JSON):
    {
      "developerId": "username",
      "publicKey": "hex...",
      "privateKey": "hex..."
    }

To extract keys, run DumpKeys.js in PixInsight first.
"""

import argparse
import base64
import hashlib
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

try:
    from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
    HAVE_CRYPTO = True
except ImportError:
    HAVE_CRYPTO = False


def load_json_keys(json_path: str) -> dict:
    """Load signing keys from JSON file (extracted by DumpKeys.js)"""
    with open(json_path, 'r') as f:
        data = json.load(f)

    if 'developerId' not in data or 'privateKey' not in data:
        raise ValueError("Invalid keys file: missing developerId or privateKey")

    return {
        'developer_id': data['developerId'],
        'public_key': bytes.fromhex(data.get('publicKey', '')),
        'private_key': bytes.fromhex(data['privateKey']),
    }


def extract_script_id(script_path: str) -> str:
    """Extract #script-id from a JavaScript file"""
    with open(script_path, 'r', encoding='utf-8') as f:
        content = f.read()

    match = re.search(r'#script-id\s+(\S+)', content)
    if match:
        return match.group(1)

    # Fallback to filename without extension
    return Path(script_path).stem


def canonicalize_script(script_path: str) -> bytes:
    """
    Canonicalize script for signing.
    PixInsight normalizes line endings to LF.
    """
    with open(script_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Normalize line endings to LF
    content = content.replace('\r\n', '\n').replace('\r', '\n')

    return content.encode('utf-8')


def sign_data(private_key_bytes: bytes, data: bytes) -> bytes:
    """Sign data with Ed25519 private key"""
    # Ed25519 private key: 32 bytes (seed) or 64 bytes (seed + public key)
    if len(private_key_bytes) == 64:
        # Seed is first 32 bytes
        seed = private_key_bytes[:32]
    elif len(private_key_bytes) == 32:
        seed = private_key_bytes
    else:
        raise ValueError(f"Invalid private key length: {len(private_key_bytes)}")

    private_key = Ed25519PrivateKey.from_private_bytes(seed)
    return private_key.sign(data)


def sign_script(keys: dict, script_path: str, entitlements: list = None) -> str:
    """Sign a script file and return the signature XML"""
    script_id = extract_script_id(script_path)
    developer_id = keys['developer_id']
    now = datetime.now(timezone.utc)
    timestamp = now.strftime('%Y-%m-%dT%H:%M:%S.') + f"{now.microsecond // 1000:03d}Z"

    # Canonicalize script
    script_content = canonicalize_script(script_path)

    # Build message to sign
    # Format: scriptId + developerId + timestamp + script + entitlements
    message_parts = [
        script_id.encode('utf-8'),
        developer_id.encode('utf-8'),
        timestamp.encode('utf-8'),
        script_content,
    ]

    if entitlements:
        for e in entitlements:
            message_parts.append(e.encode('utf-8'))

    # Hash the message with SHA-512
    full_message = b''.join(message_parts)
    message_hash = hashlib.sha512(full_message).digest()

    # Sign the hash
    signature = sign_data(keys['private_key'], message_hash)
    signature_b64 = base64.b64encode(signature).decode('ascii')

    # Build XML output
    xml_content = f'''<?xml version="1.0" encoding="UTF-8"?>
<!--
PixInsight XML Code Signature Format - XSGN version 1.0
Created with pi_codesign.py - https://pixinsight.com/
-->
<xsgn version="1.0" xmlns="http://www.pixinsight.com/xsgn" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.pixinsight.com/xsgn http://pixinsight.com/xsgn/xsgn-1.0.xsd">
   <CreationTime>{timestamp}</CreationTime>
   <Signature version="1.0" scriptId="{script_id}" developerId="{developer_id}">
      <Timestamp>{timestamp}</Timestamp>
      <CodeSignature encoding="Base64">{signature_b64}</CodeSignature>
   </Signature>
</xsgn>
'''
    return xml_content


def sign_xri(keys: dict, xri_path: str) -> bool:
    """Sign an XRI file by adding/updating signature element.

    PixInsight XRI files have signature OUTSIDE the root element:
    </xri>
    <Signature ...>...</Signature>
    """
    developer_id = keys['developer_id']
    now = datetime.now(timezone.utc)
    timestamp = now.strftime('%Y-%m-%dT%H:%M:%S.') + f"{now.microsecond // 1000:03d}Z"

    # Read the XRI file as text
    with open(xri_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove existing signature if present (it's after </xri>)
    content_clean = re.sub(r'\s*<Signature[^>]*>.*?</Signature>\s*$', '', content, flags=re.DOTALL)
    content_clean = content_clean.rstrip() + '\n'

    # Build message to sign (XRI content without signature)
    message_parts = [
        developer_id.encode('utf-8'),
        timestamp.encode('utf-8'),
        content_clean.encode('utf-8'),
    ]

    full_message = b''.join(message_parts)
    message_hash = hashlib.sha512(full_message).digest()

    # Sign
    signature = sign_data(keys['private_key'], message_hash)
    signature_b64 = base64.b64encode(signature).decode('ascii')

    # Build signature element (outside root, PixInsight style)
    sig_line = f'<Signature developerId="{developer_id}" timestamp="{timestamp}" encoding="Base64">{signature_b64}</Signature>'

    # Write back: content + signature after closing tag
    with open(xri_path, 'w', encoding='utf-8') as f:
        f.write(content_clean)
        f.write(sig_line)

    return True


def main():
    parser = argparse.ArgumentParser(
        description='Standalone PixInsight code signing tool',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  # Sign scripts using extracted keys:
  %(prog)s -k ~/.pi_signing_keys.json src/*.js

  # Extract keys first by running DumpKeys.js in PixInsight
'''
    )
    parser.add_argument('--keys', '-k', required=True,
                       help='Path to JSON keys file (from DumpKeys.js)')
    parser.add_argument('files', nargs='+', help='Files to sign')
    parser.add_argument('--debug', '-d', action='store_true', help='Debug mode')
    args = parser.parse_args()

    if not HAVE_CRYPTO:
        print("Error: cryptography library required")
        print("Install with: pip install cryptography")
        sys.exit(1)

    # Load keys
    print(f"Loading keys from: {args.keys}")
    try:
        keys = load_json_keys(args.keys)
        print(f"Developer ID: {keys['developer_id']}")
        if args.debug:
            print(f"Public key length: {len(keys['public_key'])} bytes")
            print(f"Private key length: {len(keys['private_key'])} bytes")
    except FileNotFoundError:
        print(f"Error: Keys file not found: {args.keys}")
        print("\nTo create keys file:")
        print("  1. Run DumpKeys.js in PixInsight")
        print("  2. Move the output to ~/.pi_signing_keys.json")
        sys.exit(1)
    except Exception as e:
        print(f"Error loading keys: {e}")
        sys.exit(1)

    # Sign each file
    succeeded = 0
    failed = 0

    for filepath in args.files:
        if not os.path.exists(filepath):
            print(f"Warning: File not found: {filepath}")
            failed += 1
            continue

        ext = os.path.splitext(filepath)[1].lower()

        try:
            if ext in ('.js', '.scp', '.jsh'):
                print(f"Signing: {filepath}")
                signature_xml = sign_script(keys, filepath)
                sig_path = os.path.splitext(filepath)[0] + '.xsgn'
                with open(sig_path, 'w', encoding='utf-8') as f:
                    f.write(signature_xml)
                print(f"  Created: {sig_path}")
                succeeded += 1

            elif ext == '.xri':
                print(f"Signing XRI: {filepath}")
                sign_xri(keys, filepath)
                print(f"  Signed: {filepath}")
                succeeded += 1

            else:
                print(f"Unknown file type: {filepath}")
                failed += 1

        except Exception as e:
            print(f"  Error: {e}")
            failed += 1
            if args.debug:
                import traceback
                traceback.print_exc()

    print(f"\nResults: {succeeded} succeeded, {failed} failed")
    sys.exit(0 if failed == 0 else 1)


if __name__ == '__main__':
    main()
