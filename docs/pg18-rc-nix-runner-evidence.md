# PG18 RC1 Nix Runner Evidence

## Host state

- Host command `nix`: not present on PATH.
- Policy: Nix was not installed on host without explicit authorization.

## Container runner probe

```text
== nix container runner probe ==
Unable to find image 'nixos/nix:latest' locally
latest: Pulling from nixos/nix
32e601cdc7fa: Pulling fs layer
ea6169bb3d46: Pulling fs layer
bc3d7b1e1030: Pulling fs layer
594f717abc59: Pulling fs layer
ec10d2b7910c: Pulling fs layer
f44023ca1850: Pulling fs layer
09f1e18c6fe6: Pulling fs layer
ec312a25e058: Pulling fs layer
594f717abc59: Waiting
f44023ca1850: Waiting
dcf06b678516: Pulling fs layer
09f1e18c6fe6: Waiting
ec10d2b7910c: Waiting
ec312a25e058: Waiting
dcf06b678516: Waiting
6251c5ec7b43: Pulling fs layer
b6b0e6c0f68e: Pulling fs layer
5dc4a74d5cec: Pulling fs layer
6251c5ec7b43: Waiting
58865ecf2072: Pulling fs layer
b6b0e6c0f68e: Waiting
5dc4a74d5cec: Waiting
7807cfe20cdb: Pulling fs layer
58865ecf2072: Waiting
0c63dd7dcb2d: Pulling fs layer
7807cfe20cdb: Waiting
1872c791f5b1: Pulling fs layer
0c63dd7dcb2d: Waiting
f6ae56c34d89: Pulling fs layer
f88fd4f6ec86: Pulling fs layer
2e121bb83151: Pulling fs layer
f6ae56c34d89: Waiting
f88fd4f6ec86: Waiting
07a5402454cb: Pulling fs layer
2e121bb83151: Waiting
1f5c15505828: Pulling fs layer
07a5402454cb: Waiting
9e3a618c4271: Pulling fs layer
1f5c15505828: Waiting
d91d266b0c1b: Pulling fs layer
22c7d97b911d: Pulling fs layer
d91d266b0c1b: Waiting
c1c0d8a98d6f: Pulling fs layer
22c7d97b911d: Waiting
cf6ad4bce7bc: Pulling fs layer
e2c57edd132d: Pulling fs layer
c1c0d8a98d6f: Waiting
d85e68a85334: Pulling fs layer
cf6ad4bce7bc: Waiting
32059865c060: Pulling fs layer
d85e68a85334: Waiting
32059865c060: Waiting
29d03d5bc28a: Pulling fs layer
860acc1e704c: Pulling fs layer
e10389e3029d: Pulling fs layer
29d03d5bc28a: Waiting
774eef6b3662: Pulling fs layer
e10389e3029d: Waiting
860acc1e704c: Waiting
ba174ecc3d99: Pulling fs layer
36a44da3b04b: Pulling fs layer
ba174ecc3d99: Waiting
42ea76084e80: Pulling fs layer
36a44da3b04b: Waiting
42ea76084e80: Waiting
db662ad53859: Pulling fs layer
644f15b0c985: Pulling fs layer
dafa48047230: Pulling fs layer
f4428044bdad: Pulling fs layer
db662ad53859: Waiting
644f15b0c985: Waiting
dafa48047230: Waiting
eaa25811c1c8: Pulling fs layer
f4428044bdad: Waiting
2a2cd9d7d78c: Pulling fs layer
eaa25811c1c8: Waiting
c32385b9ee3a: Pulling fs layer
2a2cd9d7d78c: Waiting
b6a33318a02b: Pulling fs layer
c32385b9ee3a: Waiting
e5b48b0c2ae4: Pulling fs layer
b6a33318a02b: Waiting
843616d586f9: Pulling fs layer
e5b48b0c2ae4: Waiting
510969890832: Pulling fs layer
843616d586f9: Waiting
510969890832: Waiting
81a229a3e2bd: Pulling fs layer
433fc54a19b4: Pulling fs layer
81a229a3e2bd: Waiting
433fc54a19b4: Waiting
da42a763430e: Pulling fs layer
61aa42971e75: Pulling fs layer
da42a763430e: Waiting
d35d97de6636: Pulling fs layer
436251ef77a5: Pulling fs layer
ffe24b8b826a: Pulling fs layer
d35d97de6636: Waiting
436251ef77a5: Waiting
b3871ebe7035: Pulling fs layer
a7ee6ad148eb: Pulling fs layer
b3871ebe7035: Waiting
67505dc3d906: Pulling fs layer
a7ee6ad148eb: Waiting
6af9e13c797a: Pulling fs layer
54d211734a74: Pulling fs layer
67505dc3d906: Waiting
6af9e13c797a: Waiting
064fef95ad1e: Pulling fs layer
54d211734a74: Waiting
0d49f873f51c: Pulling fs layer
4989cec31911: Pulling fs layer
064fef95ad1e: Waiting
c88db10c2799: Pulling fs layer
0d49f873f51c: Waiting
4989cec31911: Waiting
d563a417996f: Pulling fs layer
c88db10c2799: Waiting
011b19fba244: Pulling fs layer
ae2618316aae: Pulling fs layer
011b19fba244: Waiting
d563a417996f: Waiting
729d6da1079b: Pulling fs layer
ae2618316aae: Waiting
d097a4aaf880: Pulling fs layer
b6b0537a28ee: Pulling fs layer
729d6da1079b: Waiting
d097a4aaf880: Waiting
b6b0537a28ee: Waiting
32e601cdc7fa: Verifying Checksum
32e601cdc7fa: Download complete
32e601cdc7fa: Pull complete
ea6169bb3d46: Download complete
ea6169bb3d46: Pull complete
bc3d7b1e1030: Download complete
bc3d7b1e1030: Pull complete
ec10d2b7910c: Verifying Checksum
ec10d2b7910c: Download complete
f44023ca1850: Verifying Checksum
f44023ca1850: Download complete
09f1e18c6fe6: Verifying Checksum
09f1e18c6fe6: Download complete
ec312a25e058: Download complete
594f717abc59: Verifying Checksum
594f717abc59: Download complete
dcf06b678516: Verifying Checksum
dcf06b678516: Download complete
6251c5ec7b43: Verifying Checksum
6251c5ec7b43: Download complete
5dc4a74d5cec: Verifying Checksum
5dc4a74d5cec: Download complete
594f717abc59: Pull complete
58865ecf2072: Verifying Checksum
58865ecf2072: Download complete
ec10d2b7910c: Pull complete
7807cfe20cdb: Verifying Checksum
7807cfe20cdb: Download complete
f44023ca1850: Pull complete
09f1e18c6fe6: Pull complete
ec312a25e058: Pull complete
0c63dd7dcb2d: Download complete
1872c791f5b1: Download complete
dcf06b678516: Pull complete
6251c5ec7b43: Pull complete
f6ae56c34d89: Verifying Checksum
f6ae56c34d89: Download complete
b6b0e6c0f68e: Pull complete
5dc4a74d5cec: Pull complete
58865ecf2072: Pull complete
2e121bb83151: Verifying Checksum
2e121bb83151: Download complete
f88fd4f6ec86: Verifying Checksum
f88fd4f6ec86: Download complete
7807cfe20cdb: Pull complete
07a5402454cb: Verifying Checksum
07a5402454cb: Download complete
0c63dd7dcb2d: Pull complete
1872c791f5b1: Pull complete
f6ae56c34d89: Pull complete
9e3a618c4271: Verifying Checksum
9e3a618c4271: Download complete
1f5c15505828: Verifying Checksum
1f5c15505828: Download complete
f88fd4f6ec86: Pull complete
d91d266b0c1b: Download complete
2e121bb83151: Pull complete
07a5402454cb: Pull complete
22c7d97b911d: Verifying Checksum
22c7d97b911d: Download complete
1f5c15505828: Pull complete
cf6ad4bce7bc: Verifying Checksum
cf6ad4bce7bc: Download complete
c1c0d8a98d6f: Download complete
32059865c060: Verifying Checksum
32059865c060: Download complete
860acc1e704c: Verifying Checksum
860acc1e704c: Download complete
29d03d5bc28a: Verifying Checksum
29d03d5bc28a: Download complete
e10389e3029d: Verifying Checksum
e10389e3029d: Download complete
d85e68a85334: Verifying Checksum
d85e68a85334: Download complete
774eef6b3662: Verifying Checksum
774eef6b3662: Download complete
9e3a618c4271: Pull complete
d91d266b0c1b: Pull complete
ba174ecc3d99: Verifying Checksum
ba174ecc3d99: Download complete
36a44da3b04b: Verifying Checksum
36a44da3b04b: Download complete
22c7d97b911d: Pull complete
42ea76084e80: Verifying Checksum
42ea76084e80: Download complete
c1c0d8a98d6f: Pull complete
db662ad53859: Verifying Checksum
db662ad53859: Download complete
644f15b0c985: Verifying Checksum
644f15b0c985: Download complete
cf6ad4bce7bc: Pull complete
dafa48047230: Verifying Checksum
dafa48047230: Download complete
f4428044bdad: Verifying Checksum
f4428044bdad: Download complete
e2c57edd132d: Pull complete
eaa25811c1c8: Verifying Checksum
eaa25811c1c8: Download complete
c32385b9ee3a: Verifying Checksum
c32385b9ee3a: Download complete
d85e68a85334: Pull complete
2a2cd9d7d78c: Verifying Checksum
2a2cd9d7d78c: Download complete
32059865c060: Pull complete
b6a33318a02b: Download complete
29d03d5bc28a: Pull complete
860acc1e704c: Pull complete
e5b48b0c2ae4: Verifying Checksum
e5b48b0c2ae4: Download complete
843616d586f9: Verifying Checksum
843616d586f9: Download complete
e10389e3029d: Pull complete
510969890832: Verifying Checksum
510969890832: Download complete
774eef6b3662: Pull complete
81a229a3e2bd: Verifying Checksum
81a229a3e2bd: Download complete
433fc54a19b4: Verifying Checksum
433fc54a19b4: Download complete
ba174ecc3d99: Pull complete
da42a763430e: Verifying Checksum
da42a763430e: Download complete
36a44da3b04b: Pull complete
d35d97de6636: Verifying Checksum
d35d97de6636: Download complete
436251ef77a5: Verifying Checksum
42ea76084e80: Pull complete
61aa42971e75: Download complete
db662ad53859: Pull complete
b3871ebe7035: Verifying Checksum
b3871ebe7035: Download complete
ffe24b8b826a: Verifying Checksum
ffe24b8b826a: Download complete
644f15b0c985: Pull complete
67505dc3d906: Verifying Checksum
67505dc3d906: Download complete
dafa48047230: Pull complete
6af9e13c797a: Verifying Checksum
6af9e13c797a: Download complete
f4428044bdad: Pull complete
a7ee6ad148eb: Verifying Checksum
a7ee6ad148eb: Download complete
eaa25811c1c8: Pull complete
064fef95ad1e: Verifying Checksum
064fef95ad1e: Download complete
2a2cd9d7d78c: Pull complete
0d49f873f51c: Verifying Checksum
0d49f873f51c: Download complete
54d211734a74: Verifying Checksum
54d211734a74: Download complete
c32385b9ee3a: Pull complete
4989cec31911: Verifying Checksum
4989cec31911: Download complete
b6a33318a02b: Pull complete
c88db10c2799: Verifying Checksum
c88db10c2799: Download complete
011b19fba244: Verifying Checksum
011b19fba244: Download complete
d563a417996f: Download complete
e5b48b0c2ae4: Pull complete
843616d586f9: Pull complete
510969890832: Pull complete
d097a4aaf880: Download complete
81a229a3e2bd: Pull complete
b6b0537a28ee: Verifying Checksum
b6b0537a28ee: Download complete
729d6da1079b: Verifying Checksum
729d6da1079b: Download complete
433fc54a19b4: Pull complete
ae2618316aae: Verifying Checksum
ae2618316aae: Download complete
da42a763430e: Pull complete
61aa42971e75: Pull complete
d35d97de6636: Pull complete
436251ef77a5: Pull complete
ffe24b8b826a: Pull complete
b3871ebe7035: Pull complete
a7ee6ad148eb: Pull complete
67505dc3d906: Pull complete
6af9e13c797a: Pull complete
54d211734a74: Pull complete
064fef95ad1e: Pull complete
0d49f873f51c: Pull complete
4989cec31911: Pull complete
c88db10c2799: Pull complete
d563a417996f: Pull complete
011b19fba244: Pull complete
ae2618316aae: Pull complete
729d6da1079b: Pull complete
d097a4aaf880: Pull complete
b6b0537a28ee: Pull complete
Digest: sha256:bf1d938835ab96312f098fa6c2e9cab367728e0aad0646ee3e02a787c80d8fb8
Status: Downloaded newer image for nixos/nix:latest
nix (Nix) 2.34.7
/root/.nix-profile/bin/bash
/root/.nix-profile/bin/git
PATH=/root/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin
```

