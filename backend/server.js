import express from "express";
import cors from "cors";
import { connectDB } from "./config/db.js";
import foodRouter from "./routes/foodRoute.js";
import userRouter from "./routes/userRoute.js";
import "dotenv/config";
import cartRouter from "./routes/cartRoute.js";
import orderRouter from "./routes/orderRoute.js";
import client from "prom-client";

// app config
const app = express();
const port = process.env.PORT || 4000;

// Prometheus metrics setup
const register = new client.Registry();
client.collectDefaultMetrics({ register });

// Custom metrics
const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.5, 1, 2, 5]
});
register.registerMetric(httpRequestDuration);

const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});
register.registerMetric(httpRequestsTotal);

// middlewares
app.use(express.json());
app.use(cors());

// Metrics middleware
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const route = req.route ? req.route.path : req.path;
    httpRequestDuration.observe(
      { method: req.method, route: route, status_code: res.statusCode },
      duration
    );
    httpRequestsTotal.inc({ method: req.method, route: route, status_code: res.statusCode });
  });
  next();
});

// DB connection
// DB connection moved to start-up block
// connectDB();

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({
    status: "healthy",
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Prometheus metrics endpoint
app.get("/metrics", async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// api endpoints
app.use("/api/food", foodRouter);
app.use("/images", express.static("uploads"));
app.use("/api/user", userRouter);
app.use("/api/cart", cartRouter);
app.use("/api/order", orderRouter);

app.get("/", (req, res) => {
  res.send("API Working");
});

// Start server only if not in test mode
if (process.env.NODE_ENV !== 'test') {
  connectDB();
  app.listen(port, () => {
    console.log(`Server Started on port: ${port}`);
  });
}

// Export app for testing
export default app;
