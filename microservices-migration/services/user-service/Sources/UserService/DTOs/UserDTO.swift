import Fluent
import Vapor

// MARK: - 用户注册 DTO
struct CreateUserRequest: Content {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    let phone: String?
    
    func validate() throws {
        guard email.contains("@") else {
            throw Abort(.badRequest, reason: "Invalid email format")
        }
        guard password.count >= 8 else {
            throw Abort(.badRequest, reason: "Password must be at least 8 characters")
        }
    }
}

// MARK: - 用户登录 DTO
struct LoginRequest: Content {
    let email: String
    let password: String
}

// MARK: - 用户响应 DTO
struct UserResponse: Content {
    let id: UUID
    let email: String
    let firstName: String
    let lastName: String
    let phone: String?
    let createdAt: Date?
}

// MARK: - 登录响应 DTO
struct LoginResponse: Content {
    let user: UserResponse
    let token: String
    let expiresAt: Date
}

// MARK: - 用户资料 DTO
struct UserProfileRequest: Content {
    let birthDate: Date?
    let gender: String?
    let address: String?
    let city: String?
    let country: String?
    let occupation: String?
}

struct UserProfileResponse: Content {
    let id: UUID
    let userId: UUID
    let birthDate: Date?
    let gender: String?
    let address: String?
    let city: String?
    let country: String?
    let occupation: String?
}

// MARK: - Model Extensions
extension User {
    func toResponse() -> UserResponse {
        UserResponse(
            id: self.id!,
            email: self.email,
            firstName: self.firstName,
            lastName: self.lastName,
            phone: self.phone,
            createdAt: self.createdAt
        )
    }
}

extension UserProfile {
    func toResponse() -> UserProfileResponse {
        UserProfileResponse(
            id: self.id!,
            userId: self.$user.id,
            birthDate: self.birthDate,
            gender: self.gender,
            address: self.address,
            city: self.city,
            country: self.country,
            occupation: self.occupation
        )
    }
}
