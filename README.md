# Starttech "Much To Do" Platform

This repository contains the application source code for the "Much To Do" platform. It is structured as a monorepo containing a modern React frontend and a high-performance Go backend.

## Project Architecture

The platform is built on the following technologies:
- **Frontend**: React (Vite), Tailwind CSS, TypeScript
- **Backend**: Go (Gin Framework)
- **Database**: MongoDB
- **Caching**: Redis
- **Infrastructure**: AWS (EC2, ASG, ALB, S3, ElastiCache), entirely managed via Terraform in the standalone `starttech-infra` repository.

## Repository Structure

```
.
├── .github/
│   └── workflows/                # CI/CD Pipelines for both Frontend and Backend
├── backend/
│   └── MuchToDo/                 # Go backend source code (Gin)
├── frontend/                     # React/Vite frontend source code
└── scripts/                      # Deployment, rollback, and health-check bash scripts
```

## Running Locally

### 1. Start the Backend
The backend requires a MongoDB and Redis instance. You can run these via Docker locally, or point to a remote instance.

```bash
cd backend/MuchToDo
cp .env.example .env
# Edit .env with your local Mongo/Redis URIs
go mod download
go run cmd/server/main.go
```
The backend will start on `http://localhost:8080`.

### 2. Start the Frontend
The frontend requires Node.js (v18 or higher).

```bash
cd frontend
npm install
# Note: You can also set this inside a .env file in the frontend directory
export VITE_API_BASE_URL="http://localhost:8080"
npm run dev
```
The frontend will start on `http://localhost:5173`.

## CI/CD Pipelines

This repository implements two isolated GitHub Action pipelines for continuous deployment to AWS:

### Backend Pipeline (`backend-ci-cd.yaml`)
Triggers automatically on pushes modifying `backend/MuchToDo/**`.
1. **Test & Audit:** Runs Go tests, formatting, and deep vulnerability scans (`govulncheck`).
2. **Build:** Compiles a highly-optimized Docker Image.
3. **Push:** Authenticates securely via AWS OIDC and pushes the image to Amazon ECR.
4. **Deploy:** Triggers a zero-downtime **AWS Auto Scaling Group Instance Refresh**.
5. **Verify:** Runs a live smoke test against the Application Load Balancer health endpoint to guarantee a successful rollout.

### Frontend Pipeline (`frontend-ci-cd.yaml`)
Triggers automatically on pushes modifying `frontend/**`.
1. **Audit:** Installs Node.js dependencies and runs a security `npm audit`.
2. **Build:** Compiles the Vite production bundle (dynamically injecting the public AWS ALB URL).
3. **Deploy:** Authenticates via AWS OIDC and safely syncs the compiled `dist/` directory into the AWS S3 static hosting bucket.

## Operations & Deployment Scripts

If you need to bypass GitHub Actions or fix a broken state, the `scripts/` directory contains tools to manage AWS deployments manually from your local terminal:

- `./scripts/deploy-backend.sh`: Manually builds the Go Docker image, pushes it to ECR, and triggers an ASG refresh.
- `./scripts/deploy-frontend.sh`: Manually executes the Vite build and syncs directly to the S3 bucket.
- `./scripts/health-check.sh`: Continuously pings the ALB `/health` endpoint to verify the backend is online.
- `./scripts/rollback.sh`: Very useful tool to cancel a stuck ASG rollout, or manually revert the AWS Launch Template to a previous healthy state.
