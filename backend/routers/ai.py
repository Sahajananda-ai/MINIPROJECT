from fastapi import APIRouter, Depends
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from sqlalchemy.orm import Session
from datetime import datetime, timezone
from ..database import get_db
from .. import models
from ..services import decay_pricing, ai_vision_curator

router = APIRouter(
    prefix="/ai",
    tags=["AI Surplus Assistant"]
)

class GenerateBoxDescriptionRequest(BaseModel):
    items_detected: Optional[List[str]] = None
    items_text: Optional[str] = None
    category: Optional[str] = "Bakery"
    image_url: Optional[str] = None
    image_base64: Optional[str] = None

class GenerateBoxDescriptionResponse(BaseModel):
    success: bool
    mystery_title: str
    mystery_description: str
    dietary_tag: str
    freshness_guarantee: str
    suggested_original_value: float
    suggested_start_price: float
    suggested_min_price: float
    detected_items_internal: List[str]
    cover_image_url: str


class AiRecommendRequest(BaseModel):
    query: Optional[str] = "best value"
    max_budget: Optional[float] = None
    preferred_category: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class AiRecommendResponse(BaseModel):
    success: bool
    ai_insight: str
    recommended_deal: Optional[Dict[str, Any]] = None
    alternative_deals: List[Dict[str, Any]] = []
    projected_savings: float = 0.0
    carbon_offset_kg: float = 0.0

@router.post("/recommend", response_model=AiRecommendResponse)
def get_ai_deal_recommendation(request: AiRecommendRequest, db: Session = Depends(get_db)):
    now = datetime.now(timezone.utc)
    
    # 1. Fetch all active deals
    active_deals = db.query(models.Deal).filter(
        models.Deal.is_active == True,
        models.Deal.closing_time > now,
        models.Deal.quantity > 0
    ).all()
    
    if not active_deals:
        return AiRecommendResponse(
            success=False,
            ai_insight="🤖 No active mystery boxes are currently available in your area. Check back closer to store closing hours when fresh surplus is listed!",
            recommended_deal=None,
            alternative_deals=[],
            projected_savings=0.0,
            carbon_offset_kg=0.0
        )
    
    # 2. Enrich deals with live decay prices and metadata
    scored_deals = []
    query_lower = (request.query or "").lower()
    cat_filter = (request.preferred_category or "").lower()

    for deal in active_deals:
        vendor = deal.vendor
        current_price = decay_pricing.calculate_decay_price(deal)
        discount_pct = round(((deal.original_value - current_price) / deal.original_value) * 100) if deal.original_value > 0 else 0
        savings = round(deal.original_value - current_price, 2)
        
        # Calculate closing urgency (hours remaining)
        closing_time = deal.closing_time
        if closing_time.tzinfo is None:
            closing_time = closing_time.replace(tzinfo=timezone.utc)
        hours_left = max(0.1, (closing_time - now).total_seconds() / 3600.0)
        
        # Base scoring algorithm:
        # High discount (+), Under budget (+), Matches search query (+), Closing sooner (+)
        score = discount_pct * 1.5
        
        if request.max_budget and current_price <= request.max_budget:
            score += 40
        elif request.max_budget and current_price > request.max_budget:
            score -= 50
            
        if cat_filter and cat_filter in (vendor.shop_category or "").lower():
            score += 30
            
        if query_lower:
            if any(term in vendor.name.lower() or term in (vendor.shop_category or "").lower() for term in query_lower.split()):
                score += 35
                
        # Urgency bonus (closing within 2 hours)
        if hours_left < 2.0:
            score += 20
            
        deal_dict = {
            "id": deal.id,
            "vendor_name": vendor.name,
            "shop_category": vendor.shop_category,
            "original_value": deal.original_value,
            "current_price": current_price,
            "savings": savings,
            "discount_percentage": discount_pct,
            "quantity_remaining": deal.quantity,
            "hours_left": round(hours_left, 1),
            "vendor_rating": vendor.rating,
        }
        scored_deals.append((score, deal_dict))
        
    # Sort by score descending
    scored_deals.sort(key=lambda x: x[0], reverse=True)
    
    top_deal = scored_deals[0][1]
    alternatives = [d[1] for d in scored_deals[1:4]]
    
    # Generate humanized AI explanation
    savings = top_deal["savings"]
    co2 = round(savings * 0.015 + 1.2, 1) # Estimated food carbon footprint avoided
    
    insight = (
        f"🌟 Top Pick: {top_deal['vendor_name']} ({top_deal['shop_category']})!\n"
        f"• Value Deal: Priced at ₹{top_deal['current_price']} (originally ₹{top_deal['original_value']}, {top_deal['discount_percentage']}% OFF).\n"
        f"• You save ₹{savings} and prevent ~{co2} kg of food waste CO₂ emissions!\n"
        f"• Closing in {top_deal['hours_left']} hours. Grab it before inventory runs out!"
    )
    
    return AiRecommendResponse(
        success=True,
        ai_insight=insight,
        recommended_deal=top_deal,
        alternative_deals=alternatives,
        projected_savings=savings,
        carbon_offset_kg=co2
    )

@router.post("/generate-box-description", response_model=GenerateBoxDescriptionResponse)
def generate_mystery_box_description(request: GenerateBoxDescriptionRequest):
    """
    Curates a customer-facing Mystery Box description from vendor surplus items/photos.
    Enforces the privacy & surprise rule: specific items are kept hidden from the customer.
    """
    result = ai_vision_curator.generate_curated_mystery_box(
        items_detected=request.items_detected,
        items_text=request.items_text,
        category=request.category,
        image_url=request.image_url,
        image_base64=request.image_base64
    )
    return GenerateBoxDescriptionResponse(**result)
