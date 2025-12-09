/**
 * Transactions Tab Component
 */

let transactionsData = [];

function renderTransactionsTab() {
    const { selectedTransaction } = AppState;

    return `
        <div class="flex gap-6">
            <!-- Transactions List -->
            <div class="flex-1">
                <div class="flex items-center justify-between mb-6">
                    <div>
                        <h2 class="text-lg font-medium">Recent Transactions</h2>
                        <p class="text-xs text-gray-400">Last 20 transactions</p>
                    </div>
                    <button
                        id="refresh-transactions"
                        class="px-4 py-2 text-sm bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
                    >
                        Refresh
                    </button>
                </div>

                <div id="transactions-list">
                    ${renderTransactionsList()}
                </div>
            </div>

            <!-- Transaction Detail Panel -->
            ${selectedTransaction ? `
                <div class="w-80 detail-panel pl-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-lg font-medium">Transaction Details</h3>
                        <button id="close-detail" class="text-gray-400 hover:text-gray-600">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                            </svg>
                        </button>
                    </div>
                    ${renderTransactionDetail(selectedTransaction)}
                </div>
            ` : ''}
        </div>
    `;
}

function renderTransactionsList() {
    if (transactionsData.length === 0) {
        return `
            <div class="text-center py-8 text-gray-500">
                Click refresh to load transactions
            </div>
        `;
    }

    return `
        <div class="border border-gray-200 rounded-lg overflow-hidden">
            <table class="w-full">
                <thead class="bg-gray-50 border-b border-gray-200">
                    <tr>
                        <th class="text-left px-4 py-3 text-sm font-medium text-gray-600">Date & Time</th>
                        <th class="text-left px-4 py-3 text-sm font-medium text-gray-600">Merchant</th>
                        <th class="text-right px-4 py-3 text-sm font-medium text-gray-600">Amount</th>
                        <th class="w-8"></th>
                    </tr>
                </thead>
                <tbody>
                    ${transactionsData.map(tx => `
                        <tr
                            class="transaction-row border-b border-gray-100 cursor-pointer"
                            data-tx-id="${tx.transactionId}"
                        >
                            <td class="px-4 py-3 text-sm">
                                ${new Date(parseInt(tx.timestamp)).toLocaleString()}
                            </td>
                            <td class="px-4 py-3 text-sm">${tx.merchant}</td>
                            <td class="px-4 py-3 text-sm text-right font-medium">
                                $${parseFloat(tx.amount).toFixed(2)}
                            </td>
                            <td class="px-2 py-3 text-gray-300">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
                                </svg>
                            </td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        </div>
    `;
}

function renderTransactionDetail(tx) {
    return `
        <div class="space-y-4 text-sm">
            <div>
                <div class="text-gray-500 mb-1">Transaction ID</div>
                <div class="font-mono">${tx.transactionId}</div>
            </div>
            <div>
                <div class="text-gray-500 mb-1">Customer ID</div>
                <div class="font-mono">${tx.customerId}</div>
            </div>
            <div>
                <div class="text-gray-500 mb-1">Amount</div>
                <div class="text-lg font-medium">$${parseFloat(tx.amount).toFixed(2)}</div>
            </div>
            <div>
                <div class="text-gray-500 mb-1">Merchant</div>
                <div>${tx.merchant}</div>
            </div>
            <div>
                <div class="text-gray-500 mb-1">Category</div>
                <div class="inline-block px-2 py-1 bg-gray-100 rounded">${tx.category}</div>
            </div>
            <div>
                <div class="text-gray-500 mb-1">Date & Time</div>
                <div>${new Date(parseInt(tx.timestamp)).toLocaleString()}</div>
            </div>
            <div>
                <div class="text-gray-500 mb-1">Location</div>
                <div>${tx.location}</div>
            </div>
            ${tx.notes ? `
                <div>
                    <div class="text-gray-500 mb-1">Notes</div>
                    <div class="text-gray-700">${tx.notes}</div>
                </div>
            ` : ''}
        </div>
    `;
}

async function loadTransactions() {
    try {
        const res = await fetch(`${API_BASE}/api/transactions/recent?limit=20`);
        const data = await res.json();

        if (data.error || !data.transactions) {
            transactionsData = [];
        } else {
            transactionsData = data.transactions;
        }

        app.render();
    } catch (err) {
        console.error('Failed to load transactions:', err);
        transactionsData = [];
        app.render();
    }
}

function attachTransactionsListeners() {
    // Refresh button
    const refreshBtn = document.getElementById('refresh-transactions');
    if (refreshBtn) {
        refreshBtn.onclick = () => loadTransactions();
    }

    // Close detail panel button
    const closeBtn = document.getElementById('close-detail');
    if (closeBtn) {
        closeBtn.onclick = () => {
            AppState.selectedTransaction = null;
            app.render();
        };
    }

    // Transaction row clicks
    document.querySelectorAll('[data-tx-id]').forEach(row => {
        row.onclick = () => {
            const txId = row.dataset.txId;
            const tx = transactionsData.find(t => t.transactionId === txId);
            if (tx) {
                AppState.selectedTransaction = tx;
                app.render();
            }
        };
    });
}
