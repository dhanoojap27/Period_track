document.addEventListener("DOMContentLoaded", () => {
    const token = sessionStorage.getItem('adminToken');
    if (!token) {
        window.location.href = '/admin/login.html';
        return;
    }

    window.logout = () => {
        sessionStorage.removeItem('adminToken');
        window.location.href = '/admin/login.html';
    };

    async function apiFetch(url, options = {}) {
        const headers = {
            'Authorization': `Bearer ${token}`,
            ...(options.headers || {})
        };
        const res = await fetch(url, { ...options, headers });
        if (res.status === 401) {
            logout(); // Kick to login
        }
        return res;
    }
    
    let partners = [];

    // Nav Logic
    const navLinks = document.querySelectorAll('.nav-links li');
    const tabContents = document.querySelectorAll('.tab-content');
    const addProductBtn = document.getElementById('add-product-btn');

    navLinks.forEach(link => {
        link.addEventListener('click', () => {
            // Remove active classes
            navLinks.forEach(l => l.classList.remove('active'));
            tabContents.forEach(tc => tc.classList.add('hidden'));
            
            // Add active class to clicked
            link.classList.add('active');
            const targetTab = link.getAttribute('data-tab');
            document.getElementById(targetTab).classList.remove('hidden');

            // Header adjustments
            const titleStr = link.innerText.trim();
            document.getElementById('page-title').innerText = titleStr;
            
            if (targetTab === 'products-tab') {
                addProductBtn.style.display = 'block';
                loadProducts();
            } else {
                addProductBtn.style.display = 'none';
            }

            if (targetTab === 'orders-tab') {
                loadOrders();
            }
        });
    });

    // API ENDPOINTS
    const API_BASE = '/api';

    // ==========================================
    // PRODUCTS LOGIC
    // ==========================================
    const prodModal = document.getElementById('product-modal');
    const closeBtn = document.getElementById('close-modal');
    const prodForm = document.getElementById('product-form');

    addProductBtn.addEventListener('click', () => openModal());
    closeBtn.addEventListener('click', closeModal);

    function openModal(prod = null) {
        prodModal.classList.add('show');
        if (prod) {
            document.getElementById('modal-title').innerText = 'Edit Product';
            document.getElementById('prod-id').value = prod.id;
            document.getElementById('prod-name').value = prod.name;
            document.getElementById('prod-price').value = prod.price;
            document.getElementById('prod-stock').value = prod.stock_quantity;
            document.getElementById('prod-cat').value = prod.category_id;
            document.getElementById('prod-desc').value = prod.description;
            document.getElementById('prod-img').value = prod.image_urls[0] || '';
            
            const preview = document.getElementById('prod-img-preview');
            if (prod.image_urls && prod.image_urls[0]) {
                preview.src = prod.image_urls[0];
                preview.style.display = 'block';
            } else {
                preview.style.display = 'none';
            }
        } else {
            document.getElementById('modal-title').innerText = 'Add New Product';
            prodForm.reset();
            document.getElementById('prod-id').value = '';
            document.getElementById('prod-img-preview').style.display = 'none';
        }
    }

    function closeModal() {
        prodModal.classList.remove('show');
    }

    async function loadPartners() {
        try {
            const res = await apiFetch(`${API_BASE}/delivery/partners`);
            const json = await res.json();
            if (json.success) partners = json.data;
        } catch (e) {
            console.error('Error loading partners', e);
        }
    }

    window.assignOrderToPartner = async (orderId, partnerId) => {
        if (!partnerId) return;
        try {
            const res = await apiFetch(`${API_BASE}/delivery/assign`, {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({orderId, partnerId: parseInt(partnerId)})
            });
            if(res.ok) {
                showToast('Success', 'Order assigned successfully!');
                loadOrders();
            } else {
                alert('Failed to assign partner');
            }
        } catch (e) { console.error(e); }
    }

    async function loadProducts() {
        try {
            const res = await apiFetch(`${API_BASE}/products`);
            const json = await res.json();
            const tbody = document.getElementById('products-table-body');
            tbody.innerHTML = '';
            
            document.getElementById('stat-total-products').innerText = json.count || 0;

            if(json.success && json.data) {
                window.cachedProducts = json.data; // cache for editing
                json.data.forEach(prod => {
                    const validImages = (prod.image_urls || []).filter(url => url && url.trim() !== '');
                    const img = validImages.length ? validImages[0] : 'https://placehold.co/40x40?text=NA';
                    const tr = document.createElement('tr');
                    tr.innerHTML = `
                        <td>
                            <img src="${img}" class="prod-img">
                            <strong>#${prod.id}</strong> ${prod.name}
                        </td>
                        <td>${prod.categories?.name || 'Unknown'}</td>
                        <td>₹${prod.price.toFixed(2)}</td>
                        <td>${prod.stock_quantity}</td>
                        <td>
                            <button class="action-btn" onclick="editProduct(${prod.id})"><ion-icon name="create-outline"></ion-icon></button>
                            <button class="action-btn delete" onclick="deleteProduct(${prod.id})"><ion-icon name="trash-outline"></ion-icon></button>
                        </td>
                    `;
                    tbody.appendChild(tr);
                });
            }
        } catch(e) { console.error('Error loading products', e); }
    }

    window.editProduct = (id) => {
        const prod = window.cachedProducts.find(p => p.id === id);
        if(prod) openModal(prod);
    };

    window.deleteProduct = async (id) => {
        if(!confirm('Are you sure you want to delete this product?')) return;
        try {
            const res = await apiFetch(`${API_BASE}/products/${id}`, { method: 'DELETE' });
            if(res.ok) {
                alert('Product deleted successfully');
                loadProducts();
            }
        } catch(e) { alert('Error deleting product'); }
    }

    // Image preview logic
    const imgInput = document.getElementById('prod-img');
    const imgPreview = document.getElementById('prod-img-preview');
    
    imgInput.addEventListener('input', () => {
        const url = imgInput.value;
        if (url && url.startsWith('http')) {
            imgPreview.src = url;
            imgPreview.style.display = 'block';
        } else {
            imgPreview.style.display = 'none';
        }
    });

    window.useDefaultImage = (type) => {
        let url = 'https://placehold.co/400x400/FFB6C1/FFFFFF/png?text=';
        switch(type) {
            case 'pads': url += 'Pads'; break;
            case 'medicine': url += 'Medicine'; break;
            case 'kit': url += 'Emergency+Kit'; break;
            default: url += 'Product';
        }
        imgInput.value = url;
        imgPreview.src = url;
        imgPreview.style.display = 'block';
    }

    prodForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        const id = document.getElementById('prod-id').value;
        const payload = {
            name: document.getElementById('prod-name').value,
            price: parseFloat(document.getElementById('prod-price').value),
            stock_quantity: parseInt(document.getElementById('prod-stock').value),
            category_id: parseInt(document.getElementById('prod-cat').value),
            description: document.getElementById('prod-desc').value,
            image_urls: [document.getElementById('prod-img').value].filter(url => url.trim() !== ''),
            is_active: true
        };

        try {
            let res;
            if (id) {
                // Update
                res = await apiFetch(`${API_BASE}/products/${id}`, {
                    method: 'PUT',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify(payload)
                });
            } else {
                // Create
                res = await apiFetch(`${API_BASE}/products`, {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify(payload)
                });
            }
            if(res.ok) {
                closeModal();
                loadProducts();
            } else {
                alert("Failed to save product.");
            }
        } catch(err) {
            console.error(err);
        }
    });

    // ==========================================
    // ORDERS LOGIC
    // ==========================================

    async function loadOrders() {
        try {
            const res = await apiFetch(`${API_BASE}/orders/all`);
            const json = await res.json();
            const tbody = document.getElementById('orders-table-body');
            tbody.innerHTML = '';

            if(json.success && json.data) {
                window.cachedOrders = json.data; // Store orders for viewing details
                document.getElementById('stat-total-orders').innerText = json.count || 0;

                json.data.forEach(order => {
                    const statusClass = ['pending','processing'].includes(order.status) ? 'pending' : order.status;
                    
                    // Check for assigned partner
                    const tracking = order.delivery_tracking && order.delivery_tracking.length > 0 ? order.delivery_tracking[0] : null;
                    const partnerName = tracking && tracking.delivery_partners ? tracking.delivery_partners.name : null;

                    const partnerHtml = partnerName 
                        ? `<div class="partner-assigned"><ion-icon name="person-circle-outline"></ion-icon> <span>${partnerName}</span></div>` 
                        : `<button class="btn btn-primary" style="padding: 6px 10px; font-size:12px;" onclick="assignPartner(${order.id})">Assign</button>`;

                    const paymentStatusClass = order.payment_status === 'awaiting_verification' ? 'warning' : order.payment_status;
                    const paymentHtml = `<div class="payment-info">
                        <span class="pay-method">${order.payment_method.toUpperCase()}</span>
                        <span class="pay-status ${paymentStatusClass}">${order.payment_status.replace('_', ' ')}</span>
                    </div>`;

                    const tr = document.createElement('tr');
                    
                    // Apply highlighting logic
                    if (!partnerName) {
                        tr.classList.add('row-highlight-unassigned');
                    } else if (order.status !== 'delivered') {
                        tr.classList.add('row-highlight-pending');
                    }

                    tr.innerHTML = `
                        <td><strong>${order.order_number}</strong></td>
                        <td>${new Date(order.created_at).toLocaleDateString()}</td>
                        <td>₹${order.final_amount.toFixed(2)}</td>
                        <td>${paymentHtml}</td>
                        <td>
                            ${partnerName 
                                ? `<div class="partner-assigned"><ion-icon name="person-circle-outline"></ion-icon> <span>${partnerName}</span></div>` 
                                : `
                                <select class="status-select" onchange="assignOrderToPartner(${order.id}, this.value)">
                                    <option value="">-- Choose Driver --</option>
                                    ${partners.map(p => `
                                        <option value="${p.id}">${p.name}</option>
                                    `).join('')}
                                </select>
                                `
                            }
                        </td>
                        <td>
                            <select class="status-select" onchange="updateOrderStatus(${order.id}, this.value)">
                                <option value="pending" ${order.status==='pending'?'selected':''}>Pending</option>
                                <option value="processing" ${order.status==='processing'?'selected':''}>Processing</option>
                                <option value="out_for_delivery" ${order.status==='out_for_delivery'?'selected':''}>Out for Delivery</option>
                                <option value="delivered" ${order.status==='delivered'?'selected':''}>Delivered</option>
                                <option value="cancelled" ${order.status==='cancelled'?'selected':''}>Cancelled</option>
                            </select>
                        </td>
                        <td>
                            <button class="btn btn-primary" style="padding: 4px 10px; font-size: 11px; display: inline-flex; align-items: center; gap: 4px;" onclick="openOrderModal(${order.id})">
                                <ion-icon name="eye-outline"></ion-icon> View
                            </button>
                        </td>
                    `;
                    tbody.appendChild(tr);
                });
            }
        } catch(e) { console.error('Error loading orders', e); }
    }

    window.updateOrderStatus = async (orderId, newStatus) => {
        try {
            const res = await apiFetch(`${API_BASE}/orders/status/${orderId}`, {
                method: 'PATCH',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({status: newStatus})
            });
            if(res.ok) {
                // Refresh local cache if needed or just reload
                loadOrders();
            } else {
                alert("Failed to update status");
            }
        } catch (e) { console.error(e); }
    }

    // Modal logic for Order Details
    const orderModal = document.getElementById('order-modal');
    const closeOrderBtn = document.getElementById('close-order-modal');

    closeOrderBtn.addEventListener('click', () => {
        orderModal.classList.remove('show');
    });

    window.openOrderModal = (orderId) => {
        const order = window.cachedOrders.find(o => o.id === orderId);
        if (!order) return;

        document.getElementById('view-order-number').innerText = `#${order.order_number}`;
        document.getElementById('view-order-status').innerText = order.status.toUpperCase();
        document.getElementById('view-order-status').className = `badge ${order.status}`;
        document.getElementById('view-order-address').innerText = order.delivery_address || 'N/A';
        document.getElementById('view-order-notes').innerText = order.notes || 'No notes';
        document.getElementById('view-order-total').innerText = `₹${order.final_amount.toFixed(2)}`;

        const itemsList = document.getElementById('order-items-list');
        itemsList.innerHTML = '';

        if (order.order_items && order.order_items.length > 0) {
            order.order_items.forEach(item => {
                const itemDiv = document.createElement('div');
                itemDiv.style.display = 'flex';
                itemDiv.style.justifyContent = 'space-between';
                itemDiv.style.padding = '8px 0';
                itemDiv.style.borderBottom = '1px solid #f9f9f9';
                itemDiv.innerHTML = `
                    <span>${item.product_name} x ${item.quantity}</span>
                    <span>₹${item.subtotal.toFixed(2)}</span>
                `;
                itemsList.appendChild(itemDiv);
            });
        } else {
            itemsList.innerHTML = '<p style="color: #999;">No items found in this order.</p>';
        }

        orderModal.classList.add('show');
    };

    window.assignPartner = async (orderId) => {
        // Hardcoded partner ID for demo
        const partnerId = 1; 
        try {
            const res = await apiFetch(`${API_BASE}/delivery/assign`, {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({orderId, partnerId})
            });
            if(res.ok) {
                alert('Delivery partner assigned successfully!');
                // Auto-update order to out_for_delivery
                updateOrderStatus(orderId, 'out_for_delivery');
                loadOrders();
            } else {
                alert('Failed to assign partner');
            }
        } catch (e) { console.error(e); }
    }

    // ==========================================
    // NOTIFICATIONS LOGIC
    // ==========================================
    const bell = document.getElementById('notification-bell');
    const badge = document.getElementById('notification-badge');
    const dropdown = document.getElementById('notification-dropdown');
    const list = document.getElementById('notification-list');
    const clearBtn = document.getElementById('clear-notifications');
    const toastContainer = document.getElementById('toast-container');

    let lastNotificationId = 0;

    bell.addEventListener('click', (e) => {
        e.stopPropagation();
        dropdown.classList.toggle('hidden');
        if (!dropdown.classList.contains('hidden')) {
            loadNotifications();
        }
    });

    document.addEventListener('click', () => dropdown.classList.add('hidden'));
    dropdown.addEventListener('click', (e) => e.stopPropagation());

    async function loadNotifications() {
        try {
            const res = await apiFetch(`${API_BASE}/notifications/admin`);
            const json = await res.json();
            if (json.success) {
                renderNotifications(json.data);
                updateBadge(json.data);
            }
        } catch (e) { console.error('Error loading notifications', e); }
    }

    function renderNotifications(notifications) {
        if (!notifications || notifications.length === 0) {
            list.innerHTML = '<div class="empty-state">No new notifications</div>';
            return;
        }

        list.innerHTML = notifications.map(n => `
            <div class="notification-item ${n.is_read ? '' : 'unread'}" onclick="markAsRead(${n.id})">
                <div class="notification-message">${n.message}</div>
                <div class="notification-time">${new Date(n.created_at).toLocaleTimeString()}</div>
            </div>
        `).join('');
    }

    function updateBadge(notifications) {
        const unreadCount = notifications.filter(n => !n.is_read).length;
        if (unreadCount > 0) {
            badge.innerText = unreadCount;
            badge.classList.remove('hidden');
        } else {
            badge.classList.add('hidden');
        }
    }

    window.markAsRead = async (id) => {
        try {
            await apiFetch(`${API_BASE}/notifications/read/${id}`, { method: 'PATCH' });
            loadNotifications();
        } catch (e) { console.error(e); }
    };

    clearBtn.addEventListener('click', async () => {
        try {
            await apiFetch(`${API_BASE}/notifications/clear-all`, { method: 'DELETE' });
            loadNotifications();
        } catch (e) { console.error(e); }
    });

    // POLLING FOR REAL-TIME UPDATES
    async function pollUpdates() {
        try {
            const res = await apiFetch(`${API_BASE}/notifications/admin`);
            const json = await res.json();
            
            if (json.success && json.data.length > 0) {
                const latest = json.data[0];
                
                // If we found a new notification ID
                if (latest.id > lastNotificationId) {
                    lastNotificationId = latest.id;
                    
                    // Show Toast
                    showToast('Delivery Update', latest.message);
                    
                    // Update UI
                    updateBadge(json.data);
                    
                    // AUTO-REFRESH ORDERS TABLE!
                    // This satisfies the "automatically change status" requirement
                    const currentTab = document.querySelector('.nav-links li.active').getAttribute('data-tab');
                    if (currentTab === 'orders-tab' || currentTab === 'dashboard-tab') {
                        loadOrders();
                    }
                }
            }
        } catch (e) { console.error('Polling error', e); }
    }

    function showToast(title, message) {
        const toast = document.createElement('div');
        toast.className = 'toast';
        toast.innerHTML = `
            <div class="toast-icon"><ion-icon name="information-circle"></ion-icon></div>
            <div class="toast-content">
                <div class="toast-title">${title}</div>
                <div class="toast-msg">${message}</div>
            </div>
        `;
        toastContainer.appendChild(toast);

        // Auto remove
        setTimeout(() => {
            toast.classList.add('fade-out');
            setTimeout(() => toast.remove(), 300);
        }, 5000);
    }

    // Set initial ID so we don't toast old notifications on load
    apiFetch(`${API_BASE}/notifications/admin`).then(r => r.json()).then(j => {
        if(j.success && j.data.length > 0) lastNotificationId = j.data[0].id;
    });

    // Start Polling every 10 seconds
    setInterval(pollUpdates, 10000);

    // INITIAL LOAD
    loadPartners().then(() => {
        loadProducts();
        loadOrders();
    });
    
    // Simulate some active drivers
    document.getElementById('stat-active-drivers').innerText = "12";
});
