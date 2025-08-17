from fastapi import APIRouter, Depends, HTTPException, Query, Request
from typing import List, Optional
import logging

from app.schemas.search import (
    ListingSearchResult,
    ListingEmbeddingCreate,
    SearchResponse
)
from app.services.embed_service import EmbedService
from app.core.database import get_database
from app.core.cache import get_cache

logger = logging.getLogger(__name__)
router = APIRouter()

@router.get("/", response_model=SearchResponse)
async def search_listings(
    q: str = Query(..., description="Search query"),
    campus_id: Optional[int] = Query(None, description="Campus ID filter"),
    limit: int = Query(20, le=100, description="Maximum number of results"),
    offset: int = Query(0, ge=0, description="Offset for pagination"),
    request: Request = None,
) -> SearchResponse:
    """
    Search for listings using semantic search with embeddings.
    
    This endpoint performs vector similarity search against listing embeddings
    to find the most relevant listings based on the query.
    """
    try:
        # Get model manager from app state
        model_manager = request.app.state.model_manager
        embed_service = EmbedService(model_manager, get_database(), get_cache())
        
        # Generate query embedding
        query_embedding = await embed_service.generate_embedding(q)
        
        # Perform vector search
        results = await embed_service.search_similar_listings(
            query_embedding=query_embedding,
            campus_id=campus_id,
            limit=limit,
            offset=offset
        )
        
        # Convert results to response format
        search_results = [
            ListingSearchResult(
                listing_id=result["listing_id"],
                title=result["title"],
                description=result["description"],
                price=result["price"],
                campus_id=result["campus_id"],
                relevance_score=result["similarity_score"],
                created_at=result["created_at"]
            )
            for result in results
        ]
        
        return SearchResponse(
            query=q,
            results=search_results,
            total_count=len(search_results),
            limit=limit,
            offset=offset
        )
        
    except Exception as e:
        logger.error(f"Search failed for query '{q}': {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Search failed: {str(e)}"
        )

@router.post("/embeddings")
async def create_listing_embedding(
    embedding_data: ListingEmbeddingCreate,
    request: Request = None,
) -> dict:
    """
    Generate and store embeddings for a listing (Internal API).
    
    This endpoint is called by the listing-service when a new listing
    is created or updated to populate the vector database.
    """
    try:
        # Get model manager from app state
        model_manager = request.app.state.model_manager
        embed_service = EmbedService(model_manager, get_database(), get_cache())
        
        # Generate embedding for the listing text
        embedding = await embed_service.generate_embedding(embedding_data.text)
        
        # Store embedding in vector database
        await embed_service.store_listing_embedding(
            listing_id=embedding_data.listing_id,
            embedding=embedding,
            metadata={
                "title": embedding_data.title,
                "description": embedding_data.description,
                "campus_id": embedding_data.campus_id,
                "price": embedding_data.price,
                "created_at": embedding_data.created_at.isoformat()
            }
        )
        
        logger.info(f"Created embedding for listing {embedding_data.listing_id}")
        
        return {
            "success": True,
            "listing_id": embedding_data.listing_id,
            "embedding_dimension": len(embedding),
            "message": "Embedding created successfully"
        }
        
    except Exception as e:
        logger.error(f"Failed to create embedding for listing {embedding_data.listing_id}: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create embedding: {str(e)}"
        )

@router.post("/train")
async def trigger_embedding_training(
    request: Request = None,
) -> dict:
    """
    Trigger embedding model training/update process (Admin/Internal API).
    
    This endpoint allows the backend to re-embed all listings after 
    a major update to the model or when the database grows significantly.
    """
    try:
        # Get model manager from app state
        model_manager = request.app.state.model_manager
        embed_service = EmbedService(model_manager, get_database(), get_cache())
        
        # Trigger background training process
        training_job_id = await embed_service.trigger_model_training()
        
        logger.info(f"Started embedding model training job: {training_job_id}")
        
        return {
            "success": True,
            "job_id": training_job_id,
            "message": "Embedding training started",
            "status": "training"
        }
        
    except Exception as e:
        logger.error(f"Failed to start embedding training: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to start training: {str(e)}"
        )

@router.get("/train/status/{job_id}")
async def get_training_status(
    job_id: str,
    request: Request = None,
) -> dict:
    """
    Get the status of a training job.
    """
    try:
        model_manager = request.app.state.model_manager
        embed_service = EmbedService(model_manager, get_database(), get_cache())
        
        status = await embed_service.get_training_status(job_id)
        
        return {
            "job_id": job_id,
            "status": status["status"],
            "progress": status.get("progress", 0),
            "message": status.get("message", ""),
            "started_at": status.get("started_at"),
            "completed_at": status.get("completed_at")
        }
        
    except Exception as e:
        logger.error(f"Failed to get training status for job {job_id}: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get training status: {str(e)}"
        )
