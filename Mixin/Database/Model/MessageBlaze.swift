import Foundation
import WCDBSwift

struct MessageBlaze: BaseCodable {

    static var tableName: String = "messages_blaze"

    let messageId: String
    let message: Data
    let createdAt: String

    enum CodingKeys: String, CodingTableKey {
        typealias Root = MessageBlaze
        case messageId = "_id"
        case message
        case createdAt = "created_at"

        static let objectRelationalMapping = TableBinding(CodingKeys.self)
        static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
            return [
                messageId: ColumnConstraintBinding(isPrimary: true)
            ]
        }
        static var indexBindings: [IndexBinding.Subfix: IndexBinding]? {
            return [
                "_index": IndexBinding(indexesBy: [createdAt])
            ]
        }
    }

}
