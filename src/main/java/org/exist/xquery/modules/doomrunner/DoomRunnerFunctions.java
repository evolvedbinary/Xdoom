/*
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
 */
package org.exist.xquery.modules.doomrunner;

import mochadoom.DoomConfig;
import mochadoom.MochaDoom;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.concurrent.atomic.AtomicReference;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.exist.dom.QName;
import org.exist.xquery.BasicFunction;
import org.exist.xquery.Cardinality;
import org.exist.xquery.FunctionSignature;
import org.exist.xquery.XPathException;
import org.exist.xquery.XQueryContext;
import org.exist.xquery.value.BooleanValue;
import org.exist.xquery.value.FunctionParameterSequenceType;
import org.exist.xquery.value.FunctionReturnSequenceType;
import org.exist.xquery.value.IntegerValue;
import org.exist.xquery.value.Sequence;
import org.exist.xquery.value.SequenceType;
import org.exist.xquery.value.StringValue;
import org.exist.xquery.value.Type;

public class DoomRunnerFunctions extends BasicFunction {

    private static final Logger logger = LogManager.getLogger(DoomRunnerFunctions.class);

    /** Caches the path of the extracted bundled WAD so we only extract it once per JVM. */
    private static final AtomicReference<Path> BUNDLED_WAD_PATH = new AtomicReference<>(null);

    public static final FunctionSignature startIwad = new FunctionSignature(
        new QName("start", DoomRunnerModule.NAMESPACE_URI, DoomRunnerModule.PREFIX),
        "Start the MochaDoom game engine in headless mode with the given IWAD path. " +
        "Throws an error if the engine has already been started in this JVM.",
        new SequenceType[] {
            new FunctionParameterSequenceType("iwad", Type.STRING, Cardinality.EXACTLY_ONE,
                "File-system path to the IWAD (e.g. doom.wad, freedoom1.wad)")
        },
        new SequenceType(Type.EMPTY_SEQUENCE, Cardinality.EMPTY_SEQUENCE)
    );

    public static final FunctionSignature startIwadWs = new FunctionSignature(
        new QName("start", DoomRunnerModule.NAMESPACE_URI, DoomRunnerModule.PREFIX),
        "Start the MochaDoom game engine with the given IWAD path and WebSocket port. " +
        "Frames are streamed to browser clients over WebSocket. " +
        "Throws an error if the engine has already been started in this JVM.",
        new SequenceType[] {
            new FunctionParameterSequenceType("iwad", Type.STRING, Cardinality.EXACTLY_ONE,
                "File-system path to the IWAD"),
            new FunctionParameterSequenceType("websocket-port", Type.INTEGER, Cardinality.EXACTLY_ONE,
                "TCP port for the embedded WebSocket server")
        },
        new SequenceType(Type.EMPTY_SEQUENCE, Cardinality.EMPTY_SEQUENCE)
    );

    public static final FunctionSignature startIwadWsSkill = new FunctionSignature(
        new QName("start", DoomRunnerModule.NAMESPACE_URI, DoomRunnerModule.PREFIX),
        "Start the MochaDoom game engine with the given IWAD path, WebSocket port, and skill level. " +
        "Skill: 1=ITYTD, 2=HNTR, 3=HMP, 4=UV, 5=Nightmare. " +
        "Throws an error if the engine has already been started in this JVM.",
        new SequenceType[] {
            new FunctionParameterSequenceType("iwad", Type.STRING, Cardinality.EXACTLY_ONE,
                "File-system path to the IWAD"),
            new FunctionParameterSequenceType("websocket-port", Type.INTEGER, Cardinality.EXACTLY_ONE,
                "TCP port for the embedded WebSocket server"),
            new FunctionParameterSequenceType("skill", Type.INTEGER, Cardinality.EXACTLY_ONE,
                "Skill level: 1=ITYTD 2=HNTR 3=HMP 4=UV 5=Nightmare")
        },
        new SequenceType(Type.EMPTY_SEQUENCE, Cardinality.EMPTY_SEQUENCE)
    );

