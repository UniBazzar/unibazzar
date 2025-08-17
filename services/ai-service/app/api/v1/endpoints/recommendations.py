from fastapi import APIRouter, Depends, HTTPException, Query, Request
from typing import List
import logging

from app.schemas.recommendations import (
    RecommendationResult,
    UserInteractionCreate,
    RecommendationRequest,
    RecommendationResponse
)
from app.services.recommend_service import RecommendService
from app.core.database import get_database

logger = logging.getLogger(__name__)
router = APIRouter()

@router.get("/", response_model=RecommendationResponse)
async def get_personalized_recommendations(
    user_id: int = Query(..., description="User ID for personalized recommendations"),
    limit: int = Query(10, le=50, description="Number of recommendations to return"),
    exclude_own: bool = Query(True, description="Exclude user's own listings"),
    campus_only: bool = Query(False, description="Limit to user's campus only"),
    request: Request = None,
) -> RecommendationResponse:
    """
    Get personalized recommendations for a user.
    
    Uses collaborative filtering (SVD) combined with content-based filtering
    to provide personalized listing recommendations.
    """
    try:
        # Get model manager from app state
        model_manager = request.app.state.model_manager
        recommend_service = RecommendService(model_manager, get_database())
        
        # Get user's recommendation preferences
        user_profile = await recommend_service.get_user_profile(user_id)
        
        # Generate recommendations using hybrid approach
        recommendations = await recommend_service.get_hybrid_recommendations(
            user_id=user_id,
            limit=limit,
            exclude_own=exclude_own,
            campus_only=campus_only
        )
        
        # Convert to response format
        recommendation_results = [
            RecommendationResult(
                listing_id=rec["listing_id"],
                title=rec["title"],
                description=rec["description"],
                price=rec["price"],
                campus_id=rec["campus_id"],
                confidence_score=rec["confidence_score"],
                recommendation_reason=rec["reason"],
                similarity_type=rec["similarity_type"],
                created_at=rec["created_at"]
            )
            for rec in recommendations
        ]
        
        return RecommendationResponse(
            user_id=user_id,
            recommendations=recommendation_results,
            total_count=len(recommendation_results),
            algorithm_version="hybrid_v1.0",
            generated_at=datetime.utcnow()
        )
        
    except Exception as e:
        logger.error(f"Recommendation generation failed for user {user_id}: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate recommendations: {str(e)}"
        )

@router.post("/interactions/")
async def log_user_interaction(
    interaction: UserInteractionCreate,
    request: Request = None,
) -> dict:
    """
    Log user behavior for recommendation training (Internal API).
    
    This endpoint captures user interactions with listings to improve
    the recommendation algorithm over time.
    """
    try:
        # Get model manager from app state
        model_manager = request.app.state.model_manager
        recommend_service = RecommendService(model_manager, get_database())
        
        # Store the interaction
        interaction_id = await recommend_service.log_interaction(
            user_id=interaction.user_id,
            listing_id=interaction.listing_id,
            interaction_type=interaction.interaction_type,
            interaction_value=interaction.interaction_value,
            context_data=interaction.context_data
        )
        
        # Update user profile incrementally if needed
        await recommend_service.update_user_profile_incremental(
            user_id=interaction.user_id,
            interaction=interaction
        )
        
        logger.info(f"Logged interaction {interaction_id} for user {interaction.user_id}")
        
        return {
            "success": True,
            "interaction_id": interaction_id,
            "message": "Interaction logged successfully"
        }
        
    except Exception as e:
        logger.error(f"Failed to log interaction for user {interaction.user_id}: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to log interaction: {str(e)}"
        )

@router.post("/train/")
async def trigger_recommendation_training(
    request: Request = None,
) -> dict:
    """
    Trigger SVD model retraining (Admin/Internal API).
    
    This endpoint allows triggering the collaborative filtering model
    retraining process. Typically scheduled nightly or weekly.
    """
    try:
        # Get model manager from app state
        model_manager = request.app.state.model_manager
        recommend_service = RecommendService(model_manager, get_database())
        
        # Start training job
        training_job_id = await recommend_service.trigger_model_training()
        
        logger.info(f"Started recommendation model training job: {training_job_id}")
        
        return {
            "success": True,
            "job_id": training_job_id,
            "message": "Recommendation model training started",
            "estimated_duration": "30-60 minutes"
        }
        
    except Exception as e:
        logger.error(f"Failed to start recommendation training: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to start training: {str(e)}"
        )

@router.get("/similar/{listing_id}")
async def get_similar_listings(
    listing_id: int,
    limit: int = Query(10, le=20, description="Number of similar listings"),
    request: Request = None,
) -> List[RecommendationResult]:
    """
    Get similar listings based on content similarity.
    
    Uses content-based filtering to find listings similar to the given listing.
    """
    try:
        model_manager = request.app.state.model_manager
        recommend_service = RecommendService(model_manager, get_database())
        
        similar_listings = await recommend_service.get_content_similar_listings(
            listing_id=listing_id,
            limit=limit
        )
        
        return [
            RecommendationResult(
                listing_id=listing["listing_id"],
                title=listing["title"],
                description=listing["description"],
                price=listing["price"],
                campus_id=listing["campus_id"],
                confidence_score=listing["similarity_score"],
                recommendation_reason=f"Similar to listing #{listing_id}",
                similarity_type="content_based",
                created_at=listing["created_at"]
            )
            for listing in similar_listings
        ]
        
    except Exception as e:
        logger.error(f"Failed to get similar listings for {listing_id}: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get similar listings: {str(e)}"
        )
