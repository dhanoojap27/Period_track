const jwt = require('jsonwebtoken');

const deliveryAuthMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      error: 'Unauthorized: No partner token provided.'
    });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Check if it's a partner token (we'll add a role field during login)
    if (decoded.role !== 'partner') {
      return res.status(403).json({
        success: false,
        error: 'Forbidden: Invalid access level.'
      });
    }

    req.partner = decoded;
    next();
  } catch (error) {
    console.error('Delivery JWT Error:', error.message);
    return res.status(401).json({
      success: false,
      error: 'Unauthorized: Invalid or expired partner token.'
    });
  }
};

module.exports = deliveryAuthMiddleware;
