from fastapi import APIRouter, HTTPException, Request
from typing import Dict, Any
import logging

from app.schemas.moderation import (
    ModerationRequest,
    ModerationResult,
    ModerationResponse
)
from app.services.moderation_service import ModerationService
from app.core.database import get_database

logger = logging.getLogger(__name__)
router = APIRouter()

@router.post("/listing", response_model=ModerationResponse)
async def moderate_listing(
    moderation_request: ModerationRequest,
    request: Request = None,
) -> ModerationResponse:
    """
    Analyze a listing's text for inappropriate content.
    
    Performs content moderation using ML models to detect:
    - Hate speech and offensive language
    - Inappropriate content for academic marketplace
    - Spam and fraudulent listings
    - Policy violations
    """
    try:
        # Get model manager from app state
        model_manager = request.app.state.model_manager
        moderation_service = ModerationService(model_manager, get_database())
        
        # Perform moderation analysis
        moderation_result = await moderation_service.moderate_content(
            content_id=moderation_request.listing_id,
            content_type="listing",
            text=moderation_request.text,
            additional_context={
                "title": moderation_request.additional_context.get("title", ""),
                "category": moderation_request.additional_context.get("category", ""),
                "price": moderation_request.additional_context.get("price", 0)
            }
        )
        
        # Log moderation action
        await moderation_service.log_moderation_action(
            content_id=moderation_request.listing_id,
            content_type="listing",
            moderation_result=moderation_result
        )
        
        return ModerationResponse(
            content_id=moderation_request.listing_id,
            content_type="listing",
            is_flagged=moderation_result.is_flagged,
            confidence_score=moderation_result.confidence_score,
            flagged_categories=moderation_result.flagged_categories,
            severity_level=moderation_result.severity_level,
            recommended_action=moderation_result.recommended_action,
            explanation=moderation_result.explanation,
            model_version=moderation_result.model_version
        )
        
    except Exception as e:
        logger.error(f"Moderation failed for listing {moderation_request.listing_id}: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Content moderation failed: {str(e)}"
        )

@router.post("/review", response_model=ModerationResponse)
async def moderate_review(
    moderation_request: ModerationRequest,
    request: Request = None,
) -> ModerationResponse:
    """
    Analyze a user review for inappropriate content.
    
    Similar to listing moderation but with different thresholds
    and rules specific to user-generated reviews and ratings.
    """
    try:
        # Get model manager from app state
        model_manager = request.app.state.model_manager
        moderation_service = ModerationService(model_manager, get_database())
        
        # Perform moderation analysis with review-specific rules
        moderation_result = await moderation_service.moderate_content(
            content_id=moderation_request.review_id or moderation_request.listing_id,
            content_type="review",
            text=moderation_request.text,
            additional_context={
                "rating": moderation_request.additional_context.get("rating", 0),
                "reviewer_history": moderation_request.additional_context.get("reviewer_history", {}),
                "listing_id": moderation_request.additional_context.get("listing_id", "")
            }
        )
        
        # Log moderation action
        await moderation_service.log_moderation_action(
            content_id=moderation_request.review_id or moderation_request.listing_id,
            content_type="review",
            moderation_result=moderation_result
        )
        
        return ModerationResponse(
            content_id=moderation_request.review_id or moderation_request.listing_id,
            content_type="review",
            is_flagged=moderation_result.is_flagged,
            confidence_score=moderation_result.confidence_score,
            flagged_categories=moderation_result.flagged_categories,
            severity_level=moderation_result.severity_level,
            recommended_action=moderation_result.recommended_action,
            explanation=moderation_result.explanation,
            model_version=moderation_result.model_version
        )
        
    except Exception as e:
        logger.error(f"Moderation failed for review {moderation_request.review_id}: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Review moderation failed: {str(e)}"
        )

@router.post("/batch")
async def moderate_batch_content(
    moderation_requests: list[ModerationRequest],
    request: Request = None,
) -> Dict[str, Any]:
    """
    Moderate multiple pieces of content in batch.
    
    Useful for processing multiple listings or reviews at once,
    with optimized batch processing for efficiency.
    """
    try:
        # Get model manager from app state
        model_manager = request.app.state.model_manager
        moderation_service = ModerationService(model_manager, get_database())
        
        # Process batch moderation
        batch_results = await moderation_service.moderate_batch(moderation_requests)
        
        # Count flagged items
        flagged_count = sum(1 for result in batch_results if result.is_flagged)
        
        return {
            "success": True,
            "total_processed": len(moderation_requests),
            "flagged_count": flagged_count,
            "results": [
                {
                    "content_id": result.content_id,
                    "is_flagged": result.is_flagged,
                    "confidence_score": result.confidence_score,
                    "flagged_categories": result.flagged_categories,
                    "recommended_action": result.recommended_action
                }
                for result in batch_results
            ]
        }
        
    except Exception as e:
        logger.error(f"Batch moderation failed: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Batch moderation failed: {str(e)}"
        )

@router.get("/stats")
async def get_moderation_stats(
    request: Request = None,
) -> Dict[str, Any]:
    """
    Get moderation statistics and metrics.
    
    Returns aggregated statistics about content moderation
    for monitoring and quality assurance purposes.
    """
    try:
        model_manager = request.app.state.model_manager
        moderation_service = ModerationService(model_manager, get_database())
        
        stats = await moderation_service.get_moderation_stats()
        
        return {
            "total_moderated": stats["total_moderated"],
            "flagged_percentage": stats["flagged_percentage"],
            "categories_breakdown": stats["categories_breakdown"],
            "model_performance": stats["model_performance"],
            "recent_trends": stats["recent_trends"],
            "last_updated": stats["last_updated"]
        }
        
    except Exception as e:
        logger.error(f"Failed to get moderation stats: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get moderation statistics: {str(e)}"
        )
