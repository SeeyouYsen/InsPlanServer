import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return ["message": "Payment Service is running"]
    }
    
    app.get("health") { req in
        return ["status": "healthy"]
    }
    
    let paymentController = PaymentController()
    try app.register(collection: paymentController)
}
