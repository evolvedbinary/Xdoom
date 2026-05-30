(:
 * Copyright (C) 2026 Evolved Binary Ltd
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors
 *    may be used to endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 :)
xquery version "3.1";

import module namespace doom = "http://elemental.xyz/xquery/doom-runner";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html";
declare option output:media-type "text/html";
declare option output:html-version "5.0";



declare variable $iwad     as xs:string  external := doom:iwad-path();
declare variable $ws-port  as xs:integer external := 3001;
declare variable $skill    as xs:integer external := 2;
declare variable $no-sound as xs:boolean external := false();
declare variable $no-music as xs:boolean external := false();

let $start :=
  if (doom:is-running()) then ()
  else doom:start($iwad, $ws-port, $skill, $no-sound, $no-music)

return
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>DOOM Live Stream</title>
  <meta name="description" content="Real-time DOOM gameplay streamed from a Java engine to your browser via WebSocket." />
  <style><![CDATA[
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    @import url('https://fonts.googleapis.com/css2?family=Share+Tech+Mono&display=swap');

    /* ── Welcome screen ──────────────────────────────────────────────────── */
    #welcome {
      position: fixed;
      inset: 0;
      z-index: 100;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 32px;
      background: radial-gradient(ellipse at 50% 40%, #1a0505 0%, #080808 70%);
    }
    #welcome.hidden { display: none; }

    .welcome-title {
      font-size: clamp(3rem, 10vw, 6rem);
      font-weight: 900;
      letter-spacing: .2em;
      color: var(--red);
      text-shadow: var(--glow-red), 0 0 120px rgba(230,57,70,.4);
      text-transform: uppercase;
      user-select: none;
      line-height: 1;
    }
    .welcome-title span { color: var(--orange); }

    .welcome-skull {
      font-size: clamp(4rem, 12vw, 7rem);
      filter: drop-shadow(0 0 24px var(--red)) drop-shadow(0 0 60px rgba(230,57,70,.4));
      animation: float 3s ease-in-out infinite;
    }
    @keyframes float {
      0%, 100% { transform: translateY(0);    }
      50%       { transform: translateY(-12px); }
    }

    .welcome-sub {
      font-size: .85rem;
      color: var(--text-dim);
      letter-spacing: .18em;
      text-transform: uppercase;
    }

    #play-btn {
      margin-top: 8px;
      padding: 16px 56px;
      font-family: inherit;
      font-size: 1.1rem;
      letter-spacing: .2em;
      text-transform: uppercase;
      color: var(--text);
      background: var(--red-dark);
      border: 2px solid var(--red);
      border-radius: 4px;
      cursor: pointer;
      transition: background .15s, box-shadow .15s, transform .1s;
      box-shadow: 0 0 20px rgba(230,57,70,.35);
    }
    #play-btn:hover  { background: var(--red); box-shadow: 0 0 36px rgba(230,57,70,.6); }
    #play-btn:active { transform: scale(.97); }

    :root {
      --red:      #e63946;
      --red-dark: #9d0208;
      --orange:   #f48c06;
      --bg:       #080808;
      --surface:  #111111;
      --surface2: #1a1a1a;
      --border:   #2a2a2a;
      --text:     #e8e8e8;
      --text-dim: #888;
      --green:    #2dc653;
      --glow-red: 0 0 24px rgba(230,57,70,.6), 0 0 60px rgba(230,57,70,.25);
    }

    html, body {
      height: 100%;
      background: var(--bg);
      color: var(--text);
      font-family: 'Share Tech Mono', 'Courier New', monospace;
      overflow: hidden;
    }

    body {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: flex-start;
      min-height: 100vh;
      padding: 0;
    }

    header {
      width: 100%;
      padding: 14px 28px;
      background: linear-gradient(90deg, #0d0d0d 0%, #1a0505 50%, #0d0d0d 100%);
      border-bottom: 1px solid var(--border);
      display: flex;
      align-items: center;
      gap: 18px;
      position: relative;
      z-index: 10;
      flex-shrink: 0;
    }

    .logo {
      font-size: 1.6rem;
      font-weight: 900;
      letter-spacing: .15em;
      color: var(--red);
      text-shadow: var(--glow-red);
      text-transform: uppercase;
      user-select: none;
    }

    .logo span { color: var(--orange); }

    .header-right {
      margin-left: auto;
      display: flex;
      align-items: center;
      gap: 20px;
    }

    #status-pill {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 5px 14px;
      border-radius: 99px;
      border: 1px solid var(--border);
      background: var(--surface2);
      font-size: .78rem;
      letter-spacing: .06em;
      transition: background .3s;
    }

    #status-dot {
      width: 9px; height: 9px;
      border-radius: 50%;
      background: var(--text-dim);
      transition: background .3s, box-shadow .3s;
    }

    #status-pill.connected    { border-color: #1a3d1a; background: #0d1f0d; }
    #status-pill.connected    #status-dot { background: var(--green); box-shadow: 0 0 8px var(--green); }
    #status-pill.disconnected { border-color: #3d1a1a; background: #1f0d0d; }
    #status-pill.disconnected #status-dot { background: var(--red); box-shadow: 0 0 8px var(--red); }

    .stats {
      display: flex;
      gap: 24px;
      font-size: .75rem;
      color: var(--text-dim);
    }

    .stat-item strong {
      color: var(--text);
      font-weight: normal;
    }

    main {
      flex: 1;
      width: 100%;
      display: flex;
      align-items: center;
      justify-content: center;
      position: relative;
      overflow: hidden;
      background:
        radial-gradient(ellipse at 50% 0%, rgba(230,57,70,.06) 0%, transparent 60%),
        var(--bg);
    }

    main::before {
      content: '';
      position: absolute;
      inset: 0;
      background: repeating-linear-gradient(
        0deg,
        transparent 0px,
        transparent 2px,
        rgba(0,0,0,.18) 2px,
        rgba(0,0,0,.18) 4px
      );
      pointer-events: none;
      z-index: 3;
    }

    .canvas-wrap {
      position: relative;
      line-height: 0;
      border: 1px solid var(--border);
      box-shadow:
        0 0 0 1px rgba(230,57,70,.12),
        0 0 40px rgba(0,0,0,.8),
        inset 0 0 0 1px rgba(255,255,255,.03);
      z-index: 2;
    }

    .canvas-wrap::before {
      content: '';
      position: absolute;
      inset: -2px;
      border: 2px solid transparent;
      border-radius: 2px;
      background: linear-gradient(135deg, rgba(230,57,70,.3), transparent 40%) border-box;
      -webkit-mask: linear-gradient(#fff 0 0) padding-box, linear-gradient(#fff 0 0);
      -webkit-mask-composite: destination-out;
      mask-composite: exclude;
      pointer-events: none;
    }

    #screen {
      display: block;
      image-rendering: pixelated;
      image-rendering: crisp-edges;
    }

    #waiting {
      position: absolute;
      inset: 0;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 16px;
      background: rgba(8,8,8,.92);
      z-index: 5;
      transition: opacity .4s;
    }
    #waiting.hidden { opacity: 0; pointer-events: none; }

    .doom-skull {
      font-size: 3.5rem;
      filter: drop-shadow(0 0 16px var(--red));
      animation: pulse 2s ease-in-out infinite;
    }

    @keyframes pulse {
      0%, 100% { transform: scale(1);   opacity: 1; }
      50%       { transform: scale(.92); opacity: .7; }
    }

    #waiting p {
      font-size: .9rem;
      color: var(--text-dim);
      letter-spacing: .1em;
    }
    #waiting .blink {
      animation: blink 1.1s step-end infinite;
    }
    @keyframes blink { 50% { opacity: 0; } }

    footer {
      width: 100%;
      padding: 8px 28px;
      background: var(--surface);
      border-top: 1px solid var(--border);
      display: flex;
      align-items: center;
      justify-content: space-between;
      font-size: .7rem;
      color: var(--text-dim);
      flex-shrink: 0;
    }

    #fps-bar {
      display: flex;
      align-items: center;
      gap: 6px;
    }
    #fps-value {
      font-size: .85rem;
      color: var(--green);
      min-width: 3ch;
    }

    #reconnect-btn {
      display: none;
      padding: 6px 18px;
      background: var(--red-dark);
      border: 1px solid var(--red);
      color: var(--text);
      border-radius: 4px;
      cursor: pointer;
      font-family: inherit;
      font-size: .8rem;
      letter-spacing: .08em;
      transition: background .2s;
    }
    #reconnect-btn:hover { background: var(--red); }

    @media (max-width: 640px) {
      .stats { display: none; }
      .logo  { font-size: 1.1rem; }
    }
  ]]></style>
