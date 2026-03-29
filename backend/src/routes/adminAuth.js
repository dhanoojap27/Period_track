const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');

/**
 * @route   POST /api/admin/login
 * @desc    Authenticate admin and get JWT token
 * @access  Public
 */
router.post('/login', (req, res) => {
  const { username, password } = req.body;

  // Simple hardcoded check against environment variables
  if (
    username === process.env.ADMIN_USERNAME && 
    password === process.env.ADMIN_PASSWORD
  ) {
    // Generate a token valid for 24 hours
    const token = jwt.sign(
      { role: 'admin', username },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    return res.json({
      success: true,
      token,
      message: 'Login successful'
    });
  } else {
    return res.status(401).json({
      success: false,
      error: 'Invalid credentials'
    });
  }
});

module.exports = router;
