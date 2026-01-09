/**
 * Startup Screen Component
 */

let latestTransaction = { merchant: 'Waiting for transactions...', amount: '0.00' };
let lastStreamId = '0';

function renderStartupScreen() {
    return `
        <div class="flex flex-col items-center justify-center min-h-screen bg-white p-8">
            <!-- Redis Insight Button (Top Right) -->
            <div class="absolute top-6 right-6 flex items-center gap-2">
                <span class="text-sm text-gray-600">View the data in Redis via</span>
                <button
                    id="redis-insight-btn"
                    class="px-4 py-2 text-sm text-white rounded-lg transition-colors"
                    style="background-color: #7F3B3B;"
                    onmouseover="this.style.backgroundColor='#6B3232'"
                    onmouseout="this.style.backgroundColor='#7F3B3B'"
                    onclick="window.open(window.REDIS_INSIGHT_URL || 'http://localhost:8001', '_blank')"
                >
                    Redis Insight
                </button>
            </div>

            <!-- Welcome Message -->
            <div class="text-center mb-12">
                <h1 class="text-4xl font-light text-gray-800 mb-4">
                    Welcome to the Redis - Transactions Workshop
                </h1>
            </div>

            <!-- Transaction Pulse Indicator -->
            <div class="pulse mb-16">
                <div class="bg-blue-100 border-2 border-blue-300 rounded-lg px-8 py-6 min-w-[350px] shadow-lg">
                    <p class="text-base font-medium text-blue-800 text-center" id="transaction-pulse">
                        ${latestTransaction.merchant} - $${latestTransaction.amount}
                    </p>
                </div>
            </div>

            <!-- Begin Button -->
            <div class="flex flex-col items-center">
                <p class="text-sm text-gray-500 mb-4">
                    Begin adding data to Redis to see application components
                </p>
                <button
                    id="begin-btn"
                    class="px-6 py-3 bg-black text-white rounded-lg hover:bg-gray-800 transition-colors inline-flex items-center gap-2"
                >
                    <span>Get Started</span>
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
                    </svg>
                </button>
            </div>
        </div>
    `;
}

async function pollStreamForNewTransactions() {
    try {
        // Fetch latest transaction from stream via API endpoint
        const res = await fetch(`${API_BASE}/api/stream/latest?after=${lastStreamId}`);
        const data = await res.json();

        if (data.transaction) {
            const tx = data.transaction;
            lastStreamId = data.stream_id;

            latestTransaction = {
                merchant: tx.merchant || 'Unknown',
                amount: parseFloat(tx.amount || 0).toFixed(2)
            };

            const pulseEl = document.getElementById('transaction-pulse');
            if (pulseEl) {
                pulseEl.textContent = `${latestTransaction.merchant} - $${latestTransaction.amount}`;
            }
        }
    } catch (err) {
        // Silently fail - stream might not be available yet
        console.log('Waiting for stream...', err.message);
    }
}

function startTransactionPolling() {
    // Poll every 4 seconds to catch transactions as they come in
    pollStreamForNewTransactions();
    setInterval(pollStreamForNewTransactions, 4000);
}
