import Foundation
import SharingGRDB
import OSLog

@Table
public struct Account: Hashable, Identifiable, Sendable {
    public let id: Int
    var name: String = ""
    var balanceCents: Int = 0
    var currency: String = "USD"
    var isActive = true
    var position = 0
    var createdAt: Date?
    var updatedAt: Date?
    
    var balance: Decimal {
        get { Decimal(cents: balanceCents) }
        set { balanceCents = newValue.cents }
    }
}

extension Account.Draft: Identifiable {}

extension Account.TableColumns {
    var formattedBalance: some QueryExpression<String> {
        #sql("printf('%.2f', \(balanceCents) / 100.0)")
    }
}

@Table
public struct Category: Hashable, Identifiable, Sendable {
    public let id: Int
    var name = ""
    var type: CategoryType = .expense
    var color = 0x007AFF_ff
    var icon = "tag"
    var isActive = true
    var position = 0
    var createdAt: Date?
    var updatedAt: Date?
    
    public enum CategoryType: Int, Codable, QueryBindable {
        case income = 1
        case expense = 2
    }
}

extension Category.Draft: Identifiable {}

extension Category.TableColumns {
    var isIncome: some QueryExpression<Bool> {
        type == Category.CategoryType.income
    }
    
    var isExpense: some QueryExpression<Bool> {
        type == Category.CategoryType.expense
    }
}

@Table
public struct Transaction: Codable, Equatable, Identifiable, Sendable {
    public let id: Int
    var accountID: Account.ID
    var categoryID: Category.ID
    var amountCents: Int = 0
    var description: String = ""
    var date: Date?
    var isRecurring = false
    var recurringInterval: RecurringInterval?
    var createdAt: Date?
    var updatedAt: Date?
    
    public enum RecurringInterval: Int, Codable, QueryBindable {
        case daily = 1
        case weekly = 2
        case monthly = 3
        case yearly = 4
    }
    
    // Computed property for Decimal
    var amount: Decimal {
        get { Decimal(cents: amountCents) }
        set { amountCents = newValue.cents }
    }
}

extension Transaction.Draft: Identifiable {}

extension Transaction.TableColumns {
    var isIncome: some QueryExpression<Bool> {
        amountCents > 0
    }
    
    var isExpense: some QueryExpression<Bool> {
        amountCents < 0
    }
    
    var isToday: some QueryExpression<Bool> {
        #sql("date(\(date)) = date()")
    }
    
    var isThisMonth: some QueryExpression<Bool> {
        #sql("strftime('%Y-%m', \(date)) = strftime('%Y-%m', 'now')")
    }
    
    var isThisYear: some QueryExpression<Bool> {
        #sql("strftime('%Y', \(date)) = strftime('%Y', 'now')")
    }
    
    var formattedAmount: some QueryExpression<String> {
        #sql("printf('%.2f', \(amountCents) / 100.0)")
    }
}

