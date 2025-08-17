from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging

from app.core.config import get_settings
from app.core.database import get_database
from app.api.v1.api import api_router
from app.models.ml_models import ModelManager

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Initialize model manager as global variable
model_manager = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifespan events"""
    global model_manager
    
    # Startup
    logger.info("Starting AI Service...")
    settings = get_settings()
    
    # Initialize ML models
    model_manager = ModelManager(settings)
    await model_manager.load_models()
    
    # Set model manager in app state
    app.state.model_manager = model_manager
    
    logger.info("AI Service started successfully")
    
    yield
    
    # Shutdown
    logger.info("Shutting down AI Service...")
    if model_manager:
        await model_manager.cleanup()
    logger.info("AI Service shutdown complete")

def create_app() -> FastAPI:
    """Create and configure the FastAPI application"""
    settings = get_settings()
    
    app = FastAPI(
        title="UniBazzar AI Service",
        description="AI/ML microservice for search, recommendations, and content moderation",
        version="1.0.0",
        lifespan=lifespan,
        docs_url="/docs" if settings.ENVIRONMENT != "production" else None,
        redoc_url="/redoc" if settings.ENVIRONMENT != "production" else None,
    )
    
    # Add CORS middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.ALLOWED_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    # Include API routes
    app.include_router(api_router, prefix="/api/v1")
    
    # Health check endpoints
    @app.get("/healthz")
    async def health_check():
        """Liveness probe"""
        return {"status": "healthy", "service": "ai-service"}
    
    @app.get("/readyz")
    async def readiness_check():
        """Readiness probe"""
        try:
            # Check database connection
            db = get_database()
            await db.ping()
            
            # Check if models are loaded
            if not hasattr(app.state, 'model_manager') or not app.state.model_manager.models_loaded:
                raise HTTPException(status_code=503, detail="Models not ready")
            
            return {"status": "ready", "service": "ai-service"}
        except Exception as e:
            logger.error(f"Readiness check failed: {e}")
            raise HTTPException(status_code=503, detail="Service not ready")
    
    @app.get("/metrics")
    async def metrics():
        """Prometheus metrics endpoint"""
        # This would typically use prometheus_client
        return {"metrics": "placeholder"}
    
    return app

# Create the app instance
app = create_app()
