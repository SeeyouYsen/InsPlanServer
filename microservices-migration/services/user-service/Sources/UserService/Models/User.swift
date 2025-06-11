import Fluent
import Vapor
import JWT

// MARK: - 用户模型
final class User: Model, Authenticatable, @unchecked Sendable {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "email")
    var email: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Field(key: "first_name")
    var firstName: String
    
    @Field(key: "last_name")
    var lastName: String
    
    @Field(key: "phone")
    var phone: String?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() { }

    init(id: UUID? = nil, email: String, passwordHash: String, firstName: String, lastName: String, phone: String? = nil) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
    }
}

// MARK: - 用户资料模型
final class UserProfile: Model, @unchecked Sendable {
    static let schema = "user_profiles"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @Field(key: "birth_date")
    var birthDate: Date?
    
    @Field(key: "gender")
    var gender: String?
    
    @Field(key: "address")
    var address: String?
    
    @Field(key: "city")
    var city: String?
    
    @Field(key: "country")
    var country: String?
    
    @Field(key: "occupation")
    var occupation: String?
    
    init() { }
    
    init(id: UUID? = nil, userID: UUID, birthDate: Date? = nil, gender: String? = nil) {
        self.id = id
        self.$user.id = userID
        self.birthDate = birthDate
        self.gender = gender
    }
}

// MARK: - JWT Payload
struct UserPayload: JWTPayload {
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case issuedAt = "iat"
        case userID = "uid"
        case email = "email"
    }

    var subject: SubjectClaim
    var expiration: ExpirationClaim
    var issuedAt: IssuedAtClaim
    var userID: UUID
    var email: String

    func verify(using signer: JWTSigner) throws {
        try self.expiration.verifyNotExpired()
    }
}