</head>
<body>

<div id="welcome">
  <div class="welcome-skull">&#x1F480;</div>
  <div class="welcome-title">DOO<span>M</span></div>
  <div class="welcome-sub">ElementalDB Doom</div>
  <button id="play-btn">&#x25BA; PLAY DOOM</button>
</div>

<header>
  <div class="logo">&#x1F480; <span>DOOM</span> LIVE</div>
  <div class="header-right">
    <div class="stats">
      <div class="stat-item">FRAME <strong id="stat-frame">&#x2014;</strong></div>
      <div class="stat-item">RES <strong id="stat-res">&#x2014;</strong></div>
      <div class="stat-item">SIZE <strong id="stat-size">&#x2014;</strong></div>
    </div>
    <div id="status-pill">
      <div id="status-dot"></div>
      <span id="status-text">CONNECTING</span>
    </div>
  </div>
</header>

<main>
  <div class="canvas-wrap" id="canvas-wrap">
    <canvas id="screen" width="320" height="200"></canvas>
    <div id="waiting">
      <div class="doom-skull">&#x1F480;</div>
      <p>WAITING FOR DOOM STREAM<span class="blink">_</span></p>
      <button id="reconnect-btn">RECONNECT</button>
    </div>
  </div>
</main>

<footer>
  <span>MochaDoom &#x2014; Java port &#xB7; streaming via WebSocket</span>
  <div id="fps-bar">
    FPS: <span id="fps-value">&#x2014;</span>
  </div>
