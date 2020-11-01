import Foundation

extension ProcessInfo {
    #if os(macOS)
    /// Returns a `String` representing the machine hardware name or nil if there was an error invoking `uname(_:)` or decoding the response.
    ///
    /// Return value is the equivalent to running `$ uname -m` in shell.
    var machineHardwareName: String? {
        var sysinfo = utsname()
        let result = uname(&sysinfo)
        guard result == EXIT_SUCCESS else { return nil }

        let data = Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN))

        guard let identifier = String(bytes: data, encoding: .ascii) else { return nil }
        return identifier.trimmingCharacters(in: .controlCharacters)
    }
    #endif
}
