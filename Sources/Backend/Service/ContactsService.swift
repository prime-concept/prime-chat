import Foundation
import Contacts

protocol VCardRepresentable {
    func asVCard() -> Data?
}

protocol ContactsServiceProtocol: AnyObject {
    func fetchContacts(completion: @escaping (Result<[ContactItem], Swift.Error>) -> Void)
}

struct ContactItem: VCardRepresentable, DataInitializable {
    let contact: CNContact

    var fullName: String {
        [self.contact.givenName, self.contact.familyName].filter { !$0.isEmpty }.joined(separator: " ")
    }

    var phone: String? {
        self.contact.phoneNumbers.first?.value.stringValue
    }

    init(contact: CNContact) {
        self.contact = contact
    }

    init?(data: Data) {
        guard let contact = Self.contact(from: data) else {
            return nil
        }

        self.contact = contact
    }

    private static func contact(from data: Data) -> CNContact? {
        (try? CNContactVCardSerialization.contacts(with: data))?.first
    }

    func asVCard() -> Data? {
        try? CNContactVCardSerialization.data(with: [self.contact])
    }
}

protocol CNContactStoreProtocol {
    static func authorizationStatus(
        for entityType: CNEntityType
    ) -> CNAuthorizationStatus

    func enumerateContacts(
        with fetchRequest: CNContactFetchRequest,
        usingBlock block: (
            CNContact,
            UnsafeMutablePointer<ObjCBool>
        ) -> Void
    ) throws

    func requestAccess(for entityType: CNEntityType, completionHandler: @escaping (Bool, Error?) -> Void)
}

extension CNContactStore: CNContactStoreProtocol { }

final class ContactsService: ContactsServiceProtocol {

    private let storeType: CNContactStoreProtocol.Type
    private let store: CNContactStoreProtocol

    init(store: CNContactStoreProtocol = CNContactStore()) {
        self.store = store
        self.storeType = type(of: store)
    }

    func fetchContacts(completion: @escaping (Result<[ContactItem], Swift.Error>) -> Void) {
        let status = storeType.authorizationStatus(for: .contacts)

        switch status {
        case .denied, .restricted:
            completion(.failure(Error.noPermission))

        case .notDetermined:
            store.requestAccess(for: .contacts) { [weak self] (success, error) in
                guard let self else { return }
                if !success || error != nil {
                    completion(.failure(Error.noPermission))
                } else {
                    fetchContactsWithPermissions(store: self.store, completion: completion)
                }
            }

        case .authorized:
            fetchContactsWithPermissions(store: store, completion: completion)

        @unknown default:
            assertionFailure("Unsupported status")
        }
    }

    // MARK: - Private

    private func fetchContactsWithPermissions(
        store: CNContactStoreProtocol,
        completion: @escaping (Result<[ContactItem], Swift.Error>) -> Void
    ) {
        let request = CNContactFetchRequest(
            keysToFetch: [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor
            ]
        )

        var contacts: [ContactItem] = []

        do {
            try store.enumerateContacts(with: request) { (contact, _) in
                contacts.append(ContactItem(contact: contact))
            }

            completion(.success(contacts))
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) fetchContactsWithPermissions",
                "details": "\(#function) contacts service: unable to fetch contacts",
                "error": error
            ]
            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

            log(sender: self, "contacts service: unable to fetch contacts, error = \(error)")
            completion(.failure(Error.invalidRequest))
        }
    }

    // MARK: - Enums

    enum Error: Swift.Error {
        case invalidRequest
        case noPermission
    }
}
