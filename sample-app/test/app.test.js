const request = require('supertest');
const server = require('../app');

describe('API Endpoints', () => {

    // Close the server after all tests to prevent Jest from hanging
    afterAll((done) => {
        server.close(() => {
            done();
        });
    });

    describe('GET /', () => {
        it('should return welcome message', async () => {
            const res = await request(server).get('/');
            expect(res.statusCode).toBe(200);
            expect(res.body).toHaveProperty('message');
            expect(res.body.message).toBe('Welcome to AWS CI/CD Pipeline Demo');
        });

        it('should return version information', async () => {
            const res = await request(server).get('/');
            expect(res.body).toHaveProperty('version');
            expect(res.body.version).toBe('1.0.0');
        });
    });

    describe('GET /health', () => {
        it('should return healthy status', async () => {
            const res = await request(server).get('/health');
            expect(res.statusCode).toBe(200);
            expect(res.body.status).toBe('healthy');
        });

        it('should return timestamp and uptime', async () => {
            const res = await request(server).get('/health');
            expect(res.body).toHaveProperty('timestamp');
            expect(res.body).toHaveProperty('uptime');
            expect(typeof res.body.uptime).toBe('number');
        });
    });

    describe('GET /api/info', () => {
        it('should return application information', async () => {
            const res = await request(server).get('/api/info');
            expect(res.statusCode).toBe(200);
            expect(res.body).toHaveProperty('application');
            expect(res.body).toHaveProperty('services');
        });

        it('should list AWS services used', async () => {
            const res = await request(server).get('/api/info');
            expect(res.body.services).toContain('CodePipeline');
            expect(res.body.services).toContain('CodeBuild');
            expect(res.body.services).toContain('CodeDeploy');
        });
    });

    describe('GET /nonexistent', () => {
        it('should return 404 for unknown routes', async () => {
            const res = await request(server).get('/nonexistent');
            expect(res.statusCode).toBe(404);
        });
    });
});