func appDatabase() throws -> any DatabaseWriter {
    @Dependency(\.context) var context
    
    let database: any DatabaseWriter
    
    var confituragion = Configuration()
    confituragion.foreignKeysEnabled = true
    
    confituragion.prepareDatabase { db in
#if DEBUG
        db.trace(options: .profile) {
            if context == .preview {
                print($0.expandedDescription)
            } else {
                logger.debug("\($0.description)")
            }
        }
#endif
    }
    
    switch context {
    case .live:
        let path = URL.documentsDirectory.appending(component: "db.sqlite").path()
        logger.info("open \(path)")
        database = try DatabasePool(path: path, configuration: confituragion)
    case .preview, .test:
        database = try DatabaseQueue(configuration: confituragion)
    }
    
    var migrator = DatabaseMigrator()
#if DEBUG
    migrator.eraseDatabaseOnSchemaChange = true
#endif
    migrator.registerMigration("Create tables") { db in
        try #sql("""
              CREATE TABLE "accounts" (
                  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
                  "name" TEXT NOT NULL DEFAULT '',
                  "balanceCents" INTEGER NOT NULL DEFAULT 0,
                  "currency" TEXT NOT NULL DEFAULT 'USD',
                  "isActive" INTEGER NOT NULL DEFAULT 1,
                  "position" INTEGER NOT NULL DEFAULT 0,
                  "createdAt" TEXT,
                  "updatedAt" TEXT
              ) STRICT
          """).execute(db)
        
        try #sql("""
              CREATE TABLE "categories" (
                  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
                  "name" TEXT NOT NULL DEFAULT '',
                  "type" INTEGER NOT NULL DEFAULT 2,
                  "color" INTEGER NOT NULL DEFAULT \(raw: 0x007AFF_ff),
                  "icon" TEXT NOT NULL DEFAULT 'tag',
                  "isActive" INTEGER NOT NULL DEFAULT 1,
                  "position" INTEGER NOT NULL DEFAULT 0,
                  "createdAt" TEXT,
                  "updatedAt" TEXT
              ) STRICT
          """).execute(db)
        
        try #sql("""
              CREATE TABLE "transactions" (
                  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
                  "accountID" INTEGER NOT NULL REFERENCES "accounts"("id") ON DELETE CASCADE,
                  "categoryID" INTEGER NOT NULL REFERENCES "categories"("id") ON DELETE RESTRICT,
                  "amountCents" INTEGER NOT NULL DEFAULT 0,
                  "description" TEXT NOT NULL DEFAULT '',
                  "date" TEXT,
                  "isRecurring" INTEGER NOT NULL DEFAULT 0,
                  "recurringInterval" INTEGER,
                  "createdAt" TEXT,
                  "updatedAt" TEXT
              ) STRICT
          """).execute(db)
        
        //        try #sql("""
        //              CREATE TABLE "budgets" (
        //                  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
        //                  "categoryID" INTEGER NOT NULL REFERENCES "categories"("id") ON DELETE CASCADE,
        //                  "amountCents" INTEGER NOT NULL DEFAULT 0,
        //                  "period" INTEGER NOT NULL DEFAULT 2,
        //                  "startDate" TEXT,
        //                  "endDate" TEXT,
        //                  "isActive" INTEGER NOT NULL DEFAULT 1,
        //                  "createdAt" TEXT,
        //                  "updatedAt" TEXT
        //              ) STRICT
        //          """).execute(db)
    }
    
#if DEBUG
    migrator.registerMigration("Seed database") { db in
        @Dependency(\.date.now) var now
        
        try db.seed {
            // Default accounts
            Account(id: 1, name: "Main Account", balanceCents: 100000, position: 0)
            Account(id: 2, name: "Savings", balanceCents: 500000, position: 1)
            Account(id: 3, name: "Credit Card", balanceCents: -25000, position: 2)
            
            // Default categories
            Category(id: 1, name: "Salary", type: .income, color: 0x34C759_ff, icon: "dollarsign.circle", position: 0)
            Category(id: 2, name: "Freelance", type: .income, color: 0x30D158_ff, icon: "laptopcomputer", position: 1)
            Category(id: 3, name: "Investment", type: .income, color: 0x64D2FF_ff, icon: "chart.line.uptrend.xyaxis", position: 2)
            Category(id: 4, name: "Food & Dining", type: .expense, color: 0xFF9500_ff, icon: "fork.knife", position: 3)
            Category(id: 5, name: "Transportation", type: .expense, color: 0x007AFF_ff, icon: "car", position: 4)
            Category(id: 6, name: "Shopping", type: .expense, color: 0xAF52DE_ff, icon: "bag", position: 5)
            Category(id: 7, name: "Entertainment", type: .expense, color: 0xFF2D92_ff, icon: "tv", position: 6)
            Category(id: 8, name: "Bills & Utilities", type: .expense, color: 0xFF3B30_ff, icon: "bolt", position: 7)
            Category(id: 9, name: "Healthcare", type: .expense, color: 0xFF6B6B_ff, icon: "cross.case", position: 8)
            Category(id: 10, name: "Education", type: .expense, color: 0x5AC8FA_ff, icon: "book", position: 9)
            
            // Sample transactions
            Transaction(
                id: 1,
                accountID: 1,
                categoryID: 1,
                amountCents: 300000,
                description: "Monthly salary",
                date: now
            )
            Transaction(
                id: 2,
                accountID: 1,
                categoryID: 4,
                amountCents: -4550,
                description: "Grocery shopping",
                date: now.addingTimeInterval(-60 * 60 * 24)
            )
            Transaction(
                id: 3,
                accountID: 1,
                categoryID: 5,
                amountCents: -2500,
                description: "Gas station",
                date: now.addingTimeInterval(-60 * 60 * 24 * 2)
            )
            Transaction(
                id: 4,
                accountID: 3,
                categoryID: 6,
                amountCents: -12000,
                description: "Online shopping",
                date: now.addingTimeInterval(-60 * 60 * 24 * 3)
            )
            Transaction(
                id: 5,
                accountID: 2,
                categoryID: 3,
                amountCents: 15000,
                description: "Dividend payment",
                date: now.addingTimeInterval(-60 * 60 * 24 * 7)
            )
            Transaction(
                id: 6,
                accountID: 1,
                categoryID: 7,
                amountCents: -3500,
                description: "Movie tickets",
                date: now.addingTimeInterval(-60 * 60 * 24 * 4)
            )
            Transaction(
                id: 7,
                accountID: 1,
                categoryID: 8,
                amountCents: -8500,
                description: "Electricity bill",
                date: now.addingTimeInterval(-60 * 60 * 24 * 5)
            )
            Transaction(
                id: 8,
                accountID: 1,
                categoryID: 9,
                amountCents: -7500,
                description: "Doctor visit",
                date: now.addingTimeInterval(-60 * 60 * 24 * 6)
            )
        }
    }
#endif
    try migrator.migrate(database)
    
    try database.write { db in
        try Account.createTemporaryTrigger(
            ifNotExists: true,
            after: .delete(forEachRow: { old in
                Account.insert { Account.Draft(name: "Main Account") }
            }, when: { old in
                !Account.exists()
            })).execute(db)
        
        try Category.createTemporaryTrigger(after: .delete(forEachRow: { old in
            Category.insert { Category.Draft(name: "Uncategorized", type: .expense) }
        }, when: { old in
            !Category.exists()
        })).execute(db)
    }
    
    return database
}

private let logger = Logger(subsystem: "Reminders", category: "Database")
