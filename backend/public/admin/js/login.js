document.getElementById('login-btn').addEventListener('click', async () => {
    const username = document.getElementById('username').value;
    const password = document.getElementById('password').value;
    const errorMsg = document.getElementById('login-error');
    const btn = document.getElementById('login-btn');

    if(!username || !password) {
        errorMsg.innerText = 'Please enter both username and password';
        errorMsg.style.display = 'block';
        return;
    }

    btn.disabled = true;
    btn.innerText = 'Signing in...';
    errorMsg.style.display = 'none';

    try {
        const res = await fetch('/api/admin/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, password })
        });

        const json = await res.json();
        if (json.success) {
            alert('Login successful! Welcome to the Admin Dashboard.');
            sessionStorage.setItem('adminToken', json.token);
            window.location.href = '/admin/';
        } else {
            errorMsg.innerText = json.error || 'Invalid credentials';
            errorMsg.style.display = 'block';
        }
    } catch (err) {
        errorMsg.innerText = 'Network error. Please make sure the server is running.';
        errorMsg.style.display = 'block';
    } finally {
        btn.disabled = false;
        btn.innerText = 'Sign In';
    }
});

// Redirect if already logged in
if (sessionStorage.getItem('adminToken')) {
    window.location.href = '/admin/';
}