</footer>

<script>var WS_PORT = {$ws-port};
<![CDATA[
'use strict';

// ── Message type bytes (must match Java GameWebSocketServer) ────────────────
const TYPE_VIDEO = 0x01;
const TYPE_AUDIO = 0x02;
const TYPE_MUSIC = 0x03;

// ── DOM refs ────────────────────────────────────────────────────────────────
const welcome      = document.getElementById('welcome');
const playBtn      = document.getElementById('play-btn');
const canvas       = document.getElementById('screen');
const ctx          = canvas.getContext('2d');
const waiting      = document.getElementById('waiting');
const statusPill   = document.getElementById('status-pill');
const statusText   = document.getElementById('status-text');
const statFrame    = document.getElementById('stat-frame');
const statRes      = document.getElementById('stat-res');
const statSize     = document.getElementById('stat-size');
const fpsValue     = document.getElementById('fps-value');
const reconnectBtn = document.getElementById('reconnect-btn');

// ── State ───────────────────────────────────────────────────────────────────
let frameCount  = 0;
let lastFpsTime = performance.now();

// ── FPS counter ─────────────────────────────────────────────────────────────
function updateFps() {
  const now = performance.now();
  const elapsed = (now - lastFpsTime) / 1000;
  if (elapsed >= 1) {
    fpsValue.textContent = Math.round(frameCount / elapsed);
    frameCount  = 0;
    lastFpsTime = now;
  }
}

// ── Render a JPEG onto the canvas ────────────────────────────────────────────
// msg: ArrayBuffer — byte 0 is the type byte (0x01), rest is JPEG
async function renderVideo(msg) {
  const blob = new Blob([new Uint8Array(msg, 1)], { type: 'image/jpeg' });
  const bitmap = await createImageBitmap(blob);
  const { width: w, height: h } = bitmap;
  if (canvas.width !== w || canvas.height !== h) {
    canvas.width  = w;
    canvas.height = h;
    scaleCanvas(w, h);
  }
  ctx.drawImage(bitmap, 0, 0);
  frameCount++;
  statFrame.textContent = (parseInt(statFrame.textContent) || 0) + 1;
  statRes.textContent   = w + '\xD7' + h;
  statSize.textContent  = formatBytes(blob.size);
  updateFps();
}

function scaleCanvas(w, h) {
  const main  = document.querySelector('main');
  const maxW  = main.clientWidth  - 32;
  const maxH  = main.clientHeight - 16;
  const scale = Math.min(maxW / w, maxH / h, 4);
  canvas.style.width  = Math.floor(w * scale) + 'px';
  canvas.style.height = Math.floor(h * scale) + 'px';
}
window.addEventListener('resize', () => scaleCanvas(canvas.width, canvas.height));

function formatBytes(b) {
  return b < 1024 ? b + 'B' : (b / 1024).toFixed(1) + 'KB';
}

// ── Web Audio API ────────────────────────────────────────────────────────────
// PCM format from Java: signed 16-bit big-endian stereo at 22050 Hz.
const DOOM_SAMPLE_RATE = 22050;
const AUDIO_LOOKAHEAD  = 0.15; // seconds to buffer ahead (prevents gaps)

let audioCtx = null;

function ensureAudioCtx() {
  if (!audioCtx) {
    audioCtx = new AudioContext({ sampleRate: DOOM_SAMPLE_RATE });
  }
}

function resumeAudioCtx() {
  if (audioCtx && audioCtx.state === 'suspended') audioCtx.resume();
}

function decodePcm(msg) {
  const pcmBytes = msg.byteLength - 1;
  const sampleCount = Math.floor(pcmBytes / 4);
  if (sampleCount === 0) return null;
  const view   = new DataView(msg, 1);
  const buffer = audioCtx.createBuffer(2, sampleCount, DOOM_SAMPLE_RATE);
  const left   = buffer.getChannelData(0);
  const right  = buffer.getChannelData(1);
  for (let i = 0; i < sampleCount; i++) {
    left[i]  = view.getInt16(i * 4,     false) / 32768;
    right[i] = view.getInt16(i * 4 + 2, false) / 32768;
  }
  return buffer;
}

function scheduleBuffer(buffer, nextTimeRef) {
  const source = audioCtx.createBufferSource();
  source.buffer = buffer;
  source.connect(audioCtx.destination);
  const now = audioCtx.currentTime;
  if (nextTimeRef.t < now + 0.01) nextTimeRef.t = now + AUDIO_LOOKAHEAD;
  source.start(nextTimeRef.t);
  nextTimeRef.t += buffer.duration;
}

const sfxTime   = { t: 0 };
const musicTime = { t: 0 };

function playAudio(msg) {
  ensureAudioCtx();
  const buf = decodePcm(msg);
  if (buf) scheduleBuffer(buf, sfxTime);
}

function playMusic(msg) {
  ensureAudioCtx();
  const buf = decodePcm(msg);
  if (buf) scheduleBuffer(buf, musicTime);
}

// ── WebSocket connection ─────────────────────────────────────────────────────
let ws            = null;
let reconnectTimer = null;
let firstFrame    = true;

function setStatus(state, label) {
  statusPill.className   = state;
  statusText.textContent = label;
}

function connect() {
  if (ws) { ws.onclose = null; ws.close(); }
  clearTimeout(reconnectTimer);
  ws = new WebSocket('ws://' + location.hostname + ':' + WS_PORT);
  ws.binaryType = 'arraybuffer'; // need raw bytes to read the type prefix
  setStatus('', 'CONNECTING…');
  reconnectBtn.style.display = 'none';

  ws.addEventListener('open', () => {
    setStatus('connected', 'LIVE');
  });

  ws.addEventListener('message', async (evt) => {
    if (!(evt.data instanceof ArrayBuffer) || evt.data.byteLength < 1) return;
    const type = new Uint8Array(evt.data, 0, 1)[0];
    if (type === TYPE_VIDEO) {
      if (firstFrame) { firstFrame = false; waiting.classList.add('hidden'); }
      await renderVideo(evt.data);
    } else if (type === TYPE_AUDIO) {
      playAudio(evt.data);
    } else if (type === TYPE_MUSIC) {
      playMusic(evt.data);
    }
  });

  ws.addEventListener('close', () => {
    setStatus('disconnected', 'DISCONNECTED');
    reconnectBtn.style.display = 'inline-block';
    reconnectTimer = setTimeout(connect, 3000);
  });

  ws.addEventListener('error', () => {});
}
reconnectBtn.addEventListener('click', connect);

// ── Welcome screen ───────────────────────────────────────────────────────────
// The Play button click is the required user gesture for AudioContext unlock.
playBtn.addEventListener('click', () => {
  welcome.classList.add('hidden');
  ensureAudioCtx();
  resumeAudioCtx();
  connect();
});

// ── Keyboard — use e.code for physical-key identity ──────────────────────────
function sendKey(type, k) {
  if (ws && ws.readyState === WebSocket.OPEN)
    ws.send(JSON.stringify({ t: type, k }));
}

const CAPTURE_CODES = new Set([
  'ArrowLeft','ArrowRight','ArrowUp','ArrowDown',
  'Space','Tab','Backspace',
  'F1','F2','F3','F4','F5','F6','F7','F8','F9','F10','F11','F12',
]);

function getGameKey(e) {
  const code = e.code;
  if (!code) return null;
  if (code.startsWith('Key'))   return code.slice(3).toLowerCase();
  if (code.startsWith('Digit')) return code.slice(5);
  if (code === 'ShiftLeft'   || code === 'ShiftRight')   return 'Shift';
  if (code === 'ControlLeft' || code === 'ControlRight') return 'Control';
  if (code === 'AltLeft'     || code === 'AltRight')     return 'Alt';
  if (code === 'MetaLeft'    || code === 'MetaRight')    return 'Meta';
  return code;
}

window.addEventListener('keydown', (e) => {
  if (CAPTURE_CODES.has(e.code)) e.preventDefault();
  if (e.repeat) return;
  const k = getGameKey(e);
  if (k) sendKey('d', k);
});

window.addEventListener('keyup', (e) => {
  if (CAPTURE_CODES.has(e.code)) e.preventDefault();
  const k = getGameKey(e);
  if (k) sendKey('u', k);
});

]]></script>
</body>
</html>
