import Foundation
import ComposableArchitecture
import SharingGRDB

@Reducer
public struct FinanceTracker: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        @Presents var destination: Destination.State?
        var path = StackState<Path.State>()
        
        @FetchAll(
            Account
                .group(by: \.id)
                .order(by: \.position),
            animation: .default
        )
        var accounts
        
        @FetchAll(Transaction
            .group(by: \.id)
            .order(by: \.date)
        )
        var recentTransactions
        
        @FetchOne(Account.select { $0.balanceCents.sum() })
        var totalBalanceCents
        
        @FetchAll
        var transactionWithCategory: [TransactionWithCategory]
        
        var query: some StructuredQueries.Statement<TransactionWithCategory> {
            Transaction
                .group(by: \.id)
                .leftJoin(Category.all, on: {
                    $0.categoryID.eq($1.id)
                })
                .select({
                    TransactionWithCategory.Columns(transaction: $0, category: $1)
                })
        }
        
        var isLoading = false
        var errorMessage: String?
        
        var totalBalance: Decimal {
            Decimal(totalBalanceCents ?? 0) / Decimal(100)
        }
        
        public init() {
            _transactionWithCategory = FetchAll(query)
        }
    }
    
    public enum Action: ViewAction, Sendable {
        case destination(PresentationAction<Destination.Action>)
        case path(StackAction<Path.State, Path.Action>)
        case view(View)
        
        @CasePathable
        public enum View: Sendable {
            case onDeleteTransaction(Transaction)
            case onAppear
            case refreshData
            case addTransactionTapped
            case addAccountTapped
            case accountTapped(Account)
            case transactionTapped(Transaction)
        }
    }
    
    @Reducer(state: .equatable, .sendable, action: .sendable)
    public enum Path {}
    
    @Reducer(state: .equatable, action: .sendable)
    public enum Destination {}
    
    @Dependency(\.defaultDatabase) var database
    
    public var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                return .run { send in
                    await send(.view(.refreshData))
                }
                
            case .view(.refreshData):
                state.isLoading = true
                state.errorMessage = nil
      
                return .none
            case .view(.addTransactionTapped):
                // TODO: Navigate to add transaction screen
                return .none
                
            case .view(.addAccountTapped):
                // TODO: Navigate to add account screen
                return .none
                
            case .view(.accountTapped(let account)):
                return .none
                
            case .view(.transactionTapped(let transaction)):
                return .none
                
            case .destination, .path:
                return .none
            case .view(.onDeleteTransaction(let transaction)):
                withErrorReporting {
                    try database.write { db in
                        try Transaction
                            .delete(transaction)
                            .execute(db)
                    }
                }
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        .forEach(\.path, action: \.path)
    }
}

// MARK: - Internal Actions
extension FinanceTracker.Action {
    enum Internal: Sendable {
        case dataLoaded(accounts: [Account], recentTransactions: [Transaction], totalBalance: Decimal)
        case dataLoadFailed(String)
    }
}
