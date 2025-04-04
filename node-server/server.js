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
    console.log(req.query.id);
    const { id, email, name, page = 1, pageSize = 50 } = req.query;
    
    console.log("ID" + id);
    // Validate pagination parameters
    const parsedPage = Math.max(1, parseInt(page));
    let parsedPageSize = parseInt(pageSize);
    parsedPageSize = Math.max(0, Math.min(parsedPageSize, 999));
    if (isNaN(parsedPageSize)) parsedPageSize = 50;
       
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

    if (name) {
      conditions.push('name LIKE ?');
      params.push(`%${name}%`);
    }
    
    whereClause = "";
    console.log("CONDITION_LENGHT: " + conditions.length);
    if (conditions.length) {
      whereClause = ' WHERE ' + conditions.join(' AND ');
      query += whereClause;
    }

    const offset = (parsedPage - 1) * parsedPageSize;
    // Add pagination
    query += ' LIMIT ? OFFSET ?';
    params.push(parsedPageSize, offset);
    
    // Get total count for pagination info
    let countQuery = 'SELECT COUNT(*) as total FROM users' + whereClause;

    console.log("COUNT_QUERY: " + countQuery)
    console.log("COUNT_PARAMS: " + params.slice(0, -2));
    const [[{ total }]] = await pool.query(countQuery, params.slice(0, -2));
    
    console.log("TOTAL: " + total);

 
    
    console.log("QUERY: " + query);
    console.log("PARAMS: " + params)

    // Execute query
    const [rows] = await pool.query(query, params);

    console.log("CURRENT_PAGE_SIZE: " + rows.length);
    

    
    res.json({
      data: rows,
      pagination: {
        page: parsedPage,
        pageSize: rows.length,
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
