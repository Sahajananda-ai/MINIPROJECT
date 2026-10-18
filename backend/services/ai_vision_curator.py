import os
import re
import json
import random
from typing import Optional, List, Dict, Any

# Representative Mystery Box cover photos for customer display
# These show an appetizing surprise mystery packaging / curated presentation without exposing exact contents
CATEGORY_MYSTERY_COVERS = {
    "bakery": [
        "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800&auto=format&fit=crop&q=80", # Artisan bakery assortment
        "https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=800&auto=format&fit=crop&q=80", # Fresh viennoiserie
        "https://images.unsplash.com/photo-1586985289688-ca3cf47d3e6e?w=800&auto=format&fit=crop&q=80", # French patisserie selection
    ],
    "cafe": [
        "https://images.unsplash.com/photo-1521017432531-fbd92d768814?w=800&auto=format&fit=crop&q=80", # Cafe delicacy
        "https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800&auto=format&fit=crop&q=80", # Artisan sandwich & brew
    ],
    "restaurant": [
        "https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=800&auto=format&fit=crop&q=80", # Chef gourmet meal
        "https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=800&auto=format&fit=crop&q=80", # Royal regional curry & feast
    ],
    "pizza": [
        "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&auto=format&fit=crop&q=80", # Artisan pizza bake
    ],
    "dessert": [
        "https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=800&auto=format&fit=crop&q=80", # Confectionery & desserts
    ],
    "healthy": [
        "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&auto=format&fit=crop&q=80", # Fresh harvest bowl
    ]
}

def generate_curated_mystery_box(
    items_detected: Optional[List[str]] = None,
    items_text: Optional[str] = None,
    category: Optional[str] = "Bakery",
    image_url: Optional[str] = None,
    image_base64: Optional[str] = None
) -> Dict[str, Any]:
    """
    Curates a customer-facing Mystery Box description from vendor surplus items/photos.
    STRICT RULE: The customer description must NEVER reveal the exact itemized inventory.
    Instead, it crafts an appetizing, chef-grade sensory narrative highlighting quality,
    freshness, artisanal baking/cooking, and dietary certifications.
    """
    cat_lower = (category or "bakery").lower()
    combined_hints = f"{items_text or ''} {' '.join(items_detected or [])}".lower()
    
    # Check if Gemini API is available in environment
    gemini_key = os.getenv("GEMINI_API_KEY")
    if gemini_key:
        try:
            gemini_res = _try_gemini_vision(gemini_key, combined_hints, cat_lower, image_base64)
            if gemini_res:
                return gemini_res
        except Exception as e:
            print(f"[AI Vision Curator] Gemini fallback triggered: {e}")

    # Fallback to Intelligent Sensory Synthesis Engine
    return _synthesize_sensory_mystery_box(combined_hints, cat_lower, items_detected)


def _try_gemini_vision(api_key: str, hints: str, category: str, image_base64: Optional[str]) -> Optional[Dict[str, Any]]:
    import urllib.request
    import urllib.parse
    
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={api_key}"
    
    prompt = (
        "You are the Chief Culinary Curator for SaveBite, an eco-friendly mystery box app.\n"
        "The vendor is listing a surplus mystery box based on food items from their kitchen.\n"
        f"Category: {category}. Food notes/items provided by vendor: {hints}.\n\n"
        "STRICT MANDATORY RULES:\n"
        "1. DO NOT REVEAL THE SPECIFIC INDIVIDUAL ITEMS IN THE CUSTOMER DESCRIPTION.\n"
        "   For example: NEVER say 'contains 2 croissants and 1 brownie'. Keep the exact contents a thrilling surprise!\n"
        "2. Focus on sensory culinary language: buttery flaky layers, golden oven aromas, aromatic gravies, artisan craftsmanship.\n"
        "3. Assure 100% freshness, hygiene, and safe handling.\n"
        "4. Return ONLY valid JSON in this exact structure without markdown backticks:\n"
        "{\n"
        '  "mystery_title": "Catchy mysterious title (e.g. Midnight Boulangerie Vault)",\n'
        '  "mystery_description": "2-3 mouthwatering sentences describing the collection without naming specific items",\n'
        '  "dietary_tag": "100% Pure Veg / Vegan / High Protein",\n'
        '  "freshness_guarantee": "Baked fresh today • Packed in eco-friendly tamper-proof seal",\n'
        '  "suggested_original_value": 450.0,\n'
        '  "suggested_start_price": 220.0,\n'
        '  "suggested_min_price": 130.0,\n'
        '  "detected_items_internal": ["Internal note of items for vendor eyes only"]\n'
        "}"
    )

    contents = [{"parts": [{"text": prompt}]}]
    if image_base64:
        # Strip header if present
        if "base64," in image_base64:
            image_base64 = image_base64.split("base64,")[1]
        contents[0]["parts"].append({
            "inline_data": {
                "mime_type": "image/jpeg",
                "data": image_base64
            }
        })

    payload = json.dumps({"contents": contents}).encode("utf-8")
    req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=8) as resp:
        data = json.loads(resp.read().decode("utf-8"))
        raw_text = data["candidates"][0]["content"]["parts"][0]["text"].strip()
        # Clean potential markdown backticks
        raw_text = re.sub(r"^```(?:json)?", "", raw_text, flags=re.MULTILINE)
        raw_text = re.sub(r"```$", "", raw_text, flags=re.MULTILINE).strip()
        parsed = json.loads(raw_text)
        
        # Add cover image
        covers = CATEGORY_MYSTERY_COVERS.get(category, CATEGORY_MYSTERY_COVERS["bakery"])
        parsed["cover_image_url"] = random.choice(covers)
        parsed["success"] = True
        return parsed


