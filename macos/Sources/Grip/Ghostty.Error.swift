extension Grip {
    /// Possible errors from internal Grip calls.
    enum Error: Swift.Error, CustomLocalizedStringResourceConvertible {
        case apiFailed

        var localizedStringResource: LocalizedStringResource {
            switch self {
            case .apiFailed: return "libgrip API call failed"
            }
        }
    }
}
