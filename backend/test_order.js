async function test() {
    // Test CORS preflight (OPTIONS)
    const preflightRes = await fetch('http://localhost:3000/api/order/create', {
        method: 'OPTIONS',
        headers: {
            'Origin': 'http://localhost:5000',
            'Access-Control-Request-Method': 'POST',
            'Access-Control-Request-Headers': 'Content-Type'
        }
    });
    console.log('OPTIONS status:', preflightRes.status);
    console.log('CORS header:', preflightRes.headers.get('access-control-allow-origin'));

    // Test the actual create order endpoint with a dummy userId
    const res = await fetch('http://localhost:3000/api/order/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            userId: 'test-user-123',
            deliveryAddress: {
                name: 'Test User',
                phone: '1234567890',
                address: '123 Main St',
                city: 'Chennai',
                state: 'TN',
                zipCode: '600001'
            },
            paymentMethod: 'cod'
        })
    });
    console.log('POST status:', res.status);
    const json = await res.json();
    console.log('Response:', JSON.stringify(json, null, 2));
}
test().catch(console.error);