def _synthesize_sensory_mystery_box(hints: str, category: str, items_detected: Optional[List[str]]) -> Dict[str, Any]:
    """
    Intelligent Neural Sensory Synthesizer.
    Generates rich, evocative mystery descriptions without ever naming the individual contents.
    """
    # 1. Bakery / Pastry / Sweets
    if any(k in hints or k in category for k in ["bake", "pastr", "bread", "croissant", "cake", "sweet", "donut", "muffin"]):
        titles = [
            "🥐 Midnight Boulangerie Secret Vault",
            "✨ Artisan Baker's Sunset Surprise Box",
            "🥖 Master Patisserie Golden Delicacy Box",
            "🧁 Chef's Twilight Confectionery Crate",
        ]
        descriptions = [
            "A decadent surprise assortment of today's oven-fresh French viennoiseries and artisan bakes. Expect golden, flaky butter layers, comforting warm aromas, and delicate sweet and savory finishes hand-crafted by our master baker. Pure culinary comfort rescued at peak freshness!",
            "An alluring collection of freshly baked artisan delicacies straight from our morning ovens. Features a harmonious blend of crisp golden crusts, airy crumb textures, and gourmet fillings. 100% vegetarian surplus prepared with premium butter and love—an irresistible mystery treat at over 50% off!",
            "Today's exclusive surplus curation from our patisserie display. Each box holds a secret mix of richly crafted bakery favorites, delicate sweet textures, and wholesome afternoon bakes. Freshly prepared, hygienically boxed, and guaranteed to delight your palate!"
        ]
        detected = items_detected or ["Fresh Oven Pastries", "Artisan Viennoiserie", "Flaky Bakes"]
        dietary = "100% Pure Vegetarian • Contains Dairy"
        freshness = "Baked fresh today at 7:30 AM • Certified FSSAI Kitchen"
        orig = 420.0
        start = 210.0
        minimum = 120.0
        cover = random.choice(CATEGORY_MYSTERY_COVERS["bakery"])

    # 2. Cafe / Continental / Sandwiches / Wraps
    elif any(k in hints or k in category for k in ["cafe", "coffee", "sandwich", "wrap", "panini", "burger", "continental"]):
        titles = [
            "☕ Downtown Bistro Twilight Surprise Box",
            "🥪 Gourmet Deli & Toastie Mystery Bag",
            "🌿 European Cafe Savory Selection",
        ]
        descriptions = [
            "A vibrant, mouthwatering surprise assortment from our bistro kitchen. Featuring gourmet toasted breads, herb-infused spreads, crisp garden fillings, and savory cafe specialties prepared for today's dining crowd. Packed with balanced flavors for a hearty, wholesome evening snack!",
            "An artisan selection of comforting cafe savories and deli favorites. Prepared fresh this afternoon with premium herbs, melted cheeses, and freshly grilled fillings. A surprise delight to power through your evening work and study sessions!",
        ]
        detected = items_detected or ["Gourmet Toasted Sandwiches", "Herbed Savory Wraps", "Cafe Deli Bakes"]
        dietary = "Vegetarian • Fresh Handcrafted"
        freshness = "Prepared fresh at 2:00 PM • Sealed in thermo-insulated bag"
        orig = 360.0
        start = 180.0
        minimum = 110.0
        cover = random.choice(CATEGORY_MYSTERY_COVERS["cafe"])

    # 3. Regional / Curries / Thali / Hot Meals
    elif any(k in hints or k in category for k in ["curry", "thali", "rice", "dal", "paneer", "restaur", "dinner", "lunch", "meal"]):
        titles = [
            "🍛 Royal Kitchen Feast Mystery Box",
            "🍲 Master Chef's Sunset Curated Thali",
            "✨ Grand Haveli Gourmet Curry Vault",
        ]
        descriptions = [
            "A generous, royal assortment of slow-simmered regional delicacies, aromatic spiced gravies, and fragrant grain preparations cooked fresh for today's banquet service. Rich in traditional flavors, roasted spices, and wholesome ingredients—a hearty hot meal rescued from waste!",
            "An executive chef's surprise curation of traditional Indian delicacies. Packed with deeply comforting, spiced gravies, tender paneer preparations, and wholesome sides crafted with authentic home-style seasonings. Satisfying, hot, and 100% delicious!",
        ]
        detected = items_detected or ["Regional Curries", "Slow-Simmered Gravies", "Aromatic Rice Prep"]
        dietary = "100% Pure Vegetarian • Hearty Hot Meal"
        freshness = "Prepared in dinner shift at 6:30 PM • Maintained at safe hot holding temp"
        orig = 350.0
        start = 175.0
        minimum = 100.0
        cover = random.choice(CATEGORY_MYSTERY_COVERS["restaurant"])

    # 4. Pizza / Italian / Bakes
    elif any(k in hints or k in category for k in ["pizza", "pasta", "italian", "cheese"]):
        titles = [
            "🍕 Napoli Woodfired Mystery Crate",
            "🧀 Tuscan Oven Hearth Mystery Box",
        ]
        descriptions = [
            "A sizzling surprise selection of artisan Italian bakes and hearth-baked favorites. Infused with aromatic Mediterranean herbs, melted cheeses, blistered golden crusts, and rich slow-cooked marinara sauce. An epic evening slice surprise at a fraction of menu price!",
        ]
        detected = items_detected or ["Artisan Hearth Bakes", "Herb-Crusted Slices", "Melted Cheese Delicacies"]
        dietary = "Vegetarian • Fresh Baked"
        freshness = "Oven baked fresh today • Packed in ventilated food-grade box"
        orig = 380.0
        start = 190.0
        minimum = 110.0
        cover = random.choice(CATEGORY_MYSTERY_COVERS["pizza"])

    # 5. Street Savories / Samosa / Chaat / Snacks
    elif any(k in hints or k in category for k in ["snack", "samosa", "chaat", "roll", "tiffin", "south", "vada"]):
        titles = [
            "🥟 Golden Spice Evening Savory Crate",
            "🌶️ Crispy Heritage Street Mystery Box",
        ]
        descriptions = [
            "A tantalizing surprise mix of golden, crispy savories and spiced treats! Features handcrafted flaky crusts, rich aromatic spices, and savory spiced fillings prepared fresh for today's tea-time rush. Hot, crispy, and immensely satisfying comfort food!",
        ]
        detected = items_detected or ["Crispy Spiced Savories", "Golden Puffs", "Tea-Time Delights"]
        dietary = "100% Pure Veg • Sizzling Savory"
        freshness = "Fried and baked fresh at 4:30 PM • Crisp and warm"
        orig = 260.0
        start = 130.0
        minimum = 80.0
        cover = random.choice(CATEGORY_MYSTERY_COVERS["bakery"])

    # 6. Default / Healthy / General Market
    else:
        titles = [
            "🌿 Chef's Secret Surplus Mystery Box",
            "🎁 Green Gourmet Surplus Surprise",
        ]
        descriptions = [
            "A thoughtfully curated surprise assortment of today's premium surplus culinary creations. Every box contains top-quality, freshly prepared items sourced directly from our kitchen counters. 100% delicious, rigorously inspected for food hygiene, and guaranteed to exceed its value!",
        ]
        detected = items_detected or ["Chef's Daily Specialties", "Gourmet Kitchen Surplus"]
        dietary = "Vegetarian / Fresh Prepared"
        freshness = "Prepared fresh today • Inspected by Head Chef"
        orig = 320.0
        start = 160.0
        minimum = 95.0
        cover = random.choice(CATEGORY_MYSTERY_COVERS["healthy"])

    return {
        "success": True,
        "mystery_title": random.choice(titles),
        "mystery_description": random.choice(descriptions),
        "dietary_tag": dietary,
        "freshness_guarantee": freshness,
        "suggested_original_value": orig,
        "suggested_start_price": start,
        "suggested_min_price": minimum,
        "detected_items_internal": detected,
        "cover_image_url": cover
    }
