require('dotenv').config();
const express = require('express');
const mysql = require('mysql2/promise');
const app = express();
const port = process.env.PORT || 3000;

// Database configuration
const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'test',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
};

// Create MySQL connection pool
const pool = mysql.createPool(dbConfig);

// Middleware to parse JSON requests
app.use(express.json());

// Health endpoint
app.get('/health', async (req, res) => {
  try {
    const connection = await pool.getConnection();
    connection.release();
    res.json({ 
      status: 'healthy',
      database: 'connected'
    });
  } catch (error) {
    res.status(500).json({ 
      status: 'unhealthy',
      database: 'disconnected',
      error: error.message
    });
  }
});

// Users endpoint with filtering and pagination
app.get('/users', async (req, res) => {
  try {
    const { id, email, page = 1, pageSize = 50 } = req.query;
    
    // Validate pagination parameters
    const parsedPage = Math.max(1, parseInt(page));
    let parsedPageSize = parseInt(pageSize);
    parsedPageSize = Math.max(0, Math.min(parsedPageSize, 999));
    if (isNaN(parsedPageSize)) parsedPageSize = 50;
    
    const offset = (parsedPage - 1) * parsedPageSize;
    
    // Build the query based on filters
    let query = 'SELECT * FROM users';
    const conditions = [];
    const params = [];
    
    if (id) {
      conditions.push('id = ?');
      params.push(id);
    }
    
    if (email) {
      conditions.push('email LIKE ?');
      params.push(`%${email}%`);
    }
    
    if (conditions.length) {
      query += ' WHERE ' + conditions.join(' AND ');
    }
    
    // Add pagination
    query += ' LIMIT ? OFFSET ?';
    params.push(parsedPageSize, offset);
    
    // Execute query
    const [rows] = await pool.query(query, params);
    
    // Get total count for pagination info
    let countQuery = 'SELECT COUNT(*) as total FROM users';
    if (conditions.length) {
      countQuery += ' WHERE ' + conditions.join(' AND ');
    }
    const [[{ total }]] = await pool.query(countQuery, params.slice(0, -2));
    
    res.json({
      data: rows,
      pagination: {
        page: parsedPage,
        pageSize: parsedPageSize,
        totalItems: total,
        totalPages: Math.ceil(total / parsedPageSize)
      }
    });
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Start the server
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  await pool.end();
  process.exit(0);
});

process.on('SIGINT', async () => {
  await pool.end();
  process.exit(0);
});
