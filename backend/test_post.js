async function test() {
    const login = await fetch('http://localhost:3000/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username: 'admin', password: 'admin123' })
    });
    const { token } = await login.json();

    const payload = {
        name: "Test Pad",
        price: 9.99,
        stock_quantity: 10,
        category_id: 1,
        description: "Test Desc",
        image_urls: [""],
        is_active: true
    };

    const res = await fetch('http://localhost:3000/api/products', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(payload)
    });
    console.log(JSON.stringify(await res.json(), null, 2));
}
test();
