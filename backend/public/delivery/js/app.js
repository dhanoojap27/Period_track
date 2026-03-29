const API_BASE = '/api/delivery';

// State management
let activeOrders = [];
let historyOrders = [];
let currentTrackingId = null;
let selectedStatus = null;

// DOM Elements
const loginScreen = document.getElementById('login-screen');
const dashboardScreen = document.getElementById('dashboard-screen');
const loginForm = document.getElementById('login-form');
const activeOrdersList = document.getElementById('active-orders-list');
const historyOrdersList = document.getElementById('history-orders-list');
const statusModal = document.getElementById('status-modal');
const partnerNameDisplay = document.getElementById('partner-name');
const partnerVehicleDisplay = document.getElementById('partner-vehicle');

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    checkAuth();
    setupEventListeners();
});

function checkAuth() {
    const token = sessionStorage.getItem('partner_token');
    const partner = JSON.parse(sessionStorage.getItem('partner_data'));

    if (token && partner) {
        showDashboard(partner);
    } else {
        showLogin();
    }
}

function showLogin() {
    loginScreen.classList.remove('hidden');
    dashboardScreen.classList.add('hidden');
}

function showDashboard(partner) {
    loginScreen.classList.add('hidden');
    dashboardScreen.classList.remove('hidden');
    partnerNameDisplay.innerText = `Welcome, ${partner.name}!`;
    partnerVehicleDisplay.innerText = partner.vehicle || 'No vehicle assigned';
    loadActiveOrders();
}

function setupEventListeners() {
    // Login
    loginForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        const email = document.getElementById('login-email').value;
        const password = document.getElementById('login-password').value;
        const errorText = document.getElementById('login-error');

        try {
            const res = await fetch(`${API_BASE}/login`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email, password })
            });
            const data = await res.json();

            if (data.success) {
                sessionStorage.setItem('partner_token', data.token);
                sessionStorage.setItem('partner_data', JSON.stringify(data.partner));
                showDashboard(data.partner);
            } else {
                errorText.innerText = data.error || 'Login failed';
            }
        } catch (err) {
            errorText.innerText = 'Network error. Please try again.';
        }
    });

    // Logout
    document.getElementById('logout-btn').addEventListener('click', () => {
        sessionStorage.clear();
        showLogin();
    });

    // Tabs
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            
            const tab = btn.dataset.tab;
            if (tab === 'active') {
                document.getElementById('active-tab').classList.remove('hidden');
                document.getElementById('history-tab').classList.add('hidden');
                loadActiveOrders();
            } else {
                document.getElementById('active-tab').classList.add('hidden');
                document.getElementById('history-tab').classList.remove('hidden');
                loadHistory();
            }
        });
    });

    // Refresh
    document.getElementById('refresh-btn').addEventListener('click', () => {
        const activeTab = document.querySelector('.tab-btn.active').dataset.tab;
        if (activeTab === 'active') loadActiveOrders();
        else loadHistory();
    });

    // Status Modal
    document.getElementById('close-modal').addEventListener('click', () => statusModal.classList.add('hidden'));
    
    document.querySelectorAll('.status-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.status-btn').forEach(b => b.classList.remove('selected'));
            btn.classList.add('selected');
            selectedStatus = btn.dataset.status;
        });
    });

    document.getElementById('confirm-status').addEventListener('click', updateStatus);
}

