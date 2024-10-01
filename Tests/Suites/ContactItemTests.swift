import XCTest
import Contacts
@testable import ChatSDK

final class ContactItemTests: XCTestCase {

    func testFullName() {
        // Arrange
        let contact = CNMutableContact()
        contact.givenName = "John"
        contact.familyName = "Doe"

        // Act
        let contactItem = ContactItem(contact: contact)

        // Assert
        XCTAssertEqual(contactItem.fullName, "John Doe")
    }

    func testFullNameWithoutGivenName() {
        // Arrange
        let contact = CNMutableContact()
        contact.givenName = ""
        contact.familyName = "Doe"

        // Act
        let contactItem = ContactItem(contact: contact)

        // Assert
        XCTAssertEqual(contactItem.fullName, "Doe")
    }

    func testFullNameWithoutFamilyname() {
        // Arrange
        let contact = CNMutableContact()
        contact.givenName = "John"
        contact.familyName = ""

        // Act
        let contactItem = ContactItem(contact: contact)

        // Assert
        XCTAssertEqual(contactItem.fullName, "John")
    }

    func testPhone() {
        // Arrange
        let phoneNumber = CNLabeledValue(
            label: CNLabelPhoneNumberMobile,
            value: CNPhoneNumber(stringValue: "123-456-7890")
        )
        let contact = CNMutableContact()
        contact.phoneNumbers = [phoneNumber]

        // Act
        let contactItem = ContactItem(contact: contact)

        // Assert
        XCTAssertEqual(contactItem.phone, "123-456-7890")
    }

    func testNoPhone() {
        // Arrange
        let contact = CNMutableContact()

        // Act
        let contactItem = ContactItem(contact: contact)

        // Assert
        XCTAssertNil(contactItem.phone)
    }

    func testVCardSerialization() {
        // Arrange
        let contact = CNMutableContact()
        contact.givenName = "John"
        contact.familyName = "Doe"

        // Act
        let contactItem = ContactItem(contact: contact)
        let vCardData = contactItem.asVCard()

        // Assert
        XCTAssertNotNil(vCardData)
        XCTAssertNoThrow(try CNContactVCardSerialization.contacts(with: vCardData!))
    }

    func testContactInitializationFromData() {
        // Arrange
        let contact = CNMutableContact()
        contact.givenName = "John"
        contact.familyName = "Doe"

        // Act
        let vCardData = try? CNContactVCardSerialization.data(with: [contact])
        let contactItem = ContactItem(data: vCardData!)

        // Assert
        XCTAssertNotNil(contactItem)
        XCTAssertEqual(contactItem?.fullName, "John Doe")
    }

    func testContactInitializationFromInvalidData() {
        // Arrange
        let invalidData = Data()

        // Act
        let contactItem = ContactItem(data: invalidData)

        // Assert
        XCTAssertNil(contactItem, "Expected initialization from invalid data to return nil")
    }
}
