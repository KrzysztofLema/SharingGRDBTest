//
//  TransactionWithCategory.swift
//  SharingGRDBTest
//
//  Created by Krzysztof Lema on 22/07/2025.
//
import Foundation
import SharingGRDB

@Selection
struct TransactionWithCategory: Equatable, Sendable {
    let transaction: Transaction
    let category: Category?
    
    var id: Transaction.ID { transaction.id }
    var date: Date? { transaction.date }
    var amount: Decimal { transaction.amount }
    var description: String { transaction.description }
    var icon: String { category?.icon ?? "tag" }
}
        