    public static final FunctionSignature startIwadWsSkillSound = new FunctionSignature(
        new QName("start", DoomRunnerModule.NAMESPACE_URI, DoomRunnerModule.PREFIX),
        "Start the MochaDoom game engine with full audio control. " +
        "In WebSocket mode SFX are streamed as type-0x02 frames and music as type-0x03 frames " +
        "(music requires the JVM flag --add-opens java.desktop/com.sun.media.sound=ALL-UNNAMED). " +
        "Skill: 1=ITYTD, 2=HNTR, 3=HMP, 4=UV, 5=Nightmare. " +
        "Throws an error if the engine has already been started in this JVM.",
        new SequenceType[] {
            new FunctionParameterSequenceType("iwad", Type.STRING, Cardinality.EXACTLY_ONE,
                "File-system path to the IWAD"),
            new FunctionParameterSequenceType("websocket-port", Type.INTEGER, Cardinality.EXACTLY_ONE,
                "TCP port for the embedded WebSocket server"),
            new FunctionParameterSequenceType("skill", Type.INTEGER, Cardinality.EXACTLY_ONE,
                "Skill level: 1=ITYTD 2=HNTR 3=HMP 4=UV 5=Nightmare"),
            new FunctionParameterSequenceType("no-sound", Type.BOOLEAN, Cardinality.EXACTLY_ONE,
                "true() to disable all audio (SFX and music)"),
            new FunctionParameterSequenceType("no-music", Type.BOOLEAN, Cardinality.EXACTLY_ONE,
                "true() to disable music only; SFX still streams")
        },
        new SequenceType(Type.EMPTY_SEQUENCE, Cardinality.EMPTY_SEQUENCE)
    );

    public static final FunctionSignature stop = new FunctionSignature(
        new QName("stop", DoomRunnerModule.NAMESPACE_URI, DoomRunnerModule.PREFIX),
        "Interrupt the game-loop thread. Returns immediately; the thread exits within one tick. " +
        "No-op if the engine was never started.",
        new SequenceType[0],
        new SequenceType(Type.EMPTY_SEQUENCE, Cardinality.EMPTY_SEQUENCE)
    );

    public static final FunctionSignature pause = new FunctionSignature(
        new QName("pause", DoomRunnerModule.NAMESPACE_URI, DoomRunnerModule.PREFIX),
        "Halt the game loop until doom-runner:resume() is called. " +
        "Throws an error if the engine has not been started.",
        new SequenceType[0],
        new SequenceType(Type.EMPTY_SEQUENCE, Cardinality.EMPTY_SEQUENCE)
    );

    public static final FunctionSignature resume = new FunctionSignature(
        new QName("resume", DoomRunnerModule.NAMESPACE_URI, DoomRunnerModule.PREFIX),
        "Unblock a paused game loop. Throws an error if the engine has not been started.",
        new SequenceType[0],
        new SequenceType(Type.EMPTY_SEQUENCE, Cardinality.EMPTY_SEQUENCE)
    );

    public static final FunctionSignature isRunning = new FunctionSignature(
        new QName("is-running", DoomRunnerModule.NAMESPACE_URI, DoomRunnerModule.PREFIX),
        "Returns true if the game-loop thread is alive.",
        new SequenceType[0],
        new FunctionReturnSequenceType(Type.BOOLEAN, Cardinality.EXACTLY_ONE,
            "true if the game is currently running")
    );

    public static final FunctionSignature isPaused = new FunctionSignature(
        new QName("is-paused", DoomRunnerModule.NAMESPACE_URI, DoomRunnerModule.PREFIX),
        "Returns true if the game loop is currently paused.",
        new SequenceType[0],
        new FunctionReturnSequenceType(Type.BOOLEAN, Cardinality.EXACTLY_ONE,
            "true if the game is currently paused")
    );

    public static final FunctionSignature iwadPath = new FunctionSignature(
        new QName("iwad-path", DoomRunnerModule.NAMESPACE_URI, DoomRunnerModule.PREFIX),
        "Returns the file-system path of the bundled doom1.wad IWAD, extracting it " +
        "from the module JAR to a temporary file on first call.",
        new SequenceType[0],
        new FunctionReturnSequenceType(Type.STRING, Cardinality.EXACTLY_ONE,
            "Absolute file-system path to the bundled doom1.wad")
    );

    public DoomRunnerFunctions(final XQueryContext context, final FunctionSignature signature) {
        super(context, signature);
    }

