import Carbon

package enum LaunchKind {
    package static func isLoginItem(propData: OSType?) -> Bool {
        propData == OSType(keyAELaunchedAsLogInItem)
    }
}
