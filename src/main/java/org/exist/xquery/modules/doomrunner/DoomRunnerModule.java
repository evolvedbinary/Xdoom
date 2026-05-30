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

import mochadoom.MochaDoom;
import org.exist.xquery.AbstractInternalModule;
import org.exist.xquery.FunctionDef;
import org.exist.xquery.XPathException;

import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicReference;

public class DoomRunnerModule extends AbstractInternalModule {

    public static final String NAMESPACE_URI = "http://elemental.xyz/xquery/doom-runner";
    public static final String PREFIX = "doom-runner";
    public static final String RELEASED_IN_VERSION = "Elemental-7.0";

    /**
     * JVM-wide singleton. null until the engine is first started.
     * Once set it is never cleared — the MochaDoom engine cannot be restarted
     * within the same JVM (it holds static state).
     */
    public static final AtomicReference<MochaDoom> INSTANCE = new AtomicReference<>(null);

    public static final FunctionDef[] functions = {
        new FunctionDef(DoomRunnerFunctions.startIwad,       DoomRunnerFunctions.class),
        new FunctionDef(DoomRunnerFunctions.startIwadWs,     DoomRunnerFunctions.class),
        new FunctionDef(DoomRunnerFunctions.startIwadWsSkill,      DoomRunnerFunctions.class),
        new FunctionDef(DoomRunnerFunctions.startIwadWsSkillSound, DoomRunnerFunctions.class),
        new FunctionDef(DoomRunnerFunctions.stop,        DoomRunnerFunctions.class),
        new FunctionDef(DoomRunnerFunctions.pause,       DoomRunnerFunctions.class),
        new FunctionDef(DoomRunnerFunctions.resume,      DoomRunnerFunctions.class),
        new FunctionDef(DoomRunnerFunctions.isRunning,   DoomRunnerFunctions.class),
        new FunctionDef(DoomRunnerFunctions.isPaused,    DoomRunnerFunctions.class),
        new FunctionDef(DoomRunnerFunctions.iwadPath,    DoomRunnerFunctions.class),
    };

    static {
        Arrays.sort(functions, new FunctionComparator());
    }

    public DoomRunnerModule(final Map<String, List<?>> parameters) throws XPathException {
        super(functions, parameters, true);
    }

    @Override
    public String getNamespaceURI() {
        return NAMESPACE_URI;
    }

    @Override
    public String getDefaultPrefix() {
        return PREFIX;
    }

    @Override
    public String getDescription() {
        return "A module for running the MochaDoom game engine inside eXist-db.";
    }

    @Override
    public String getReleaseVersion() {
        return RELEASED_IN_VERSION;
    }
}
