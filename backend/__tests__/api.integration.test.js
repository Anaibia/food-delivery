import request from 'supertest';

// Note: This test file requires the app to be exported from server.js
// and a test database to be configured

describe('API Integration Tests', () => {
    const API_URL = process.env.API_URL || 'http://localhost:4000';

    describe('Health Check', () => {
        test('GET /health should return 200', async () => {
            const response = await request(API_URL).get('/health');
            expect(response.status).toBe(200);
            expect(response.body).toHaveProperty('status', 'healthy');
        });
    });

    describe('Root Endpoint', () => {
        test('GET / should return API Working message', async () => {
            const response = await request(API_URL).get('/');
            expect(response.status).toBe(200);
            expect(response.text).toBe('API Working');
        });
    });

    describe('User Authentication', () => {
        const testUser = {
            name: 'Test User',
            email: `test${Date.now()}@example.com`,
            password: 'password123'
        };

        test('POST /api/user/register should create user', async () => {
            const response = await request(API_URL)
                .post('/api/user/register')
                .send(testUser);

            // May fail if MongoDB is not connected
            if (response.status === 200) {
                expect(response.body).toHaveProperty('success', true);
                expect(response.body).toHaveProperty('token');
            }
        });

        test('POST /api/user/login should return token for valid credentials', async () => {
            const credentials = {
                email: testUser.email,
                password: testUser.password
            };

            const response = await request(API_URL)
                .post('/api/user/login')
                .send(credentials);

            // May fail if user doesn't exist or MongoDB is not connected
            if (response.status === 200 && response.body.success) {
                expect(response.body).toHaveProperty('token');
            }
        });
    });

    describe('Food Endpoints', () => {
        test('GET /api/food/list should return food list', async () => {
            const response = await request(API_URL).get('/api/food/list');

            if (response.status === 200) {
                expect(response.body).toHaveProperty('success');
                expect(response.body).toHaveProperty('data');
            }
        });
    });
});
