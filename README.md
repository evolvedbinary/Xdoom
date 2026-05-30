# doom-runner — XQuery Module
This project was vibe coded by Younes Bahloul and Claude name. It was produced as a fun demo for the XQuery and XML Databases workshop at XML Prague 2026 conference

Runs the [MochaDoom](https://github.com/mochadoom/mochadoom) Java game engine inside Elemental and streams live game frames to any browser via an embedded WebSocket server.

---

## Architecture

```
Elemental XQuery
    │
    │  doom:start(iwad, port)
    ▼
MochaDoom engine  ──────────────────────────►  embedded WebSocket server
 (game-loop thread)     JPEG frames                      │
                                                          │  ws://localhost:{port}
                                                          ▼
                                                   Browser (canvas)
                                                   sends key events back ◄─────┘
```

The browser client is served by MochaDoom's embedded HTTP server at the same port as the WebSocket. No Node.js relay or separate server process is needed.

---

## Prerequisites

1. **MochaDoom** installed to your local Maven repository:
   ```bash
   cd mochadoom
   mvn install
   ```

2. **Elemental built** with the doom-runner module:
   ```bash
   mvn package -DskipTests
   ```

`doom1.wad` is bundled inside the module JAR (`src/main/resources/doom1.wad`) and extracted automatically at runtime by `doom:iwad-path()` — no manual WAD setup required.

---

## Module Registration

The module is already registered in `exist-distribution/src/main/config/conf.xml` and loads automatically at startup — no manual configuration needed:

```xml
<module uri="http://elemental.xyz/xquery/doom-runner"
        class="org.exist.xquery.modules.doomrunner.DoomRunnerModule"/>
```

---

## Quick Start

1. Start Elemental:
   ```
   bin/startup.bat   (Windows)
   bin/startup.sh    (Linux / macOS)
   ```

2. Open the Admin Panel query editor at `http://localhost:8088/exist/apps/admin/` (or use [eXide](http://localhost:8088/exist/apps/eXide/)).

3. Paste the contents of `doom-start.xq`, set your IWAD path, and run the query.

4. Open `http://localhost:3001` in any browser — the game canvas appears and is immediately playable with the keyboard.

---

## XQuery Scripts

| Script | What it does |
|---|---|
| `doom-start.xq` | Start the engine with WebSocket streaming; edit `$iwad` and `$ws-port` |
| `doom-status.xq` | Return an XML element showing `<running>` and `<paused>` state |
| `doom-pause.xq` | Halt the game loop (true tick-halt — audio stops, PAUSE banner shown) |
| `doom-resume.xq` | Resume after a pause |
| `doom-stop.xq` | Interrupt the game-loop thread (see Limitations below) |

---

## XQuery Function Reference

Import the module with:

```xquery
import module namespace doom = "http://elemental.xyz/xquery/doom-runner";
```

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `doom:start` | `$iwad as xs:string` | `empty-sequence()` | Start in headless mode (no browser output) |
| `doom:start` | `$iwad as xs:string, $port as xs:integer` | `empty-sequence()` | Start with embedded WebSocket server on `$port` |
| `doom:stop` | — | `empty-sequence()` | Interrupt game-loop thread; returns immediately |
| `doom:pause` | — | `empty-sequence()` | Block the game loop until `doom:resume()` |
| `doom:resume` | — | `empty-sequence()` | Unblock a paused game loop |
| `doom:is-running` | — | `xs:boolean` | `true` while the game-loop thread is alive |
| `doom:is-paused` | — | `xs:boolean` | `true` between `doom:pause()` and `doom:resume()` |
| `doom:iwad-path` | — | `xs:string` | Absolute path to the bundled doom1.wad; extracted from the JAR to a temp file on first call |

### Example: inline usage

```xquery
xquery version "3.1";
import module namespace doom = "http://elemental.xyz/xquery/doom-runner";

(: check state before starting :)
if (not(doom:is-running())) then
  doom:start("/data/freedoom1.wad", 3001)
else ()
```

---

## Playing the Game

Navigate to `http://localhost:{ws-port}` after starting. The default port in `doom-start.xq` is **3001**.

### Keyboard controls

| Key | Action |
|---|---|
| Arrow keys / WASD | Move and turn |
| Ctrl | Fire weapon |
| Space | Open doors / activate |
| Shift | Run |
| Alt + Arrow | Strafe |
| 1–7 | Select weapon |
| Enter | Confirm menu selection |
| Escape | Open / close menu |
| F1 | Help |
| F2 | Save game |
| F3 | Load game |
| F5 | Detail level |
| F6 | Quicksave |
| F7 | End game |
| F10 | Quit |
| F11 | Gamma correction |
| F12 | Toggle display |

The browser client (`doom-server/index.html`) also works standalone if you prefer to host it separately — it connects to any host/port that runs the MochaDoom WebSocket server.

---

## Limitations

- **No restart within the same JVM.** MochaDoom holds static engine state that cannot be reset. After calling `doom:stop()`, restart Elemental to play again. See `extensions/modules/LIBRARY.md` section 10 for a `ProcessBuilder`-based workaround if restartable sessions are needed.

- **One instance per JVM.** Only one MochaDoom engine can run at a time; a second `doom:start()` call throws an error.

- **Sound disabled by default.** The module starts with `-nosound`. Audio output from a headless server process is rarely useful; if you need sound, modify `DoomRunnerFunctions.java` to remove `noSound(true)`.

- **Bundled WAD.** `doom1.wad` is packaged inside the module JAR (`src/main/resources/doom1.wad`) and extracted to a temp file automatically by `doom:iwad-path()`. The temp file is deleted when the JVM exits.

---

## See Also

- `extensions/modules/LIBRARY.md` — full MochaDoom Java API reference
- `doom-server/index.html` — standalone browser client
- `extensions/modules/doom-runner/src/main/java/…/DoomRunnerModule.java` — module class
- `extensions/modules/doom-runner/src/main/java/…/DoomRunnerFunctions.java` — function implementations
