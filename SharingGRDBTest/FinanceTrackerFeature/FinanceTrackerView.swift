import SwiftUI
import ComposableArchitecture

@ViewAction(for: FinanceTracker.self)
public struct FinanceTrackerView: View {
    @Bindable public var store: StoreOf<FinanceTracker>
    
    public init(store: StoreOf<FinanceTracker>) {
        self.store = store
    }
    
    public var body: some View {
        NavigationStack(path: $store.scope(
            state: \.path,
            action: \.path
        )) {
            ScrollView {
                LazyVStack(spacing: 20) {
                    balanceCard
                    quickActionsSection
                    accountsSection
                    recentTransactionsSection
                }
                .padding()
            }
            .navigationTitle("Finance Tracker")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {

                    }
                }
            }
            .refreshable {
                send(.refreshData)
            }
            .task {
                send(.onAppear)
            }
        } destination: { store in
            
        }
        .sheet(
            store: store.scope(
                state: \.$destination,
                action: \.destination
            ),
            content: { store in
                
            }
        )
    }
    
    private var balanceCard: some View {
        VStack(spacing: 8) {
            Text("Total Balance")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(store.totalBalance.formattedCurrency())
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(store.totalBalance >= 0 ? .primary : .red)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                quickActionButton(
                    title: "Add Income",
                    icon: "plus.circle.fill",
                    color: .green
                ) {
                    send(.addTransactionTapped)
                }
                
                quickActionButton(
                    title: "Add Expense",
                    icon: "minus.circle.fill",
                    color: .red
                ) {
                    send(.addTransactionTapped)
                }
                
                quickActionButton(
                    title: "Add Account",
                    icon: "creditcard.fill",
                    color: .blue
                ) {
                    send(.addAccountTapped)
                }
            }
        }
    }
    
    private func quickActionButton(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () async -> Void
    ) -> some View {
        Button {
            Task { await action() }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Accounts")
                    .font(.headline)
                
                Spacer()
                
                Button("View All") {

                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(store.accounts) { account in
                        accountCard(account)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func accountCard(_ account: Account) -> some View {
        Button {
            send(.accountTapped(account))
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(account.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if !account.isActive {
                        Text("Inactive")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(account.balance.formattedCurrency())
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(account.balance >= 0 ? .primary : .red)
                
                Text(account.currency)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 160)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                
                Spacer()
                
                Button("View All") {
                    // TODO: Navigate to transactions list
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            
            if store.recentTransactions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "creditcard")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No transactions yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Add your first transaction to get started")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(store.recentTransactions) { transaction in
                        transactionRow(transaction)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func transactionRow(_ transaction: Transaction) -> some View {
        Button {
            send(.transactionTapped(transaction))
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "tag")
                            .font(.caption)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.description)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let date = transaction.date {
                        Text(date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(transaction.amount.formattedCurrency())
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(transaction.amount >= 0 ? .green : .red)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    
    let _ = prepareDependencies {
        $0.defaultDatabase = try! appDatabase()
    }
    
    
    FinanceTrackerView(
        store: Store(initialState: FinanceTracker.State()) {
            FinanceTracker()
        }
    )
}
