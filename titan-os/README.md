# TitanOS

A small, fast, **two-mode** Linux distribution built with Debian
[`live-build`](https://www.debian.org/devel/debian-live/). It boots into a
lightweight Openbox desktop and switches, at runtime, between:

- **Gaming mode** — Wine + Steam (Proton) to run Windows games and `setup.exe`
  installers, GameMode for performance, no desktop bloat.
- **Dev mode** — the important tools for coding, proofing, and testing (git,
  Python, Node, GCC/Make, gdb/valgrind, editors, optional Docker).

It is tuned to be usable on a **2 GB RAM** machine: minimal base, Openbox
instead of GNOME/KDE, `zram` compressed swap, and per-mode kernel tunables.

---

## ⚠️ Honest expectations (read this)

TitanOS itself is tiny and runs in ~2 GB RAM. **The games and IDEs you run on
top of it are not.** A 2 GB machine can play older/lightweight Windows titles
through Proton/Wine, but modern AAA games need 8–16 GB RAM and a real GPU no
matter how light the OS is — that's the game's requirement, not the OS's.
TitanOS gives you the leanest possible base so the maximum RAM is left for your
game or build. It does not make a heavy game fit in a small machine.

Nobody builds a distro from zero — TitanOS stands on Debian, exactly like every
real gaming distro (Bazzite, Nobara, SteamOS) stands on an existing base.

---

## Build the ISO

On a Debian or Ubuntu host:

```sh
sudo apt install live-build
cd titan-os
sudo ./build.sh                # produces live-image-amd64.hybrid.iso
```

Then write the ISO to a USB stick (e.g. with `dd` or Balena Etcher) and boot it.

Validate the config without root or a full build (what CI runs):

```sh
./build.sh --check
sh tests/run-tests.sh
```

## Using the two modes

Once booted:

```sh
sudo titan-mode gaming    # low-latency tunables, GameMode, launch Steam
sudo titan-mode dev       # developer services + toolchains
titan-mode status         # show current mode
```

The desktop's autostart reads the active mode and launches the right thing
(Steam Big Picture in gaming, a terminal in dev).

## Running Windows `setup.exe` installers

```sh
winstall setup.exe                 # install into an auto-named Wine prefix
winstall --prefix mygame game.exe  # install into a named prefix
winstall --list                    # list installed programs
winstall --run mygame              # re-open a program's C: drive
```

Each program gets its own isolated Wine prefix (a self-contained fake `C:`
drive) so one bad installer can't break another program.

## What's inside

```
titan-os/
├── build.sh                     # build / --check / --clean
├── config/
│   ├── package-lists/           # base + gaming + dev package sets
│   ├── includes.chroot/         # files baked into the image
│   │   ├── usr/local/bin/       # titan-mode, winstall
│   │   ├── etc/sysctl.d/        # per-mode kernel tuning
│   │   ├── etc/default/zramswap # low-RAM compressed swap
│   │   └── etc/skel/.config/openbox/autostart
│   └── hooks/normal/            # first-boot setup baked at build time
├── tests/run-tests.sh           # shellcheck + tool behaviour (no root)
└── .github/workflows/           # CI: lint + tests
```

## Design choices for low RAM

| Choice | Why |
|---|---|
| Openbox + tint2 | A full desktop is hundreds of MB of RAM; Openbox is a few. |
| `zram` swap (lz4) | Compressed swap in RAM keeps builds/games alive under pressure. |
| Modes don't reinstall | Switching only toggles services/tunables — instant, no disk churn. |
| Firefox **ESR** | Lighter, long-term-support browser. |
| Docker off by default | Heavy on 2 GB; started only in dev mode when you need it. |

## License

See the repository's top-level `LICENSE`.
