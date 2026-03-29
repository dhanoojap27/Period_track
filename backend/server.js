const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
// Allow Flutter web app (runs on different port) + admin dashboard
const corsOptions = {
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  preflightContinue: false,
  optionsSuccessStatus: 204
};
app.use(cors(corsOptions));
// Helmet (relaxed for development to allow inline scripts and icons)
app.use(helmet({
  crossOriginResourcePolicy: false,
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'", "https://unpkg.com"],
      scriptSrcAttr: ["'unsafe-inline'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com", "https://unpkg.com"],
      fontSrc: ["'self'", "https://fonts.gstatic.com", "https://unpkg.com"],
      imgSrc: ["'self'", "data:", "blob:", "*"],
      connectSrc: ["'self'", "https://vfzbewmyektmblkzlirp.supabase.co", "*"]
    }
  }
}));
app.use(morgan('dev'));

// Logger middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static portals
app.use('/admin', express.static(path.join(__dirname, 'public', 'admin')));
app.use('/delivery', express.static(path.join(__dirname, 'public', 'delivery')));

// Import routes
const adminAuthRoutes = require('./src/routes/adminAuth');
const productRoutes = require('./src/routes/products');
const orderRoutes = require('./src/routes/orders');
const deliveryRoutes = require('./src/routes/delivery');
const notificationRoutes = require('./src/routes/notifications');
const cartRoutes = require('./src/routes/cart');

// Use routes
app.use('/api/admin', adminAuthRoutes);
app.use('/api/products', productRoutes);
app.use('/api/order', orderRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/delivery', deliveryRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/cart', cartRoutes);

// Image proxy to bypass CORS for external images (Google Images, etc)
app.get('/api/proxy', async (req, res) => {
  const imageUrl = req.query.url;
  if (!imageUrl) return res.status(400).send('URL is required');

  try {
    const response = await fetch(imageUrl);
    const contentType = response.headers.get('content-type');
    if (contentType) res.setHeader('Content-Type', contentType);
    res.setHeader('Access-Control-Allow-Origin', '*');
    
    const arrayBuffer = await response.arrayBuffer();
    res.send(Buffer.from(arrayBuffer));
  } catch (err) {
    console.error('Proxy error:', err);
    res.status(500).send('Error fetching image');
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    message: '🚀 Period Tracker Delivery System API is running!',
    supabase_connected: !!process.env.SUPABASE_URL
  });
});

// API Root endpoint
app.get('/api', (req, res) => {
  res.json({ 
    message: 'Welcome to Period Tracker Delivery API',
    version: '1.0.0',
    endpoints: {
      products: '/api/products',
      cart: '/api/cart',
      orders: '/api/orders',
      delivery: '/api/delivery',
      health: '/health'
    }
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ 
    success: false,
    error: 'Route not found' 
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('❌ Error:', err);
  res.status(500).json({ 
    success: false,
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`
╔═══════════════════════════════════════════╗
║   🚀 Delivery System API Running!         ║
║                                           ║
║   ➜ Local:    http://localhost:${PORT}     ║
║   ➜ Health:   http://localhost:${PORT}/health ║
║   ➜ API:      http://localhost:${PORT}/api   ║
║                                           ║
║   ➜ Environment: ${process.env.NODE_ENV.padEnd(12)}       ║
║   ➜ Supabase:  Connected                  ║
╚═══════════════════════════════════════════╝
  `);
});
