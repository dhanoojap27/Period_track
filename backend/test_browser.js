async function run() {
    const res = await fetch('http://localhost:3000/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username: 'admin', password: 'admin123' })
    });
    const { token } = await res.json();
    
    // Simulate apiFetch for orders
    const headers = {
        'Authorization': `Bearer ${token}`,
    };
    
    console.log("Headers for Orders API:", headers);

    const orderRes = await fetch('http://localhost:3000/api/orders/all', {
        headers
    });
    
    console.log("Orders status:", orderRes.status);
    console.log(await orderRes.json());
}
run();