## Docker CLI inside Nix runner attempt

Attempted to use `nix shell nixpkgs#docker-client` inside `nixos/nix:latest` with the host Docker socket mounted.

Result: blocked by upstream GitHub/nixpkgs timeout before Docker CLI could be acquired.

```text
== nix container docker-client probe ==
warning: unable to download 'https://api.github.com/repos/NixOS/nixpkgs/commits/nixpkgs-unstable': Timeout was reached (28) Connection timed out after 15001 milliseconds; retrying in 264 ms (attempt 1/5)
warning: unable to download 'https://api.github.com/repos/NixOS/nixpkgs/commits/nixpkgs-unstable': Timeout was reached (28) Connection timed out after 15000 milliseconds; retrying in 528 ms (attempt 2/5)
warning: unable to download 'https://api.github.com/repos/NixOS/nixpkgs/commits/nixpkgs-unstable': Timeout was reached (28) Connection timed out after 15000 milliseconds; retrying in 1279 ms (attempt 3/5)
warning: unable to download 'https://api.github.com/repos/NixOS/nixpkgs/commits/nixpkgs-unstable': Timeout was reached (28) Connection timed out after 15000 milliseconds; retrying in 2137 ms (attempt 4/5)
error:
       … while fetching the input 'github:NixOS/nixpkgs/nixpkgs-unstable'

       error: unable to download 'https://api.github.com/repos/NixOS/nixpkgs/commits/nixpkgs-unstable': Timeout was reached (28) Connection timed out after 15001 milliseconds
```

## Verdict

`FULL_VALIDATE_ON_NIX_RUNNER`: BLOCKED/WARN in this local session.

The Dockerfile-Nix build path was already proven by the prior release-readiness slice and RC1 was smoke-tested. Full Nix runner proof remains the first external/runner gate before formal public release.