// Data Fetching
async function loadActiveOrders() {
    activeOrdersList.innerHTML = '<div class="loading">Loading assignments...</div>';
    const token = sessionStorage.getItem('partner_token');

    try {
        const res = await fetch(`${API_BASE}/my-orders`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        const data = await res.json();

        if (data.success) {
            activeOrders = data.data;
            renderActiveOrders();
        } else if (res.status === 401) {
            handleSessionExpired();
        }
    } catch (err) {
        activeOrdersList.innerHTML = '<div class="error-text">Failed to load orders.</div>';
    }
}

async function loadHistory() {
    historyOrdersList.innerHTML = '<div class="loading">Loading history...</div>';
    const token = sessionStorage.getItem('partner_token');

    try {
        const res = await fetch(`${API_BASE}/my-history`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        const data = await res.json();

        if (data.success) {
            historyOrders = data.data;
            renderHistory();
        }
    } catch (err) {
        historyOrdersList.innerHTML = '<div class="error-text">Failed to load history.</div>';
    }
}

// Rendering
// Helper to get proxy URL for images
function getProxyUrl(url) {
    if (!url) return 'https://placehold.co/100x100/FF4081/FFFFFF/png?text=Item';
    if (url.startsWith('data:')) return url;
    return `/api/proxy?url=${encodeURIComponent(url)}`;
}

function renderActiveOrders() {
    if (activeOrders.length === 0) {
        activeOrdersList.innerHTML = '<div class="empty-state">🎉 All caught up! No active orders.</div>';
        return;
    }

    activeOrdersList.innerHTML = activeOrders.map(track => {
        const order = track.orders;
        const isEmergency = order.is_emergency_order;
        
        // Product chips with thumbnails
        const itemsHtml = (order.order_items || []).map(item => `
            <div class="item-chip">
                <img src="${getProxyUrl(item.image_url)}" class="item-thumb" onerror="this.src='https://placehold.co/100x100/FF4081/FFFFFF/png?text=Item'">
                <div class="item-meta">
                    <span class="item-name">${item.product_name}</span>
                    <span class="item-qty">x ${item.quantity}</span>
                </div>
            </div>
        `).join('');
        
        return `
            <div class="order-card ${isEmergency ? 'emergency' : ''}">
                <div class="order-header">
                    <span class="order-no">#${order.order_number}</span>
                    <span class="status-badge status-${track.status}">${track.status.replace('_', ' ')}</span>
                </div>
                
                <div class="order-info">
                    <p class="customer-name"><i class="fas fa-user-circle"></i> ${order.customer_name || 'Guest Customer'}</p>
                    <p class="address-text"><i class="fas fa-map-marker-alt"></i> ${order.delivery_address}</p>
                    
                    ${order.customer_phone ? `
                        <a href="tel:${order.customer_phone}" class="call-link">
                            <i class="fas fa-phone-alt"></i> ${order.customer_phone}
                            <span class="tag">Tap to Call</span>
                        </a>
                    ` : ''}

                    <div class="items-summary">
                        <h4 class="section-title">Verified Items</h4>
                        <div class="items-grid">
                            ${itemsHtml}
                        </div>
                    </div>
                </div>

                <div class="order-footer">
                    <div class="order-total">
                        <span>Total Pay</span>
                        <strong>₹${parseFloat(order.total_amount).toFixed(2)}</strong>
                    </div>
                    <button class="btn btn-primary" onclick="openStatusModal(${track.id}, '${order.order_number}', '${track.status}')">
                        Update Status
                    </button>
                </div>
            </div>
        `;
    }).join('');
}

function renderHistory() {
    if (historyOrders.length === 0) {
        historyOrdersList.innerHTML = '<div class="empty-state">No history yet.</div>';
        return;
    }

    historyOrdersList.innerHTML = historyOrders.map(track => {
        const order = track.orders;
        return `
            <div class="order-card history-card" style="opacity: 0.8;">
                <div class="order-header">
                    <span class="order-no">#${order.order_number}</span>
                    <span class="status-badge status-delivered">Delivered</span>
                </div>
                <div class="order-info">
                    <p><i class="fas fa-user"></i> ${order.customer_name || 'Customer'}</p>
                    <p><i class="fas fa-calendar-alt"></i> ${new Date(track.delivered_at).toLocaleDateString()}</p>
                </div>
            </div>
        `;
    }).join('');
}

// UI Handlers
window.selectStatus = (btn) => {
    document.querySelectorAll('.status-btn').forEach(b => b.classList.remove('selected'));
    btn.classList.add('selected');
    selectedStatus = btn.getAttribute('data-status');
};

// Status Updates
window.openStatusModal = (id, orderNo, status) => {
    currentTrackingId = id;
    selectedStatus = status;
    document.getElementById('modal-order-number').innerText = `Order #${orderNo}`;
    document.getElementById('status-notes').value = '';
    
    // Pred-select current or next logical status
    document.querySelectorAll('.status-btn').forEach(btn => {
        btn.classList.remove('selected');
        if (btn.dataset.status === status) {
            btn.classList.add('selected');
        }
    });

    statusModal.classList.remove('hidden');
};

async function updateStatus() {
    if (!selectedStatus) return alert('Please select a status');
    
    const token = sessionStorage.getItem('partner_token');
    const notes = document.getElementById('status-notes').value;
    const btn = document.getElementById('confirm-status');
    
    btn.disabled = true;
    btn.innerText = 'Updating...';

    try {
        const res = await fetch(`${API_BASE}/status-update/${currentTrackingId}`, {
            method: 'PATCH',
            headers: { 
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({ status: selectedStatus, notes })
        });
        
        const data = await res.json();
        if (data.success) {
            statusModal.classList.add('hidden');
            loadActiveOrders();
        } else {
            alert(data.error || 'Failed to update status');
        }
    } catch (err) {
        alert('Communication error with server');
    } finally {
        btn.disabled = false;
        btn.innerText = 'Update';
    }
}

function handleSessionExpired() {
    sessionStorage.clear();
    showLogin();
    alert('Session expired. Please login again.');
}
