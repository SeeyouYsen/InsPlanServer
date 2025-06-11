import Fluent

struct CreatePayment: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.enum("payment_status")
            .case("pending")
            .case("processing")
            .case("completed")
            .case("failed")
            .case("cancelled")
            .case("refunded")
            .create()
            .flatMap { paymentStatus in
                database.enum("payment_method")
                    .case("alipay")
                    .case("wechat_pay")
                    .case("bank_card")
                    .case("credit_card")
                    .case("wallet")
                    .create()
                    .flatMap { paymentMethod in
                        database.schema("payments")
                            .id()
                            .field("order_id", .uuid, .required)
                            .field("user_id", .uuid, .required)
                            .field("amount", .double, .required)
                            .field("currency", .string, .required)
                            .field("status", paymentStatus, .required)
                            .field("method", paymentMethod, .required)
                            .field("transaction_id", .string)
                            .field("gateway_response", .string)
                            .field("created_at", .datetime)
                            .field("updated_at", .datetime)
                            .field("processed_at", .datetime)
                            .create()
                    }
            }
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("payments").delete()
            .flatMap {
                database.enum("payment_method").delete()
            }
            .flatMap {
                database.enum("payment_status").delete()
            }
    }
}