    @Override
    public Sequence eval(final Sequence[] args, final Sequence contextSequence) throws XPathException {
        if (getSignature().equals(startIwad)) {
            return evalStart(args[0].getStringValue(), -1, -1, false, false);

        } else if (getSignature().equals(startIwadWs)) {
            final int port = ((IntegerValue) args[1].itemAt(0)).getInt();
            return evalStart(args[0].getStringValue(), port, -1, false, false);

        } else if (getSignature().equals(startIwadWsSkill)) {
            final int port  = ((IntegerValue) args[1].itemAt(0)).getInt();
            final int skill = ((IntegerValue) args[2].itemAt(0)).getInt();
            return evalStart(args[0].getStringValue(), port, skill, false, false);

        } else if (getSignature().equals(startIwadWsSkillSound)) {
            final int port     = ((IntegerValue) args[1].itemAt(0)).getInt();
            final int skill    = ((IntegerValue) args[2].itemAt(0)).getInt();
            final boolean noSound = args[3].effectiveBooleanValue();
            final boolean noMusic = args[4].effectiveBooleanValue();
            return evalStart(args[0].getStringValue(), port, skill, noSound, noMusic);

        } else if (getSignature().equals(stop)) {
            final MochaDoom doom = DoomRunnerModule.INSTANCE.get();
            if (doom != null) {
                doom.stop();
                logger.info("doom-runner: stop() called");
            }
            return Sequence.EMPTY_SEQUENCE;

        } else if (getSignature().equals(pause)) {
            requireRunningInstance("pause").pause();
            return Sequence.EMPTY_SEQUENCE;

        } else if (getSignature().equals(resume)) {
            requireRunningInstance("resume").resume();
            return Sequence.EMPTY_SEQUENCE;

        } else if (getSignature().equals(isRunning)) {
            final MochaDoom doom = DoomRunnerModule.INSTANCE.get();
            return new BooleanValue(this, doom != null && doom.isRunning());

        } else if (getSignature().equals(isPaused)) {
            final MochaDoom doom = DoomRunnerModule.INSTANCE.get();
            return new BooleanValue(this, doom != null && doom.isPaused());

        } else if (getSignature().equals(iwadPath)) {
            return new StringValue(this, extractBundledWad().toAbsolutePath().toString());

        } else {
            throw new XPathException(this, "doom-runner: unknown function signature: " + getSignature());
        }
    }

    private Path extractBundledWad() throws XPathException {
        final Path existing = BUNDLED_WAD_PATH.get();
        if (existing != null) {
            return existing;
        }
        try (final InputStream is = DoomRunnerFunctions.class.getResourceAsStream("/doom1.wad")) {
            if (is == null) {
                throw new XPathException(this,
                    "doom-runner:iwad-path() — doom1.wad not found in module JAR; " +
                    "ensure the WAD is present at src/main/resources/doom1.wad and the module is rebuilt.");
            }
            // The file must be named exactly "doom1.wad" so MochaDoom's DoomVersion enum lookup succeeds.
            final Path tmpDir = Files.createTempDirectory("doom-runner-");
            tmpDir.toFile().deleteOnExit();
            final Path tmp = tmpDir.resolve("doom1.wad");
            tmp.toFile().deleteOnExit();
            Files.copy(is, tmp, StandardCopyOption.REPLACE_EXISTING);
            BUNDLED_WAD_PATH.compareAndSet(null, tmp);
            logger.info("doom-runner: bundled WAD extracted to {}", BUNDLED_WAD_PATH.get());
            return BUNDLED_WAD_PATH.get();
        } catch (final IOException e) {
            throw new XPathException(this,
                "doom-runner:iwad-path() — failed to extract bundled WAD: " + e.getMessage(), e);
        }
    }

    private Sequence evalStart(final String iwad, final int wsPort, final int skill,
                               final boolean noSound, final boolean noMusic) throws XPathException {
        final DoomConfig.Builder builder = DoomConfig.builder()
            .iwad(iwad)
            .noSound(noSound)
            .noMusic(noMusic);

        if (wsPort >= 0) {
            builder.webSocketPort(wsPort); // implies headless; SFX→0x02 frames, music→0x03 frames
            builder.extraArgs("-fps", "60");
        } else {
            builder.headless(true);
        }

        if (skill >= 1 && skill <= 5) {
            builder.extraArgs("-skill", String.valueOf(skill));
        }

        final MochaDoom doom = new MochaDoom(builder.build());

        if (!DoomRunnerModule.INSTANCE.compareAndSet(null, doom)) {
            throw new XPathException(this,
                "doom-runner:start() — the MochaDoom engine has already been started " +
                "in this JVM and cannot be started again.");
        }

        try {
            doom.start();
            logger.info("doom-runner: engine started (iwad={}, wsPort={}, skill={}, noSound={}, noMusic={})",
                iwad, wsPort, skill, noSound, noMusic);
        } catch (final IOException | IllegalStateException e) {
            throw new XPathException(this,
                "doom-runner:start() — engine failed to start: " + e.getMessage(), e);
        }

        return Sequence.EMPTY_SEQUENCE;
    }

    private MochaDoom requireRunningInstance(final String fnName) throws XPathException {
        final MochaDoom doom = DoomRunnerModule.INSTANCE.get();
        if (doom == null) {
            throw new XPathException(this,
                "doom-runner:" + fnName + "() — the engine has not been started; " +
                "call doom-runner:start() first.");
        }
        return doom;
    }
}
