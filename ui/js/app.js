/**
 * Main Application Controller
 * Manages state, routing, and API polling
 */

const API_BASE = 'http://localhost:8000';
const POLL_INTERVAL = 2000; // 2 seconds

const AppState = {
    screen: 'startup', // 'startup' | 'banking'
    activeTab: 'transactions',
    status: {
        transactions_unlocked: false,
        categories_unlocked: false,
        timeseries_unlocked: false
    },
    selectedTransaction: null
};

class App {
    constructor() {
        this.pollTimer = null;
        this.init();
    }

    async init() {
        console.log('App initializing...');
        console.log('AppState:', AppState);
        this.render();
        this.startPolling();
        console.log('App initialized');
    }

    async checkStatus() {
        try {
            const res = await fetch(`${API_BASE}/api/status`);
            const status = await res.json();

            // Only re-render if unlock status changed
            const changed =
                status.transactions_unlocked !== AppState.status.transactions_unlocked ||
                status.categories_unlocked !== AppState.status.categories_unlocked ||
                status.timeseries_unlocked !== AppState.status.timeseries_unlocked;

            AppState.status = status;

            if (changed) {
                this.render();
            }
        } catch (err) {
            console.error('Failed to check status:', err);
        }
    }

    startPolling() {
        this.pollTimer = setInterval(() => this.checkStatus(), POLL_INTERVAL);
    }

    stopPolling() {
        if (this.pollTimer) clearInterval(this.pollTimer);
    }

    navigateToBank() {
        AppState.screen = 'banking';
        this.render();
    }

    switchTab(tab) {
        AppState.activeTab = tab;
        AppState.selectedTransaction = null;
        this.render();
    }

    render() {
        const container = document.getElementById('app');
        console.log('Rendering...', 'container:', container, 'screen:', AppState.screen);

        if (AppState.screen === 'startup') {
            container.innerHTML = renderStartupScreen();
            this.attachStartupListeners();
        } else {
            container.innerHTML = renderBankingApp();
            this.attachBankingListeners();
        }
    }

    attachStartupListeners() {
        const btn = document.getElementById('begin-btn');
        if (btn) {
            btn.onclick = () => this.navigateToBank();
        }

        const insightBtn = document.getElementById('redis-insight-btn');
        if (insightBtn) {
            insightBtn.onclick = () => window.open('http://localhost:8001', '_blank');
        }

        // Start polling for latest transaction
        if (typeof startTransactionPolling === 'function') {
            startTransactionPolling();
        }
    }

    attachBankingListeners() {
        // Tab clicks
        document.querySelectorAll('[data-tab]').forEach(el => {
            el.onclick = () => this.switchTab(el.dataset.tab);
        });

        // Redis Insight
        const insightBtn = document.getElementById('redis-insight-btn');
        if (insightBtn) {
            insightBtn.onclick = () => window.open('http://localhost:8001', '_blank');
        }

        // Tab-specific listeners
        if (AppState.activeTab === 'transactions' && AppState.status.transactions_unlocked) {
            attachTransactionsListeners();
        } else if (AppState.activeTab === 'categories' && AppState.status.categories_unlocked) {
            attachCategoriesListeners();
        } else if (AppState.activeTab === 'timeseries' && AppState.status.timeseries_unlocked) {
            attachTimeseriesListeners();
        }
    }
}

// Start app after DOM and all scripts load
let app;
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        app = new App();
    });
} else {
    app = new App();
}
