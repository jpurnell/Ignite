//
// Script.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Testing

@testable import Ignite

/// Tests for the `Script` element.
@Suite("Script Tests")
class ScriptTests: IgniteTestSuite {
    @Test("Code", .publishingContext(), arguments: TestPublishingSite.standardAndSubsite)
    func code(for siteCase: TestPublishingSite) async throws {
        let site = siteCase.site

        let output = try withPublishingContext(for: site) { _ in
            let element = Script(code: "javascript code")
            return element.markupString()
        }
        
        #expect(output == "<script>javascript code</script>")
    }
    
    @Test("Local File", .publishingContext(), arguments: ["/code.js"], TestPublishingSite.standardAndSubsite)
    func file(scriptFile: String, siteCase: TestPublishingSite) async throws {
        let site = siteCase.site

        try withPublishingContext(for: site) { context in
            let element = Script(file: scriptFile)
            let output = element.markupString()

            // A root-relative script is resolved like any other asset: as given on a root
            // site, and under the subsite's path on a subsite.
            let expected = siteCase == .subsite ? "/subsite/code.js" : "/code.js"
            #expect(output == "<script src=\"\(expected)\"></script>")
        }
    }
    
    @Test("Remote File", .publishingContext(), arguments: ["https://example.com"], TestPublishingSite.standardAndSubsite)
    func file(remoteScript: String, siteCase: TestPublishingSite) async throws {
        let site = siteCase.site

        try withPublishingContext(for: site) { context in
            let element = Script(file: remoteScript)
            let output = element.markupString()

            #expect(output == "<script src=\"\(remoteScript)\"></script>")
        }
    }
    
    @Test("Attributes", .publishingContext(), arguments: ["/code.js"], TestPublishingSite.standardAndSubsite)
    func attributes(scriptFile: String, siteCase: TestPublishingSite) async throws {
        let site = siteCase.site

        try withPublishingContext(for: site) { context in
            let element = Script(file: scriptFile)
                .data("key", "value")
                .customAttribute(name: "custom", value: "part")
            let output = element.markupString()

            let expected = siteCase == .subsite ? "/subsite/code.js" : "/code.js"
            #expect(output == "<script custom=\"part\" src=\"\(expected)\" data-key=\"value\"></script>")
        }
    }
    
    @Test("TypeAttribute", .publishingContext(), arguments: TestPublishingSite.standardAndSubsite)
    func typeAttribute(for siteCase: TestPublishingSite) async throws {
        let site = siteCase.site

        let output = try withPublishingContext(for: site) { _ in
            let element = Script(code: "javascript code").type(value: "someType")
            return element.markupString()
        }
        
        #expect(output == "<script type=\"someType\">javascript code</script>")
    }
}
