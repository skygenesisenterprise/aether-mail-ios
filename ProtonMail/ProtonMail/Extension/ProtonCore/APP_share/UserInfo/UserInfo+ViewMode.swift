import ProtonCoreDataModel

enum ViewMode: Int, CaseIterable {
    case conversation = 0
    case singleMessage = 1
}

extension UserInfo {

    var viewMode: ViewMode {
        ViewMode(rawValue: groupingMode) ?? .conversation
    }

}
