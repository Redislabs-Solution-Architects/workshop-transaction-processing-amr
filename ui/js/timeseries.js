/**
 * Track Spending Over Time Tab Component
 */

let timeseriesChart = null;
let currentFilter = '7day';

function renderTimeseriesTab() {
    return `
        <div>
            <!-- Controls -->
            <div class="flex items-center justify-between mb-6">
                <h2 class="text-lg font-medium">Spending Over Time</h2>
                <div class="flex gap-2">
                    <button
                        class="filter-btn px-4 py-2 text-sm rounded-lg transition-colors ${
                            currentFilter === '1day' ? 'bg-black text-white' : 'bg-gray-100 hover:bg-gray-200'
                        }"
                        data-filter="1day"
                    >
                        1 Day
                    </button>
                    <button
                        class="filter-btn px-4 py-2 text-sm rounded-lg transition-colors ${
                            currentFilter === '3day' ? 'bg-black text-white' : 'bg-gray-100 hover:bg-gray-200'
                        }"
                        data-filter="3day"
                    >
                        3 Days
                    </button>
                    <button
                        class="filter-btn px-4 py-2 text-sm rounded-lg transition-colors ${
                            currentFilter === '7day' ? 'bg-black text-white' : 'bg-gray-100 hover:bg-gray-200'
                        }"
                        data-filter="7day"
                    >
                        7 Days
                    </button>
                    <button
                        class="filter-btn px-4 py-2 text-sm rounded-lg transition-colors ${
                            currentFilter === '30day' ? 'bg-black text-white' : 'bg-gray-100 hover:bg-gray-200'
                        }"
                        data-filter="30day"
                    >
                        30 Days
                    </button>
                </div>
            </div>

            <!-- Chart -->
            <div class="bg-white border border-gray-200 rounded-lg p-6">
                <canvas id="spending-chart"></canvas>
            </div>

            <!-- Summary -->
            <div id="spending-summary" class="mt-6 grid grid-cols-3 gap-4">
                <!-- Will be populated by data -->
            </div>
        </div>
    `;
}

async function loadTimeseriesData(days) {
    try {
        const res = await fetch(`${API_BASE}/api/spending/range?days=${days}`);
        const data = await res.json();

        if (data.error || !data.data) {
            updateChart([]);
            updateSummary(null);
            return;
        }

        updateChart(data.data);
        updateSummary(data);
    } catch (err) {
        console.error('Failed to load timeseries data:', err);
        updateChart([]);
        updateSummary(null);
    }
}

function updateChart(dataPoints) {
    const canvas = document.getElementById('spending-chart');
    if (!canvas) return;

    // Destroy existing chart
    if (timeseriesChart) {
        timeseriesChart.destroy();
    }

    if (dataPoints.length === 0) {
        const ctx = canvas.getContext('2d');
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.font = '14px -apple-system, BlinkMacSystemFont, "Segoe UI", "Roboto", sans-serif';
        ctx.fillStyle = '#9ca3af';
        ctx.textAlign = 'center';
        ctx.fillText('No data available. Complete the TimeSeries module.', canvas.width / 2, canvas.height / 2);
        return;
    }

    // Prepare data
    const labels = dataPoints.map(dp => new Date(dp.timestamp).toLocaleDateString());
    const amounts = dataPoints.map(dp => parseFloat(dp.amount));

    // Create chart
    const ctx = canvas.getContext('2d');
    timeseriesChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [{
                label: 'Spending',
                data: amounts,
                borderColor: '#1f1f1f',
                backgroundColor: 'rgba(31, 31, 31, 0.1)',
                borderWidth: 2,
                tension: 0.4,
                fill: true
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: true,
            aspectRatio: 2.5,
            plugins: {
                legend: {
                    display: false
                },
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            return '$' + context.parsed.y.toFixed(2);
                        }
                    }
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        callback: function(value) {
                            return '$' + value.toFixed(0);
                        }
                    }
                }
            }
        }
    });
}

function updateSummary(data) {
    const container = document.getElementById('spending-summary');
    if (!container) return;

    if (!data || data.count === 0) {
        container.innerHTML = '';
        return;
    }

    const avgSpending = data.total_spent / data.count;

    container.innerHTML = `
        <div class="bg-gray-50 rounded-lg p-4">
            <div class="text-sm text-gray-600 mb-1">Total Spent</div>
            <div class="text-2xl font-medium">$${parseFloat(data.total_spent).toFixed(2)}</div>
        </div>
        <div class="bg-gray-50 rounded-lg p-4">
            <div class="text-sm text-gray-600 mb-1">Transactions</div>
            <div class="text-2xl font-medium">${data.count}</div>
        </div>
        <div class="bg-gray-50 rounded-lg p-4">
            <div class="text-sm text-gray-600 mb-1">Average</div>
            <div class="text-2xl font-medium">$${avgSpending.toFixed(2)}</div>
        </div>
    `;
}

function attachTimeseriesListeners() {
    // Filter buttons
    document.querySelectorAll('[data-filter]').forEach(btn => {
        btn.onclick = () => {
            currentFilter = btn.dataset.filter;
            const days = parseInt(currentFilter.replace('day', ''));
            app.render();
            loadTimeseriesData(days);
        };
    });

    // Auto-load on mount
    const days = parseInt(currentFilter.replace('day', ''));
    loadTimeseriesData(days);
}
