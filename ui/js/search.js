/**
 * Semantic Search Tab Component
 */

let searchResults = [];
let searchQuery = '';

/**
 * Show toast with search timing
 */
function showSearchToast(message, searchMs, roundtripMs) {
    const existing = document.getElementById('api-toast');
    if (existing) existing.remove();

    const toast = document.createElement('div');
    toast.id = 'api-toast';
    toast.className = 'fixed bottom-4 right-4 bg-gray-900 text-white px-4 py-3 rounded-lg shadow-lg text-sm font-medium z-50 transition-opacity duration-300';

    const g = (ms) => `<span style="color: #86efac">${ms}ms</span>`;
    toast.innerHTML = `${message} | FT.SEARCH: ${g(searchMs)} | Roundtrip: ${g(roundtripMs)}`;
    document.body.appendChild(toast);

    setTimeout(() => toast.style.opacity = '0', 3500);
    setTimeout(() => toast.remove(), 4000);
}

function renderSearchTab() {
    return `
        <div>
            <!-- Search Input -->
            <div class="mb-6">
                <h2 class="text-lg font-medium mb-4">Semantic Transaction Search</h2>
                <div class="flex gap-3">
                    <input
                        type="text"
                        id="search-input"
                        placeholder="Try: 'coffee shops', 'travel transactions', 'restaurants in Florida'..."
                        class="flex-1 px-4 py-3 border border-gray-200 rounded-lg focus:outline-none focus:border-gray-400"
                        value="${searchQuery}"
                    />
                    <button
                        id="search-btn"
                        class="px-6 py-3 bg-black text-white rounded-lg hover:bg-gray-800 transition-colors"
                    >
                        Search
                    </button>
                </div>
                <p class="text-xs text-gray-400 mt-2">
                    Uses vector similarity search to find semantically related transactions
                </p>
            </div>

            <!-- Results -->
            <div id="search-results">
                ${renderSearchResults()}
            </div>
        </div>
    `;
}

function renderSearchResults() {
    if (searchResults.length === 0 && !searchQuery) {
        return `
            <div class="text-center py-12 text-gray-500">
                <div class="text-4xl mb-4">🔍</div>
                <p>Enter a search query to find transactions</p>
                <p class="text-sm mt-2">Examples: "grocery stores", "travel expenses", "entertainment"</p>
            </div>
        `;
    }

    if (searchResults.length === 0 && searchQuery) {
        return `
            <div class="text-center py-12 text-gray-500">
                <p>No results found for "${searchQuery}"</p>
                <p class="text-sm mt-2">Make sure the Vector Search module is complete and transactions have embeddings.</p>
            </div>
        `;
    }

    return `
        <div class="border border-gray-200 rounded-lg overflow-hidden">
            <table class="w-full">
                <thead class="bg-gray-50 border-b border-gray-200">
                    <tr>
                        <th class="text-left px-4 py-3 text-sm font-medium text-gray-600">Similarity</th>
                        <th class="text-left px-4 py-3 text-sm font-medium text-gray-600">Merchant</th>
                        <th class="text-left px-4 py-3 text-sm font-medium text-gray-600">Category</th>
                        <th class="text-left px-4 py-3 text-sm font-medium text-gray-600">Location</th>
                        <th class="text-right px-4 py-3 text-sm font-medium text-gray-600">Amount</th>
                    </tr>
                </thead>
                <tbody>
                    ${searchResults.map(tx => {
                        // Convert COSINE distance to similarity percentage (1 - distance) * 100
                        const similarity = Math.round((1 - tx.score) * 100);
                        return `
                            <tr class="border-b border-gray-100">
                                <td class="px-4 py-3">
                                    <div class="flex items-center gap-2">
                                        <div class="w-16 bg-gray-200 rounded-full h-2">
                                            <div class="bg-green-500 h-2 rounded-full" style="width: ${similarity}%"></div>
                                        </div>
                                        <span class="text-sm text-gray-600">${similarity}%</span>
                                    </div>
                                </td>
                                <td class="px-4 py-3 text-sm font-medium">${tx.merchant}</td>
                                <td class="px-4 py-3">
                                    <span class="px-2 py-1 bg-gray-100 rounded text-sm">${tx.category}</span>
                                </td>
                                <td class="px-4 py-3 text-sm text-gray-600">${tx.location}</td>
                                <td class="px-4 py-3 text-sm text-right font-medium">
                                    $${parseFloat(tx.amount).toFixed(2)}
                                </td>
                            </tr>
                        `;
                    }).join('')}
                </tbody>
            </table>
        </div>
    `;
}

async function performSearch(query) {
    if (!query || query.length < 2) return;

    searchQuery = query;

    try {
        const url = `${API_BASE}/api/search?q=${encodeURIComponent(query)}&limit=10`;
        const res = await fetch(url);
        const data = await res.json();
        const timing = performance.getEntriesByName(url).pop();
        const duration = Math.round(timing?.duration ?? 0);

        if (data.error) {
            searchResults = [];
            updateSearchResults();
            showToast('Search not ready', 'FT.SEARCH', 0, duration);
            return;
        }

        searchResults = data.results;
        updateSearchResults();
        showSearchToast(`Found ${data.count} results`, data.search_ms, duration);
    } catch (err) {
        console.error('Search failed:', err);
        searchResults = [];
        updateSearchResults();
    }
}

function updateSearchResults() {
    const container = document.getElementById('search-results');
    if (container) {
        container.innerHTML = renderSearchResults();
    }
}

function attachSearchListeners() {
    const input = document.getElementById('search-input');
    const btn = document.getElementById('search-btn');

    if (btn) {
        btn.onclick = () => {
            const query = input?.value?.trim();
            if (query) performSearch(query);
        };
    }

    if (input) {
        input.onkeypress = (e) => {
            if (e.key === 'Enter') {
                const query = input.value.trim();
                if (query) performSearch(query);
            }
        };
    }
}
