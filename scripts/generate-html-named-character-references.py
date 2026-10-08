#!/usr/bin/env python3
"""Generates Sources/Ignite/Extensions/HTMLNamedCharacterReferences.swift.

The table is the HTML Standard's list of named character references:

    https://html.spec.whatwg.org/entities.json

Usage, from the root of the package:

    curl -sS -o /tmp/entities.json https://html.spec.whatwg.org/entities.json
    python3 scripts/generate-html-named-character-references.py /tmp/entities.json

The output depends only on the contents of the input: names are written in
code-point order, and nothing about the machine or the time of the run is
recorded. Running it twice on the same list writes the same bytes, and
running it on a newer list shows exactly what the standard added.
"""

import hashlib
import json
import pathlib
import sys

OUTPUT = pathlib.Path("Sources/Ignite/Extensions/HTMLNamedCharacterReferences.swift")

HEADER = '''//
// HTMLNamedCharacterReferences.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//
// GENERATED FILE – do not edit by hand. Regenerate it with
// scripts/generate-html-named-character-references.py.
//
// The table below is the list of named character references from the HTML
// Standard, https://html.spec.whatwg.org/multipage/named-characters.html,
// taken from https://html.spec.whatwg.org/entities.json
// (SHA-256 {digest}).
//
// Copyright © WHATWG (Apple, Google, Mozilla, Microsoft).
//
// The HTML Standard is licensed under the Creative Commons Attribution 4.0
// International License; portions of it incorporated into source code, as
// here, are licensed under the BSD 3-Clause License instead:
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

/// The named character references of the HTML Standard.
enum HTMLNamedCharacterReferences {{
    /// The number of names in the table.
    static let count = {count}

    /// The length of the longest name, counting its semicolon.
    static let longestNameLength = {longest}

    /// The length of the longest name the standard accepts without a semicolon.
    static let longestLegacyNameLength = {longest_legacy}

    /// Every name and the code points it stands for, one reference to a line.
    ///
    /// A line is the name as it follows the `&` – with its semicolon, unless it is one of
    /// the names the standard also accepts without – then `=`, then one or two code
    /// points in hexadecimal, separated by a comma. Lines are in code-point order of
    /// their names. Code points are written as numbers so that this file holds no
    /// invisible or combining characters.
    static let source = """
{lines}
    """
}}
'''


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2

    raw = pathlib.Path(sys.argv[1]).read_bytes()
    entities = json.loads(raw)

    rows = []
    for reference in sorted(entities):
        if not reference.startswith("&"):
            raise SystemExit(f"unexpected name: {reference!r}")
        name = reference[1:]
        body = name[:-1] if name.endswith(";") else name
        if not (body.isascii() and body.isalnum()):
            raise SystemExit(f"name is not ASCII letters and digits: {reference!r}")
        codepoints = ",".join(f"{point:X}" for point in entities[reference]["codepoints"])
        rows.append((name, codepoints))

    names = [name for name, _ in rows]
    legacy = [name for name in names if not name.endswith(";")]
    for name in legacy:
        if name + ";" not in names:
            raise SystemExit(f"{name!r} has no form with a semicolon")

    OUTPUT.write_text(
        HEADER.format(
            digest=hashlib.sha256(raw).hexdigest(),
            count=len(rows),
            longest=max(len(name) for name in names),
            longest_legacy=max(len(name) for name in legacy),
            lines="\n".join(f"    {name}={codepoints}" for name, codepoints in rows),
        ),
        encoding="utf-8",
    )
    print(f"wrote {len(rows)} references to {OUTPUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
