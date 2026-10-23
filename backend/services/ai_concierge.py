"""
SaveBite AI Concierge.

A real, useful assistant that answers student questions about the app using
LIVE data from the database (active mystery boxes, prices, closing times,
savings, how pickup works). This grounding is what makes it genuinely helpful
rather than a hallucinating chatbot.

Brain hierarchy:
  1. Google Gemini (if GEMINI_API_KEY set) — natural, contextual replies.
  2. Deterministic rule/template engine — always works, no key required.

The live-deal context is computed once and handed to either brain, so answers
are always grounded in what is actually available right now.
"""
import os
import json
import re
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any

from sqlalchemy.orm import Session
from .. import models
from ..services import decay_pricing


def _hours_left(closing_time: datetime, now: datetime) -> float:
    if closing_time.tzinfo is None:
        closing_time = closing_time.replace(tzinfo=timezone.utc)
    return max(0.0, (closing_time - now).total_seconds() / 3600.0)


def build_live_context(db: Session, max_deals: int = 6) -> Dict[str, Any]:
    """Snapshot of what is actually available right now — the grounding truth."""
    now = datetime.now(timezone.utc)
    active = (
        db.query(models.Deal)
        .filter(
            models.Deal.is_active == True,  # noqa: E712
            models.Deal.closing_time > now,
            models.Deal.quantity > 0,
        )
        .all()
    )

    deals = []
    for d in active:
        price = decay_pricing.calculate_decay_price(d)
        vendor = d.vendor
        deals.append(
            {
                "vendor": vendor.name if vendor else "Local kitchen",
                "category": vendor.shop_category if vendor else "Food",
                "title": d.title or "Surplus Mystery Box",
                "dietary": d.dietary_tag or "Vegetarian",
                "price": round(price, 0),
                "value": round(d.original_value, 0),
                "discount_pct": round(((d.original_value - price) / d.original_value) * 100)
                if d.original_value > 0
                else 0,
                "qty": d.quantity,
                "hours_left": round(_hours_left(d.closing_time, now), 1),
            }
        )

    # Best value first (biggest discount), then urgency.
    deals.sort(key=lambda x: (x["discount_pct"], -x["hours_left"]), reverse=True)
    deals = deals[:max_deals]

    return {
        "now_utc": now.isoformat(),
        "active_count": len(deals),
        "deals": deals,
    }


def _context_block(ctx: Dict[str, Any]) -> str:
    if not ctx["deals"]:
        return "RIGHT NOW there are NO active mystery boxes available."
    lines = [f"RIGHT NOW there are {ctx['active_count']} active mystery boxes:"]
    for d in ctx["deals"]:
        lines.append(
            f"- {d['vendor']} ({d['category']}): ₹{d['price']:.0f} "
            f"(worth ₹{d['value']:.0f}, {d['discount_pct']}% off), "
            f"{d['dietary']}, {d['qty']} left, closes in {d['hours_left']}h."
        )
    return "\n".join(lines)


def _try_gemini(api_key: str, question: str, ctx: Dict[str, Any]) -> Optional[str]:
    import urllib.request

    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        f"gemini-1.5-flash:generateContent?key={api_key}"
    )
    prompt = (
        "You are SaveBite's friendly in-app assistant. SaveBite is a campus app that "
        "sells discounted 'mystery boxes' of surplus food from local shops to prevent "
        "food waste. Students reserve a box in the app, then walk to the shop to pick "
        "it up and show a pickup pass code.\n\n"
        "Answer using ONLY the live data below. Be concise (2-4 sentences), warm, and "
        "helpful. Use ₹ for prices. If asked about something not covered by the data, "
        "say you're not sure rather than inventing shops or prices.\n\n"
        f"LIVE DATA:\n{_context_block(ctx)}\n\n"
        f"STUDENT'S QUESTION: {question}\n\n"
        "Reply in plain text only (no markdown, no JSON)."
    )
    payload = json.dumps({"contents": [{"parts": [{"text": prompt}]}]}).encode("utf-8")
    req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=8) as resp:
        data = json.loads(resp.read().decode("utf-8"))
        return data["candidates"][0]["content"]["parts"][0]["text"].strip()


