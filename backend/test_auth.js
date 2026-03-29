async function test() {
    const res = await fetch('http://localhost:3000/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username: 'admin', password: 'admin123' })
    });
    const json = await res.json();
    console.log('Login:', json);

    const res2 = await fetch('http://localhost:3000/api/orders/all', {
        headers: { 'Authorization': `Bearer ${json.token}` }
    });
    console.log('Auth check status:', res2.status);
    const json2 = await res2.json();
    console.log('Orders:', json2);
}
test();
