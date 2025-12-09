/**
 * Spending Categories Tab Component
 */

let categoriesData = [];
let selectedCategory = null;
let categoryTransactions = [];

function renderCategoriesTab() {
    return `
        <div class="flex gap-6">
            <!-- Categories List -->
            <div class="w-80">
                <div class="flex items-center justify-between mb-6">
                    <h2 class="text-lg font-medium">Top Categories</h2>
                    <button
                        id="refresh-categories"
                        class="px-4 py-2 text-sm bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
                    >
                        Refresh
                    </button>
                </div>

                <div id="categories-list">
                    <div class="text-center py-8 text-gray-500">
                        Click refresh to load categories
                    </div>
                </div>
            </div>

            <!-- Category Merchants -->
            <div class="flex-1">
                ${selectedCategory ? `
                    <h3 class="text-lg font-medium mb-6">
                        Top Merchants: ${selectedCategory}
                    </h3>
                    <div id="category-merchants">
                        <div class="text-center py-8 text-gray-500">
                            Loading...
                        </div>
                    </div>
                ` : `
                    <div class="flex items-center justify-center h-full text-gray-500">
                        Select a category to view top merchants
                    </div>
                `}
            </div>
        </div>
    `;
}

async function loadCategories() {
    try {
        const res = await fetch(`${API_BASE}/api/categories/top?limit=10`);
        const data = await res.json();

        if (data.error || !data.categories) {
            updateCategoriesList([]);
            return;
        }

        categoriesData = data.categories;
        updateCategoriesList(categoriesData);
    } catch (err) {
        console.error('Failed to load categories:', err);
        updateCategoriesList([]);
    }
}

function updateCategoriesList(categories) {
    const container = document.getElementById('categories-list');
    if (!container) return;

    if (categories.length === 0) {
        container.innerHTML = `
            <div class="text-center py-8 text-gray-500">
                No categories found. Complete the Sorted Set module to see data.
            </div>
        `;
        return;
    }

    container.innerHTML = `
        <div class="space-y-2">
            ${categories.map(cat => `
                <button
                    class="w-full text-left px-4 py-3 rounded-lg hover:bg-gray-50 transition-colors border border-gray-200 ${
                        selectedCategory === cat.category ? 'bg-gray-50 border-gray-300' : ''
                    }"
                    data-category="${cat.category}"
                >
                    <div class="flex items-center justify-between">
                        <span class="font-medium">${cat.category}</span>
                        <span class="text-sm text-gray-600">
                            $${parseFloat(cat.total_spent).toFixed(2)}
                        </span>
                    </div>
                </button>
            `).join('')}
        </div>
    `;

    // Attach click handlers
    document.querySelectorAll('[data-category]').forEach(btn => {
        btn.onclick = () => {
            selectedCategory = btn.dataset.category;
            app.render();
            loadCategoryMerchants(selectedCategory);
        };
    });
}

async function loadCategoryMerchants(category) {
    try {
        const res = await fetch(`${API_BASE}/api/categories/${encodeURIComponent(category)}/top?limit=10`);
        const data = await res.json();

        if (data.error || !data.merchants) {
            updateCategoryMerchants([]);
            return;
        }

        categoryTransactions = data.merchants;
        updateCategoryMerchants(categoryTransactions);
    } catch (err) {
        console.error('Failed to load category merchants:', err);
        updateCategoryMerchants([]);
    }
}

function updateCategoryMerchants(merchants) {
    const container = document.getElementById('category-merchants');
    if (!container) return;

    if (merchants.length === 0) {
        container.innerHTML = `
            <div class="text-center py-8 text-gray-500">
                No merchants found for this category.
            </div>
        `;
        return;
    }

    container.innerHTML = `
        <div class="border border-gray-200 rounded-lg overflow-hidden">
            <table class="w-full">
                <thead class="bg-gray-50 border-b border-gray-200">
                    <tr>
                        <th class="text-left px-4 py-3 text-sm font-medium text-gray-600">Merchant</th>
                        <th class="text-right px-4 py-3 text-sm font-medium text-gray-600">Total Spent</th>
                    </tr>
                </thead>
                <tbody>
                    ${merchants.map(m => `
                        <tr class="border-b border-gray-100">
                            <td class="px-4 py-3 text-sm">${m.merchant}</td>
                            <td class="px-4 py-3 text-sm text-right font-medium">
                                $${parseFloat(m.amount).toFixed(2)}
                            </td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        </div>
    `;
}

function attachCategoriesListeners() {
    const refreshBtn = document.getElementById('refresh-categories');
    if (refreshBtn) {
        refreshBtn.onclick = () => {
            loadCategories();
            if (selectedCategory) {
                loadCategoryMerchants(selectedCategory);
            }
        };
    }

    // Auto-load on mount
    loadCategories();
}
