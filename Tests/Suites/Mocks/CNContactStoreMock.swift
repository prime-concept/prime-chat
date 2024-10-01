import Contacts
@testable import ChatSDK

class CNContactStoreMock: CNContactStore {
    static var authorizationStatus: CNAuthorizationStatus = .notDetermined
    var requestAccessResult = false
    var shouldThrowError = false
    var contacts: [CNContact] = []

    override class func authorizationStatus(for entityType: CNEntityType) -> CNAuthorizationStatus {
        authorizationStatus
    }

    override func requestAccess(for entityType: CNEntityType, completionHandler: @escaping (Bool, Error?) -> Void) {
        completionHandler(requestAccessResult, nil)
    }

    override func enumerateContacts(
        with fetchRequest: CNContactFetchRequest,
        usingBlock block: (CNContact, UnsafeMutablePointer<ObjCBool>) -> Void
    ) throws {
        guard !shouldThrowError else {
            throw ContactsService.Error.invalidRequest
        }
        for contact in contacts {
            block(contact, UnsafeMutablePointer<ObjCBool>.allocate(capacity: 1))
        }
    }
}