def _best_deal(ctx: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    return ctx["deals"][0] if ctx["deals"] else None


def _rule_based_answer(question: str, ctx: Dict[str, Any]) -> str:
    """Deterministic assistant that still produces real, grounded answers."""
    q = question.lower()
    best = _best_deal(ctx)

    # Greeting / help
    if any(k in q for k in ["hi", "hello", "hey", "namaste", "help", "what can you"]):
        if best:
            return (
                "Hi! I'm your SaveBite assistant 🌿. I can tell you what mystery boxes "
                f"are available right now, the best deals, and how pickup works. "
                f"Right now there are {ctx['active_count']} boxes live — the top one is "
                f"{best['vendor']} at ₹{best['price']:.0f} ({best['discount_pct']}% off). "
                "Ask me anything!"
            )
        return (
            "Hi! I'm your SaveBite assistant 🌿. There are no mystery boxes live at the "
            "moment, but I can still explain how SaveBite works — just ask!"
        )

    # Best deal / recommendation
    if any(k in q for k in ["best", "recommend", "cheapest", "good deal", "suggest", "what should"]):
        if not best:
            return "There are no active mystery boxes right now. Check back near shop closing time when fresh surplus gets listed!"
        return (
            f"My top pick is {best['vendor']} ({best['category']}) at just "
            f"₹{best['price']:.0f} — worth ₹{best['value']:.0f} at {best['discount_pct']}% off. "
            f"It's {best['dietary']} and closes in {best['hours_left']}h, so grab it soon!"
        )

    # Price / budget
    if any(k in q for k in ["price", "cost", "cheap", "budget", "afford", "how much"]):
        if not best:
            return "No boxes are live right now, so there's nothing to price. Prices drop as closing time nears!"
        cheapest = min(ctx["deals"], key=lambda d: d["price"])
        return (
            f"Boxes start at ₹{cheapest['price']:.0f} ({cheapest['vendor']}). "
            f"Prices use dynamic decay pricing — they fall as the closing time approaches "
            f"to move food before it's wasted."
        )

    # How it works / pickup / reserve
    if any(k in q for k in ["how", "work", "pickup", "pick up", "collect", "reserve", "order", "code", "pass"]):
        return (
            "Here's how SaveBite works: browse live mystery boxes on Discover, tap one to "
            "reserve and pay in-app, then walk to the shop using the Radar Map route. Show "
            "the pickup pass code at the counter and collect your box. It's discounted "
            "surplus food that would otherwise be thrown away!"
        )

    # Available now / what's there
    if any(k in q for k in ["available", "what's there", "what is there", "near me", "now", "any", "list"]):
        if not best:
            return "Nothing is live right now. Try again closer to closing hours when shops list their surplus."
        top = ctx["deals"][:3]
        parts = [f"{d['vendor']} ({d['category']}, ₹{d['price']:.0f})" for d in top]
        return f"Live right now: {', '.join(parts)}. " + f"{best['vendor']} is the best value at {best['discount_pct']}% off."

    # Sustainability / impact / veg
    if any(k in q for k in ["veg", "vegetarian", "vegan", "diet", "halal", "gluten", "allerg", "impact", "waste", "co2", "sustain"]):
        if best:
            return (
                f"Most boxes are clearly labelled — e.g. {best['vendor']} is {best['dietary']}. "
                "Every box you rescue keeps good food out of the bin and cuts CO₂. Check each "
                "box's dietary tag before reserving!"
            )
        return "Boxes are labelled with dietary tags (e.g. Vegetarian, Vegan, High Protein). Rescuing food also cuts waste and CO₂!"

    # Default fallback
    if best:
        return (
            f"I can help with live deals, prices, pickup, and how SaveBite works. "
            f"Right now the best deal is {best['vendor']} at ₹{best['price']:.0f} "
            f"({best['discount_pct']}% off). What would you like to know?"
        )
    return (
        "I can explain how SaveBite works, even when no boxes are live. "
        "Ask me about deals, prices, or how to pick up your box!"
    )


def answer(question: str, db: Session) -> Dict[str, Any]:
    """Answer a student question grounded in live deal data."""
    ctx = build_live_context(db)
    text: Optional[str] = None
    source = "rules"

    gemini_key = os.getenv("GEMINI_API_KEY")
    if gemini_key:
        try:
            text = _try_gemini(gemini_key, question, ctx)
            if text:
                source = "gemini"
        except Exception as e:
            print(f"[AI Concierge] Gemini fallback triggered: {e}")

    if not text:
        text = _rule_based_answer(question, ctx)
        source = "rules"

    return {
        "success": True,
        "reply": text,
        "source": source,
        "active_deals": ctx["active_count"],
    }
