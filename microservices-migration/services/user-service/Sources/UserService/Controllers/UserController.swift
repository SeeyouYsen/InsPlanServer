import Fluent
import Vapor
import JWT
import Crypto

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("api", "v1", "users")
        
        // 公开路由
        users.post("register", use: register)
        users.post("login", use: login)
        
        // 需要认证的路由
        let authenticated = users.grouped(UserAuthenticator())
        authenticated.get("me", use: getCurrentUser)
        authenticated.put("me", use: updateUser)
        authenticated.get("profile", use: getProfile)
        authenticated.put("profile", use: updateProfile)
        authenticated.delete("me", use: deleteUser)
    }

    // MARK: - 用户注册
    @Sendable
    func register(req: Request) async throws -> LoginResponse {
        let createRequest = try req.content.decode(CreateUserRequest.self)
        try createRequest.validate()
        
        // 检查邮箱是否已存在
        if let _ = try await User.query(on: req.db)
            .filter(\.$email == createRequest.email)
            .first() {
            throw Abort(.conflict, reason: "Email already exists")
        }
        
        // 创建用户
        let passwordHash = try await req.password.async.hash(createRequest.password)
        let user = User(
            email: createRequest.email,
            passwordHash: passwordHash,
            firstName: createRequest.firstName,
            lastName: createRequest.lastName,
            phone: createRequest.phone
        )
        
        try await user.save(on: req.db)
        
        // 生成 JWT Token
        let token = try generateToken(for: user, on: req)
        
        return LoginResponse(
            user: user.toResponse(),
            token: token.token,
            expiresAt: token.expiresAt
        )
    }

    // MARK: - 用户登录
    @Sendable
    func login(req: Request) async throws -> LoginResponse {
        let loginRequest = try req.content.decode(LoginRequest.self)
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$email == loginRequest.email)
            .first() else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }
        
        let isValidPassword = try await req.password.async.verify(
            loginRequest.password,
            created: user.passwordHash
        )
        
        guard isValidPassword else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }
        
        let token = try generateToken(for: user, on: req)
        
        return LoginResponse(
            user: user.toResponse(),
            token: token.token,
            expiresAt: token.expiresAt
        )
    }

    // MARK: - 获取当前用户信息
    @Sendable
    func getCurrentUser(req: Request) async throws -> UserResponse {
        let user = try req.auth.require(User.self)
        return user.toResponse()
    }

    // MARK: - 更新用户信息
    @Sendable
    func updateUser(req: Request) async throws -> UserResponse {
        let user = try req.auth.require(User.self)
        let updateRequest = try req.content.decode(CreateUserRequest.self)
        
        user.email = updateRequest.email
        user.firstName = updateRequest.firstName
        user.lastName = updateRequest.lastName
        user.phone = updateRequest.phone
        
        if !updateRequest.password.isEmpty {
            user.passwordHash = try await req.password.async.hash(updateRequest.password)
        }
        
        try await user.save(on: req.db)
        return user.toResponse()
    }

    // MARK: - 获取用户资料
    @Sendable
    func getProfile(req: Request) async throws -> UserProfileResponse {
        let user = try req.auth.require(User.self)
        
        if let profile = try await UserProfile.query(on: req.db)
            .filter(\.$user.$id == user.id!)
            .first() {
            return profile.toResponse()
        } else {
            // 创建空的资料
            let profile = UserProfile(userID: user.id!)
            try await profile.save(on: req.db)
            return profile.toResponse()
        }
    }

    // MARK: - 更新用户资料
    @Sendable
    func updateProfile(req: Request) async throws -> UserProfileResponse {
        let user = try req.auth.require(User.self)
        let profileRequest = try req.content.decode(UserProfileRequest.self)
        
        let profile: UserProfile
        if let existingProfile = try await UserProfile.query(on: req.db)
            .filter(\.$user.$id == user.id!)
            .first() {
            profile = existingProfile
        } else {
            profile = UserProfile(userID: user.id!)
        }
        
        profile.birthDate = profileRequest.birthDate
        profile.gender = profileRequest.gender
        profile.address = profileRequest.address
        profile.city = profileRequest.city
        profile.country = profileRequest.country
        profile.occupation = profileRequest.occupation
        
        try await profile.save(on: req.db)
        return profile.toResponse()
    }

    // MARK: - 删除用户
    @Sendable
    func deleteUser(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        // 删除相关的用户资料
        try await UserProfile.query(on: req.db)
            .filter(\.$user.$id == user.id!)
            .delete()
        
        // 删除用户
        try await user.delete(on: req.db)
        
        return .noContent
    }

    // MARK: - 私有方法
    private func generateToken(for user: User, on req: Request) throws -> (token: String, expiresAt: Date) {
        let expiresAt = Date().addingTimeInterval(24 * 60 * 60) // 24小时
        
        let payload = UserPayload(
            subject: SubjectClaim(value: "user"),
            expiration: ExpirationClaim(value: expiresAt),
            issuedAt: IssuedAtClaim(value: Date()),
            userID: user.id!,
            email: user.email
        )
        
        let token = try req.jwt.sign(payload)
        return (token, expiresAt)
    }
}

// MARK: - JWT 认证中间件
struct UserAuthenticator: AsyncBearerAuthenticator {
    typealias User = UserService.User

    func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
        do {
            let payload = try request.jwt.verify(bearer.token, as: UserPayload.self)
            
            if let user = try await User.find(payload.userID, on: request.db) {
                request.auth.login(user)
            }
        } catch {
            // JWT 验证失败，不抛出错误，让下游处理
        }
    }
}
