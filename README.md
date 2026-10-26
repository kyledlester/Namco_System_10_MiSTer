# Namco System 10 for MiSTer

<img width="320" height="240" alt="image" src="https://github.com/user-attachments/assets/de94939c-fd12-4928-ad29-33867efa7ab5" /> <img width="320" height="240" alt="image" src="https://github.com/user-attachments/assets/4e74a50b-ad78-430b-bef4-282cc459e40a" />

A MiSTer FPGA core for Namco's **System 10** arcade board (2000-2004), the PlayStation-based platform behind
**Mr. Driller 2**, **Mr. Driller G**, **Point Blank 3**, **Gamshara**, **Taiko no Tatsujin**, **Golgo 13** and more.
One core (`Namco_S10`) runs every supported game; each game has its own MRA.

I created this core because I wanted to play these games on my MiSTer FPGA. I am posting it here and open sourcing
it for everyone to enjoy and give feedback/make improvements. This core was created with the assistance of AI
tooling.

**Status: beta.** Every System 10 game other than Taiko no Tatsujin (1; the first iteration) and the medal/punching bag games games is working: 22 games and 4 alternative sets. All the main games have been tested on MiSTer hardware, with no known issues.

## Quick start

1. Copy the core from [`Releases/`](Releases/) (`Namco_S10_YYYYMMDD.rbf`) to **`/media/fat/_Arcade/cores/`**.
2. Copy the MRA files from [`MRA/`](MRA/) to **`/media/fat/_Arcade/`**. For the alternative sets, copy the
   `_<Game>` folders from [`MRA/_alternatives/`](MRA/_alternatives/) to **`/media/fat/_Arcade/_alternatives/`**.
3. Put the MAME 0.289 ROM zips in **`/media/fat/games/mame/`** (set names below). Split, merged and non-merged sets
   all work; with split sets, an alternative set also needs its parent's zip.
4. For the MP3 and Taiko games, you'll need to create a folder **`/media/fat/games/{mame_rom_name_without_extension}`** for each of them (for example **`/media/fat/games/taiko2`**). This is unnecessary if you don't plan to play those titles (see list below for games with extra files).
   They need one extra file each (a CD image or an audio file, see below), and they need to go inside their games' named folder in the /games folder.
5. Load the game from the **Arcade** menu.

ROMs are not included. You must supply your own.

## Supported games

