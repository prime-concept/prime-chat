import XCTest
import Contacts
@testable import ChatSDK

final class ContactsServiceTests: XCTestCase {

    var contactStoreMock: CNContactStoreMock!
    var contactsService: ContactsService!

    override func setUp() {
        super.setUp()
        contactStoreMock = CNContactStoreMock()
        contactsService = ContactsService(store: contactStoreMock)
    }

    override func tearDown() {
        contactStoreMock = nil
        contactsService = nil
        super.tearDown()
    }

    func testFetchContactsAuthorized() {
        // Arrange
        CNContactStoreMock.authorizationStatus = .authorized
        let contact = CNMutableContact()
        contact.givenName = "John"
        contact.familyName = "Doe"
        contactStoreMock.contacts = [contact]
        let expectation = expectation(description: "Fetch Contacts")

        // Act
        contactsService.fetchContacts { result in
            switch result {
            case .success(let contacts):
                XCTAssertEqual(contacts.count, 1)
            case .failure:
                XCTFail("Expected success but got failure")
            }
            expectation.fulfill()
        }

        // Assert
        waitForExpectations(timeout: 1.0)
    }

    func testFetchContactsDenied() {
        // Arrange
        CNContactStoreMock.authorizationStatus = .denied
        let expectation = expectation(description: "Fetch Contacts")

        // Act
        contactsService.fetchContacts { result in
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let error):
                XCTAssertEqual(error as? ContactsService.Error, ContactsService.Error.noPermission)
            }
            expectation.fulfill()
        }
        // Assert
        waitForExpectations(timeout: 1.0)
    }

    func testFetchContactsNotDetermined() {
        // Arrange
        CNContactStoreMock.authorizationStatus = .notDetermined
        let expectation = expectation(description: "Fetch Contacts")

        // Act
        contactsService.fetchContacts { result in
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let error):
                XCTAssertEqual(error as? ContactsService.Error, ContactsService.Error.noPermission)
            }
            expectation.fulfill()
        }
        // Assert
        waitForExpectations(timeout: 1.0)
    }

    func testFetchContactsNotAuthorized() {
        // Arrange
        CNContactStoreMock.authorizationStatus = .restricted
        let expectation = expectation(description: "Fetch Contacts")

        // Act
        contactsService.fetchContacts { result in
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let error):
                XCTAssertEqual(error as? ContactsService.Error, ContactsService.Error.noPermission)
            }
            expectation.fulfill()
        }
        // Assert
        waitForExpectations(timeout: 1.0)
    }

    func testFetchContactsWithRequestError() {
        // Arrange
        CNContactStoreMock.authorizationStatus = .authorized
        contactStoreMock.shouldThrowError = true
        let contact = CNMutableContact()
        contact.givenName = "John"
        contact.familyName = "Doe"
        contactStoreMock.contacts = [contact]
        let expectation = expectation(description: "Fetch Contacts")

        // Act
        contactsService.fetchContacts { result in
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let error):
                XCTAssertEqual(error as? ContactsService.Error, ContactsService.Error.invalidRequest)
            }
            expectation.fulfill()
        }

        // Assert
        waitForExpectations(timeout: 1.0)
    }
}
