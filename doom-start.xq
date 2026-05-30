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

(:~
  Start the MochaDoom game engine with WebSocket frame streaming.
  doom:iwad-path() resolves the bundled doom1.wad from the module JAR automatically.
  Change $ws-port if needed, then open http://localhost:{$ws-port} in a browser to play.
:)

declare variable $iwad     as xs:string  external := doom:iwad-path();
declare variable $ws-port  as xs:integer external := 3001;
declare variable $skill    as xs:integer external := 2;
declare variable $no-sound as xs:boolean external := false();
declare variable $no-music as xs:boolean external := false();

return
  if (doom:is-running()) then
    "Game is already running — run doom-stop.xq first (then restart Elemental)."
  else (
    doom:start($iwad, $ws-port, $skill, $no-sound, $no-music),
    "Game started. Open http://localhost:" || $ws-port || " in a browser to play."
  )