| Game | MAME set | Year | Board | Extra file | Status |
| --- | --- | --- | --- | --- | --- |
| Mr. Driller 2 (World, DR22 Ver.A) | `mrdrilr2` | 2000 | MEM(M) | | Tested working |
| Mr. Driller G (Japan, DRG1 Ver.A) | `mrdrilrg` | 2001 | MEM(N) | | Tested working |
| Point Blank 3 (World, GNN2 Ver.A) | `ptblank3` | 2000 | MEM(N) + EXIO(G) light-gun board | | Tested working (GunCon 2) |
| GAHAHA Ippatsudou (World, GID2 Ver.A) | `gahaha` | 2000 | MEM(N) + EXIO | | Tested working (analog sticks) |
| GAHAHA Ippatsudou 2 (Japan, GIS1 Ver.A) | `gahaha2` | 2001 | MEM(N) + EXIO | | Tested working (analog sticks) |
| GekiToride-Jong Space (10011 Ver.A) | `gjspace` | 2001 | MEM(N) | | Tested working |
| Kotoba no Puzzle Mojipittan (Japan, KPM1 Ver.A) | `knpuzzle` | 2001 | MEM(N) | | Tested working |
| Gamshara (20020912A, 10021 Ver.A) | `gamshara` | 2002 | MEM(N) | | Tested working |
| Uchuu Daisakusen: Chocovader Contactee (Japan, CVC1 Ver.A) | `chocovdr` | 2002 | MEM(N) | | Tested working |
| Panikuru Panekuru (Japan, PPA1 Ver.A) | `panikuru` | 2002 | MEM(N) | | Tested working |
| Star Trigon (Japan, STT1 Ver.A) | `startrgn` | 2002 | MEM(N) | | Tested working |
| Kono e Tako (10021 Ver.A) | `konotako` | 2003 | MEM(N) | | Tested working |
| Golgo 13: Juusei no Requiem (Japan, GLT1 VER.A) | `g13jnr` | 2001 | MEM(P3) MP3 board | `g13jnr.p3a` | Tested working (GunCon 2) |
| Tsukkomi Yousei Gips Nice Tsukkomi (NTK1 Ver.A) | `nicetsuk` | 2002 | MEM(P3) MP3 board | `nicetsuk.p3a` | Tested working |
| Seishun-Quiz Colorful High School (CHS1 Ver.A) | `squizchs` | 2003 | MEM(P3) MP3 board | `squizchs.p3a` | Tested working |
| NFL Classic Football (US, NCF3 Ver.A.) | `nflclsfb` | 2003 | MEM(N) + EXIO + trackballs | | Tested working |
| Taiko no Tatsujin 2 (Japan, TK21 Ver.C) | `taiko2` | 2001 | MEM(N) + EXIO + CD-ROM | `nm-002.bin` | Tested working |
| Taiko no Tatsujin 3 (Japan, TK31 Ver.A) | `taiko3` | 2002 | MEM(N) + EXIO + CD-ROM | `nm-003.bin` | Tested working |
| Taiko no Tatsujin 4 (Japan, TK41 Ver.A) | `taiko4` | 2002 | MEM(N) + EXIO + CD-ROM | `tk-41.bin` | Tested working |
| Taiko no Tatsujin 5 (Japan, TK51 Ver.A) | `taiko5` | 2003 | MEM(N) + EXIO + CD-ROM | `tk-5.bin` | Tested working |
| Taiko no Tatsujin 6 (Japan, TK61 Ver.A) | `taiko6` | 2004 | MEM(N) + EXIO + CD-ROM | `tk-6.bin` | Tested working |
| Taiko no Tatsujin RT: Nippon no Kokoro (Japan, TKN1 Ver.A) | `taikort` | 2004 | MEM(N) + EXIO + CD-ROM | `tk-n.bin` | Tested working |

MAME marks the Taiko games and NFL Classic Football as not working; all of them play on this core.

### Alternatives

These use the same core and the same board settings as the main set, with a different ROM set.

| Game | MAME set | Year | Parent game | Status |
| --- | --- | --- | --- | --- |
| Mr. Driller 2 (Japan, DR21 Ver.A) | `mrdrilr2j` | 2000 | Mr. Driller 2 | Limited testing |
| Mr. Driller 2 (US, DR23 Ver.A) | `mrdrilr2u` | 2000 | Mr. Driller 2 | Limited testing |
| Gunbalina (Japan, GNN1 Ver.A) | `gunbalina` | 2000 | Point Blank 3 | Tested working (GunCon 2) |
| Gamshara (20020716A, 10021 Ver.A) | `gamsharao` | 2002 | Gamshara | Limited testing |

### Games not supported

The rest of MAME's System 10 list are cabinets built around mechanics, and MAME lists all of them as not working:

* **Medal games** (Puzz Ball, Sugorotic JAPAN, Pacman BALL, Slot no Oujisama, Sekai Kaseki Hakken, Ball Pom Line,
  Keroro Gunsou, Gegege no Kitaro, Medal no Tatsujin 1 and 2): MGEXIO / EXFINAL boards driving medal hoppers,
  pushers and sensors.
