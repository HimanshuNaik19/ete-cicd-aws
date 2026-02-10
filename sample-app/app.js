const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to AWS CI/CD Pipeline Demo',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development'
  });
});

// API endpoint
app.get('/api/info', (req, res) => {
  res.json({
    application: 'AWS CI/CD Demo App',
    description: 'Sample Node.js application deployed via AWS CodePipeline',
    services: ['CodePipeline', 'CodeBuild', 'CodeDeploy'],
    platform: 'AWS EC2'
  });
});

// Start server
const server = app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
  });
});

module.exports = app;
