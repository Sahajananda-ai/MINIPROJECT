from sqlalchemy.orm import Session
from datetime import datetime, timezone
from .. import models

def calculate_decay_price(deal: models.Deal) -> float:
    """
    Calculates the current price based on the dynamic decay formula.
    current_price = max(min_price, start_price - (elapsed/total) * (start_price - min_price))
    """
    now = datetime.now(timezone.utc)
    
    # If the deal is already expired
    if now >= deal.closing_time:
        return deal.min_price

    total_time = (deal.closing_time - deal.created_at).total_seconds()
    elapsed_time = (now - deal.created_at).total_seconds()
    
    # Calculate percentage of time elapsed
    time_ratio = elapsed_time / total_time
    
    # Calculate the price drop
    max_price_drop = deal.start_price - deal.min_price
    current_drop = time_ratio * max_price_drop
    
    current_price = deal.start_price - current_drop
    
    # Ensure we never drop below minimum price
    return max(deal.min_price, round(current_price, 2))

def run_pricing_update_job(db: Session):
    """
    This function should be triggered by Celery or FastAPI BackgroundTasks every 15 mins.
    It recalculates and updates the price for all active deals.
    """
    active_deals = db.query(models.Deal).filter(models.Deal.is_active == True).all()
    
    for deal in active_deals:
        new_price = calculate_decay_price(deal)
        
        # In a highly scalable system, we would push these new prices to Redis
        # so the mobile app can fetch the live prices instantly without hitting PostgreSQL
        print(f"Deal {deal.id} price decayed to ₹{new_price}")
        
    # Example of saving back to DB if needed:
    # db.commit()