* **Punching-bag games** (Knock Down 2001 with its P-DRIVE motor board, Hard Puncher Hajime no Ippo 1 and 2 on
  Taito's MEM(IO) board).

## Taiko no Tatsujin: the CD image

The Taiko games read their songs from a CD-ROM as well as the ROM zip. MAME keeps the disc as a **CHD** file,
which a MiSTer arcade core cannot read, so convert it once to **BIN/CUE** with `chdman`, the tool that comes with
MAME.

**1. Find your CHDs.** They sit in a folder named after the game, next to the zip:

| Game | ROM zip | CHD | File to copy |
| --- | --- | --- | --- |
| Taiko no Tatsujin 2 | `taiko2.zip` | `taiko2/nm-002.chd` | `nm-002.bin` |
| Taiko no Tatsujin 3 | `taiko3.zip` | `taiko3/nm-003.chd` | `nm-003.bin` |
| Taiko no Tatsujin 4 | `taiko4.zip` | `taiko4/tk-41.chd` | `tk-41.bin` |
| Taiko no Tatsujin 5 | `taiko5.zip` | `taiko5/tk-5.chd` | `tk-5.bin` |
| Taiko no Tatsujin 6 | `taiko6.zip` | `taiko6/tk-6.chd` | `tk-6.bin` |
| Taiko no Tatsujin RT | `taikort.zip` | `taikort/tk-n.chd` | `tk-n.bin` |

(MAME lists RT's CHD as a bad dump; it plays fine.)

**2. Convert.** `chdman` is in your MAME folder (`chdman.exe` on Windows; on Linux / macOS install the
`mame-tools` package or use the binary from your MAME build). For example, for Taiko 2, from the MAME folder:

```
chdman extractcd -i roms/taiko2/nm-002.chd -o nm-002.cue
```

This writes `nm-002.cue` and `nm-002.bin` (a few hundred MB). To convert all six at once on Windows, run this in
the MAME folder (Command Prompt):

```
for %g in (taiko2\nm-002 taiko3\nm-003 taiko4\tk-41 taiko5\tk-5 taiko6\tk-6 taikort\tk-n) do chdman extractcd -i roms\%g.chd -o %~ng.cue
```

**3. Copy the `.bin`** to **`/media/fat/games/{mame_rom_name_without_extension}`** (the `.cue` is not needed). The folder must exist:
**Mount CD** opens it, and without it MiSTer shows an error instead of a file list.

**4. Mount it once.** Start the game, open the OSD (F12), choose **Mount CD** and pick the `.bin`. The game
restarts by itself with the disc in the drive; no manual reset is needed. The core remembers the disc for each
game and mounts it automatically from then on. Without a disc the game stops on a black screen after the NOTICE
screen. Both kinds of `.bin` that `chdman` writes (2352- and 2048-byte sectors) work, and so do `.iso` files.

## MP3 board games: the audio file (Golgo 13, Nice Tsukkomi, Seishun Quiz)

These three games play their music and voices through an MP3 decoder chip on the ROM board (MEM(P3)). The core
does not decode MP3 itself. Instead, a converter on your PC decodes the game's MP3 files once into an audio file
(`.p3a`), and the core streams that file from the SD card. Without it the games run silently apart from their
sound effects.

**1. Install** [Python 3](https://www.python.org/), then the two packages the converter needs (numpy, and PyAV to
decode MP3):

```
pip install numpy av
```

If [ffmpeg](https://ffmpeg.org/) is on your PATH, the converter uses it instead of PyAV.

**2. Convert.** Run [`tools/p3audio.py`](tools/p3audio.py) with the folder holding your MAME ROM zips and the set
name. It writes `<set>.p3a` in the current folder (or give an output file name as a third argument):

```
python tools/p3audio.py C:\MAME\roms g13jnr
python tools/p3audio.py C:\MAME\roms nicetsuk
python tools/p3audio.py C:\MAME\roms squizchs
```

| Game | Set | File | Audio | File size |
| --- | --- | --- | --- | --- |
| Golgo 13 | `g13jnr` | `g13jnr.p3a` | 19 tracks, 15 min | about 150 MB |
| Nice Tsukkomi | `nicetsuk` | `nicetsuk.p3a` | 873 tracks, 39 min | about 395 MB |
| Seishun Quiz | `squizchs` | `squizchs.p3a` | 98 tracks, 39 min | about 360 MB |

**3. Copy the `.p3a`** to **`/media/fat/games/{mame_rom_name_without_extension}`** (create the folder if it does not exist).

**4. Mount it once.** Start the game, open the OSD (F12), choose **Mount audio** and pick the game's `.p3a`. No
reset is needed: the next music or voice clip the game plays comes from the file. The core remembers the file for
each game and mounts it automatically from then on.

The game copies each MP3 into the board's RAM before playing it. The core recognises the track from its length and
three short samples of its data, and plays the converted audio at the game's own volume.

## NFL Classic Football: trackballs and the sideways screen

The cabinet seats four players around a monitor mounted on its side, each with a trackball and two PASS buttons.
The trackballs are read by a control-panel board that talks to the I/O board's microcontroller over a serial line.
MAME has no emulation of that board, which is why it lists the game as not working; this core emulates it.

* **Screen:** set **Orientation** to **Vertical CCW** in the OSD for an upright picture on a normal screen.
* **Trackballs:** Player 1 uses a USB mouse / trackball or the left analog stick; Players 2-4 use their left analog
  sticks. The **Trackball** OSD page has the speed (1x, 2x, 4x, 1/2), Invert X / Invert Y, and an option to turn
  the analog sticks off.
* **Buttons:** Button 1 = PASS 1 and Button 2 = PASS 2 for each player; Start = that player's Start. The play-select
  buttons of the two sides (Choose L / Choose R / Decide; LEFT SIDE and RIGHT SIDE in the service menu) are Player 1's
  and Player 2's Buttons 3 / 4 / 5. Player 1's Up / Down and Button 6 are the cabinet's Select Up / Down and Enter
  (service menu).

## Controls

The buttons are asked for in this order: Buttons 1-6 (only the ones the game uses), Start, Coin, Test, Service,
Pause.

| MiSTer button | Default pad button | Mr. Driller | Point Blank 3 | Gamshara | Taiko no Tatsujin |
| --- | --- | --- | --- | --- | --- |
| Button 1 | A | Drill | Trigger | Button 1 | Enter |
| Button 2 | B | | | Button 2 | Left Don (left drum surface) |
| Button 3 | X | | | Button 3 | Right Don (right drum surface) |
| Button 4 | Y / L | | | | Left Ka (left rim) |
| Button 5 | R2 / R | | | | Right Ka (right rim) |
| Start | Start | Start | Start | Start | |
| Coin | Select | Coin | Coin | Coin | Coin |
| Test | L (L2 for Taiko) | Test switch (press once to enter the service menu, again to leave) | same | same | same |
| Service | R (R2 for Taiko) | Service credit | same | same | same |
| Pause | R3 | Pause | Pause | Pause | Pause |

* **Taiko no Tatsujin:** Up / Down choose songs. A USB Taiko drum controller works by mapping its four zones to
  Buttons 2-5.
* **GAHAHA Ippatsudou 1 / 2:** each player's two levers are the pad's left and right analog sticks; Button 1,
  Button 2 and Enter (Button 3), Up / Down to select.
* **Golgo 13:** aim the rifle with a light gun, analog stick or mouse, as in Point Blank 3 (the **Light Gun** OSD page
  and crosshair work the same). Button 1 is Enter, Button 2 the trigger, and Button 3 toggles the scope sensor (put
  your eye to the scope / take it away).
* **Nice Tsukkomi:** Buttons 1-3 are the forehead, chest and back-of-head hit sensors, Button 4 the pedal, Button 5
  Enter, Up / Down to select and Start to choose.
* **Seishun Quiz:** Buttons 1-4 answer, for each player.
* **Mr. Driller** uses a 4-way joystick, **Gamshara** an 8-way joystick.

### Light guns (Point Blank 3, Gunbalina, Golgo 13)

Aim comes from MiSTer's standard light-gun input, so a **GunCon 2** (on a 15 kHz CRT, calibrated for the core with
**F10** in the OSD), **Sinden**, **Gun4IR**, a Wiimote or a plain analog stick all work, one per player. The trigger is
button 1 of the same player (button 2 in Golgo 13). Player 1 can also aim with a mouse.

The **Light Gun** OSD page (shown only for gun games) has:

* **Gun aim P1**: Joystick (gun / analog stick) or Mouse.
* **Crosshair**: Off / On (a different colour per player).

Point Blank 3 also has its own gun calibration in its service menu, as on the cabinet.

## OSD

* **Scandoubler Fx**, **Orientation** (Horizontal, Vertical CW, Vertical CCW, Flipped; NFL Classic Football needs
  Vertical CCW), **Video & Audio** (aspect ratio, scaling, dithering, stereo mix), **CRT Adjust** for the native
  15 kHz output.
* **DIP Switches**: the board's DIP switches, named per game from MAME. Gamshara's **Region** selects World
  (English, the default) or Japan; Kono e Tako's selects Japan (*Kono e Tako*, the default) or Export (*Kono TaCO!*,
  the English Cristaltec release). The region is read at boot, so reset after changing it.
* **Mount CD** (Taiko games) / **Mount audio** (MP3 board games): see above.
* **Light Gun** (gun games only) and **Trackball** (NFL Classic Football only): see above.
* **Hardware**: Pause when OSD open. **IRQ10 (Input)**: 100Hz (default, as MAME) or 2xVBlank. The board's real I/O
  interrupt rate is unknown (MAME's 100 Hz is a placeholder); with 2xVBlank it fires twice per frame, so Mr. Driller 2 / G
  sample the inputs exactly once per frame (smoother rapid fire). Contributed by guljam.

## Saves

System 10 keeps operator settings, high scores and bookkeeping on the ROM board itself. The core saves that area to
the SD card as a `.nvm` file shortly after the game writes it. On the very first boot the games show
**FIRST POWER ON** for a few seconds while they set it up; this is normal.

## Video and timing

The games choose their own resolution, exactly as on the PCB: most run at 240p, while Mr. Driller G, Gamshara,
Kono e Tako and Star Trigon draw some or all of their screens at 640x480 interlaced (480i). Mr. Driller G's service
menu can switch the game to 240p. On HDMI the scaler weaves the two 480i fields into a full 480-line picture (with
Scandoubler Fx set to None; the scandoubled image is line-doubled per field).

System 10 is a PlayStation running 1.5x faster: the CPU and the sound chip run from 101.4912 MHz / 2
(50.7456 MHz) instead of the PlayStation's 33.8688 MHz, while the video timing is the PlayStation's. The core
matches that: the sound chip runs at the board's **66.15 kHz** sample rate, the CPU approximates the board's speed with
the PSX core's turbo modes and a full-rate data cache (it is clocked at 33.8688 MHz), and the video runs at **59.82 Hz** (240p) / 59.94 Hz (480i). Inputs, including the Taiko drums, are read live by the game at every
poll; nothing is buffered.

MiSTer's HDMI output runs at a fixed 60 Hz by default, which repeats one frame about every 6 seconds at 240p. That
is hard to see in most games but shows as a small hitch in the scrolling notes of Taiko no Tatsujin. For
frame-perfect HDMI output, set `vsync_adjust=2` (lowest latency) or `vsync_adjust=1` in `MiSTer.ini` (globally, or
in a section per game, e.g. `[taiko2]`). The analog 15 kHz output is always native.

## Differences from MAME

MAME 0.289's `namcos10` driver is the reference for this core, which matches it everywhere that can be checked
(decrypted ROM data, board register traffic, boot sequence). In a few places the core goes beyond MAME:

* **Taiko no Tatsujin 2-6 and RT.** MAME marks them not working because its PlayStation timing is not accurate
  enough for a rhythm game. The core runs the CPU, GPU and sound chip cycle by cycle, with the sound chip at the
  board's own 66.15 kHz.
* **NFL Classic Football.** MAME cannot read the trackballs (its control-panel board is not emulated) and marks the
  game not working. The core emulates that board, so the game is fully playable.
* **Golgo 13, Nice Tsukkomi, Seishun Quiz.** These games' music and voices play from the converted audio file.
* **Sound.** MAME flags every System 10 game as *imperfect sound*. This core plays sound through the PSX_MiSTer SPU,
  a hardware-level reimplementation of the PlayStation sound chip (the chip on the System 10 main board).
* **Point Blank 3 / Gunbalina.** The real cabinets use the cut-down **EXIO(G)** board: gun logic only, no
  microcontroller. MAME emulates the full EXIO board instead; the core reports an EXIO(G) board, so the game takes
  the path it takes on the cabinet.
* **Light guns.** MAME aims with a mouse or stick-driven crosshair. The core takes real light guns (GunCon 2 on a
  CRT, Sinden, Gun4IR) through MiSTer's gun support.
* **Mr. Driller 2 operator menu.** MAME lists "opening the operator menu sometimes can crash Mr. Driller 2" as a
  known issue. On the core it opens reliably.
* **Taiko no Tatsujin 3 right edge.** During songs the game keeps scratch data just right of its 320-pixel frame
  buffer and starts the picture 2 pixels in, so MAME shows a strip of coloured dots down the right edge. The core
  blanks the picture past the frame buffer for this game (a flag in its MRA), so the edge stays clean.
* **Gamshara region.** MAME's driver notes that it is unknown whether the later Gamshara set (20020912A) honours the
  World region setting like the earlier one. It does, so the MRA defaults to World (English).

MAME marks Point Blank 3 *unemulated protection*: part of the KEYCUS chip's decryption is not understood and is
replayed from a recorded bit table (`ptblank3_nonlinear`, part of the MAME set). The core does the same, so it works
with the MAME ROM set unchanged.

## About the hardware

As mentioned, System 10 is a PSOne on an arcade board, clocked 1.5x faster: a CXD8606 CPU (R3000A + GTE) at 50.7 MHz, a CXD8561CQ
GPU with 2 MB of VRAM, the PlayStation sound chip (CXD2938Q, 66.15 kHz) with 512 KB of sound RAM, and 4 MB of main
RAM. There is no boot ROM on the main board: everything, including the boot code, comes from the **MEM** ROM board,
whose KEYCUS CPLD descrambles the ROM data and decrypts the game program. Some games add an **EXIO** expansion board
(light guns, drums, analog levers, trackballs) or a CD-ROM drive, and three use the **MEM(P3)** board with an MP3
decoder. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## About the core

* Built on Robert Peip's [PSX_MiSTer](https://github.com/MiSTer-devel/PSX_MiSTer) (CPU, GTE, GPU, SPU, MDEC, DMA), and the author's Namco System 12 (Tenkomori Shooting) and Konami GV cores.
* Thanks to guljam's [System 10 beta core](https://github.com/guljam/namco-system-10-mister-core-beta), whose
  development notes pointed out the 480i GPU throughput problem and Star Trigon's sound-upload
  stall, and whose review of this core found the HDMI 480i field and the Mr. Driller 2 / G CPU-time issue (full-rate
  cache with a longer VSync() timeout); the implementations here are this core's own.
* New for System 10: the MEM board (MEM(M) flash and mask ROMs, MEM(N) NAND), the KEYCUS
  descrambler and decrypters (type 1, type 2, type 2 with the nonlinear table or several nonlinear terms), the
  main-board I/O, the EXIO(G) light-gun board, the EXIO board with its microcontroller (drums, analog levers, NFL's
  trackball board; high-level), the ATAPI CD-ROM drive and the MEM(P3) board (high-level MCU, pre-converted audio).
  The decrypters reproduce MAME on every word the games read.
* ROM images are loaded straight into DDR3 (fast loading), so even the largest System 10 games (Seishun Quiz,
  231 MB) fit.
* One RBF for every game. The core has no per-game code beyond what each MRA's board record selects.

### Known issues

None at the moment.

* **Taiko song previews or music silent for some songs:** check that the disc `.bin` on the SD card is complete (its size
  must match the one `chdman` wrote on your PC). A truncated copy still boots, because the game's own files sit at the
  start of the disc, but every song stored past the cut-off plays silence.

## Releases

Builds are in [`Releases/`](Releases/) as `Namco_S10_YYYYMMDD.rbf`. The MRAs name the core without the date
(`<rbf>Namco_S10</rbf>`), and MiSTer loads the newest dated file in `_Arcade/cores/`. You are welcome to run your
own build if you'd prefer.

## Building

Quartus Prime Lite 17.0. Open `Namco_S10.qpf` and compile; the build copies a dated RBF into `Releases/`. The MRAs
are generated with `python scripts/s10tool.py mra`. See [docs/BUILDING.md](docs/BUILDING.md).

## Documentation

* [Architecture](docs/ARCHITECTURE.md)
* [Building and verification](docs/BUILDING.md)
* [MP3 audio converter](tools/p3audio.py)

## License

GPL-3.0-or-later for the combined work (see [LICENSE](LICENSE), [COPYING.GPL2](COPYING.GPL2) and
[COPYING.GPL3](COPYING.GPL3)). The MiSTer framework in `sys/` keeps its own notices.

No ROMs or other game data are included in this repository. "Namco" and "System 10" are trademarks of their owners;
this project is not affiliated with them.
