# Sample Node.js Application for AWS CI/CD Pipeline

A simple Express.js application demonstrating deployment via AWS CodePipeline, CodeBuild, and CodeDeploy.

## Features

- RESTful API endpoints
- Health check endpoint for monitoring
- Comprehensive unit tests with Jest
- Graceful shutdown handling
- Production-ready configuration

## API Endpoints

### GET /
Returns welcome message and version information.

**Response**:
```json
{
  "message": "Welcome to AWS CI/CD Pipeline Demo",
  "version": "1.0.0",
  "environment": "production"
}
```

### GET /health
Health check endpoint for load balancers and monitoring.

**Response**:
```json
{
  "status": "healthy",
  "timestamp": "2024-02-10T00:00:00.000Z",
  "uptime": 123.456
}
```

### GET /api/info
Application information and AWS services used.

**Response**:
```json
{
  "application": "AWS CI/CD Demo App",
  "description": "Sample Node.js application deployed via AWS CodePipeline",
  "services": ["CodePipeline", "CodeBuild", "CodeDeploy"],
  "platform": "AWS EC2"
}
```

## Local Development

### Prerequisites
- Node.js 14.x or higher
- npm 6.x or higher

### Installation

```bash
npm install
```

### Running the Application

```bash
# Development mode with auto-reload
npm run dev

# Production mode
npm start
```

The application will start on port 3000 by default.

### Running Tests

```bash
# Run tests once
npm test

# Run tests in watch mode
npm run test:watch
```

## Environment Variables

- `PORT` - Server port (default: 3000)
- `NODE_ENV` - Environment (development/production)

## Project Structure

```
sample-app/
├── app.js              # Main application file
├── package.json        # Dependencies and scripts
└── test/
    └── app.test.js     # Unit tests
```

## Deployment

This application is designed to be deployed via AWS CodeDeploy. The deployment process is automated through the CI/CD pipeline.

### Deployment Scripts

Located in the parent `scripts/` directory:
- `install_dependencies.sh` - Installs Node.js and npm packages
- `start_server.sh` - Starts the application
- `stop_server.sh` - Stops the application gracefully
- `validate_service.sh` - Validates deployment success

## Testing

The application includes comprehensive unit tests covering:
- All API endpoints
- Response status codes
- Response data structure
- Error handling

Test coverage reports are generated during the build process.

## Production Considerations

- Application runs on port 3000
- Uses `nohup` for background execution
- Implements graceful shutdown on SIGTERM
- Logs to `/home/ec2-user/app/app.log` on EC2
- Process ID stored in `/home/ec2-user/app/app.pid`

## License

MIT
