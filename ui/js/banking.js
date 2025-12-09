/**
 * Banking App Shell
 */

function renderBankingApp() {
    const { status, activeTab } = AppState;

    return `
        <div class="min-h-screen bg-white">
            <!-- Header -->
            <header class="border-b border-gray-200">
                <div class="max-w-7xl mx-auto px-6 py-4">
                    <div class="flex items-center justify-between">
                        <h1 class="text-xl font-light">Banking Workshop</h1>
                        <button
                            id="redis-insight-btn"
                            class="px-4 py-2 text-sm text-gray-600 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
                        >
                            RedisInsight
                        </button>
                    </div>
                </div>
            </header>

            <!-- Tabs -->
            <div class="border-b border-gray-200">
                <div class="max-w-7xl mx-auto px-6">
                    <div class="flex gap-8">
                        ${renderTab('transactions', 'Transactions', status.transactions_unlocked)}
                        ${renderTab('categories', 'Spending Categories', status.categories_unlocked)}
                        ${renderTab('timeseries', 'Track Spending Over Time', status.timeseries_unlocked)}
                    </div>
                </div>
            </div>

            <!-- Content -->
            <div class="max-w-7xl mx-auto px-6 py-8">
                ${renderTabContent()}
            </div>
        </div>
    `;
}

function renderTab(tab, label, unlocked) {
    const isActive = AppState.activeTab === tab;
    const lockIcon = unlocked ? '' : `
        <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z" clip-rule="evenodd"/>
        </svg>
    `;

    return `
        <button
            data-tab="${tab}"
            class="flex items-center gap-2 py-4 text-sm border-b-2 transition-colors ${
                isActive
                    ? 'border-black text-black'
                    : 'border-transparent text-gray-500 hover:text-gray-700'
            } ${unlocked ? '' : 'opacity-50'}"
        >
            ${lockIcon}
            <span>${label}</span>
        </button>
    `;
}

function renderTabContent() {
    const { activeTab, status } = AppState;

    if (activeTab === 'transactions') {
        return status.transactions_unlocked
            ? renderTransactionsTab()
            : renderLockedMessage('Complete <code>ordered_transactions.py</code> and <code>store_transaction.py</code>');
    }

    if (activeTab === 'categories') {
        return status.categories_unlocked
            ? renderCategoriesTab()
            : renderLockedMessage('Complete <code>spending_categories.py</code>');
    }

    if (activeTab === 'timeseries') {
        return status.timeseries_unlocked
            ? renderTimeseriesTab()
            : renderLockedMessage('Complete <code>spending_over_time.py</code>');
    }
}

function renderLockedMessage(message) {
    return `
        <div class="flex flex-col items-center justify-center py-20">
            <div class="text-center max-w-md">
                <svg class="w-16 h-16 mx-auto mb-4 text-gray-300" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z" clip-rule="evenodd"/>
                </svg>
                <p class="text-gray-600">${message}</p>
            </div>
        </div>
    `;
}
