//
// RunCommand.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import ArgumentParser
import Foundation

/// The command that lets users run their Ignite site
/// back in a local web server.
struct RunCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Start a local web server for the current site."
    )

    /// The server's port number. Defaults to 8000.
    @Option(name: .shortAndLong, help: "The port number to run the local server on.")
    var port = 8000

    /// The name of the site's output directory. Defaults to Build.
    @Option(name: .shortAndLong, help: "The name of your build directory.")
    var directory = "Build"

    /// Whether to open a web browser pointing at the local
    /// web server. Defaults to false.
    @Flag(help: "Whether to open the server in your preferred web browser immediately.")
    var preview = false

    /// Runs this command. Automatically called by Argument Parser.
    /// - Throws: `ExitCode.failure` when the server could not be started, so the tool
    /// exits with a non-zero status and a script that called it can tell.
    func run() throws {
        try run(output: .standard, errors: .standardError)
    }

    /// Serves the site, saying what happened on the outputs given.
    /// - Parameters:
    ///   - output: Receives the server's address and how to stop it.
    ///   - errors: Receives the reasons the server could not be started.
    /// - Throws: `ExitCode.failure` once the reason has been written to `errors`, when
    /// there is no directory to serve, no free port, or the server script is missing.
    func run(output: Output, errors: Output) throws {
        // Make sure we actually have a folder to serve up.
        guard FileManager.default.fileExists(atPath: "./\(directory)") else {
            logger.error("Nothing to serve: no directory named \(directory, privacy: .public).")
            errors.line("❌ Failed to find directory named '\(directory)'.")
            throw ExitCode.failure
        }

        // Detect if the site is an subsite
        let subsite = identifySubsite(directory: directory) ?? ""

        // Find an available port
        var currentPort = port
        while try isServerRunning(on: currentPort) {
            currentPort += 1
            if currentPort >= 9000 {
                logger.error("No free port below 9000, starting from \(port, privacy: .public).")
                errors.line("❌ No available ports found in range 8000-8999.")
                throw ExitCode.failure
            }
        }

        let previewCommand: [String] =
            if preview {
                // Automatically open a web browser pointing to their
                // local server if requested.
                ["open", "http://localhost:\(currentPort)\(subsite)"]
            } else {
                // Important: Passing an array at all, even this empty
                // one, is what makes Process.execute() wait for a key
                // press before exiting.
                []
            }

        // Find the server script installed next to the tool itself
        let tool = ProcessInfo.processInfo.arguments.first ?? "NEVER"
        let dirLoc = tool.lastIndex(of: "/") ?? tool.endIndex
        let toolDir = String(tool[..<dirLoc])
        let serverScriptURL = URL(filePath: "\(toolDir)/ignite-server.py")

        // Verify server script exists
        guard FileManager.default.fileExists(atPath: serverScriptURL.path) else {
            logger.error("Server script missing at \(serverScriptURL.path, privacy: .public).")
            errors.line("❌ Critical server script missing: \(serverScriptURL.path)")
            errors.line("   This suggests a corrupted installation. Please reinstall with:")
            errors.line("   make clean && make install")
            throw ExitCode.failure
        }

        logger.info("Serving \(directory, privacy: .public) on port \(currentPort, privacy: .public).")
        output.line("✅ Starting local web server on http://localhost:\(currentPort)\(subsite)")

        writeQRCode(port: currentPort, subsite: subsite, to: output)

        output.line("Press ↵ Return to exit.")

        let subsiteArguments = subsite.isEmpty ? [] : ["-s", subsite]
        try Process.execute(
            command: ["python3", serverScriptURL.path, "-d", directory] + subsiteArguments + [String(currentPort)],
            then: previewCommand
        )
    }

    /// Returns true if there is a server running on the specified port.
    private func isServerRunning(on port: Int) throws -> Bool {
        let result = try Process.execute(command: ["lsof", "-t", "-i", "tcp:\(port)"], timeout: 30)
        return !result.output.isEmpty
    }

    /// Generates a QR code for the site's address on the local network and writes
    /// it to `output`. Writes nothing when the address or the code is unavailable.
    private func writeQRCode(port: Int, subsite: String, to output: Output) {
        #if canImport(CoreImage)
        guard let ipAddress = getLocalIPAddress() else { return }
        let localURL = "http://\(ipAddress):\(port)\(subsite)"

        let qrCode: QRCode
        do {
            qrCode = try QRCode(utf8String: localURL)
        } catch {
            // The server is still reachable by its address; only the shortcut is lost.
            logger.warning("Could not make a QR code: \(error.localizedDescription, privacy: .public)")
            return
        }

        output.line("\n📱 Scan this QR code to access the site on your mobile device:\n")
        output.line(qrCode.smallAsciiRepresentation())
        output.line("URL: \(localURL)\n")
        #endif
    }

    /// Returns the local IP address of the machine.
    private func getLocalIPAddress() -> String? {
        var localIPAddress: String?
        var interfaceAddressPointer: UnsafeMutablePointer<ifaddrs>?

        if getifaddrs(&interfaceAddressPointer) == 0 {
            var currentPointer = interfaceAddressPointer
            while currentPointer != nil {
                defer { currentPointer = currentPointer?.pointee.ifa_next }

                guard let networkInterface = currentPointer?.pointee else { continue }
                let addressFamily = networkInterface.ifa_addr.pointee.sa_family

                if addressFamily == UInt8(AF_INET) {
                    let interfaceName = String(cString: networkInterface.ifa_name)
                    var hostNameBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    // Use sizeof(sockaddr_in) for IPv4 addresses
                    getnameinfo(networkInterface.ifa_addr, socklen_t(MemoryLayout<sockaddr_in>.size),
                                &hostNameBuffer, socklen_t(hostNameBuffer.count),
                                nil, socklen_t(0), NI_NUMERICHOST)

                    let ipAddressBytes = hostNameBuffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
                    let ipAddress = String(decoding: ipAddressBytes, as: UTF8.self)

                    // Pick the first non-loopback address
                    if interfaceName != "lo0" {
                        localIPAddress = ipAddress
                        break
                    }
                }
            }
            freeifaddrs(interfaceAddressPointer)
        }

        return localIPAddress
    }

    /// Identify subsite by looking at the canonical url of 
    /// the root index.html of given directory
    private func identifySubsite(directory: String) -> String? {
        // Find the root index.html
        guard let indexData = FileManager.default.contents(atPath: "\(directory)/index.html") else { return nil }

        // Locate and extract the canonical url 
        let indexString = String(decoding: indexData, as: UTF8.self)
        // Tag intentionally not closed to allow space and `>`, `/>`
        let regex = #/<link href="([^"]+)" rel="canonical"/#
        guard let urlSubString = indexString.firstMatch(of: regex)?.1 else { return nil }

        // Only the path of the canonical URL is wanted, so take the address apart
        // rather than building a URL from it; nothing here contacts that address.
        guard let canonical = URLComponents(string: String(urlSubString)) else { return nil }

        // URL.path, which this used to read, leaves trailing slashes off; keep doing so.
        var path = canonical.path
        while path.count > 1, path.hasSuffix("/") {
            path.removeLast()
        }

        // If there is no subsite, we don't want to return anything
        guard path != "/" else { return nil }

        return path
    }
}
