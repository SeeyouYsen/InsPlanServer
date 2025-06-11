import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return ["message": "Notification Service is running"]
    }
    
    app.get("health") { req in
        return ["status": "healthy"]
    }
    
    let notificationController = NotificationController()
    try app.register(collection: notificationController)
}
