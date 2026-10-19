# SaveBite Component Specs

Based on TGTG functionality + Pizza Amici / Batch aesthetic (warm matte papermorphism)

---

## DealCard
```
variants   horizontal (list), vertical (grid), compact (map bottom-sheet)
sizes      horizontal: h=120, vertical: h=260, compact: h=88
states     default, loading (shimmer), sold-out (overlay + badge), favourite-toggled
tokens     bg surface, radius card (24), shadow md, font base/400 body + lg/700 price
a11y       tappable, semantic card, heart button separate tap target
used on    S04, S05, S11
notes      Pizza Amici-style rounded corners with subtle border. 
           Image top (vertical) or left (horizontal). 
           Warm amber "70% OFF" badge floating on image.
           Sold-out: semi-transparent charcoal overlay + "Sold Out" chip.
           Favourite heart pulses on toggle with spring easing.
```

## CategoryChip
```
variants   selected, unselected
sizes      h=36, horizontal scroll
states     default, active (accent bg), pressed (scale 0.95)
tokens     bg accent-subtle (unselected) / accent (selected), text accent / on-accent, radius pill, font sm/600
a11y       row of buttons, selected state announced
used on    S04
notes      Horizontal scroll with fade edges. Active chip slides indicator underneath.
           Labels: All, Bakery, Restaurant, Café, Grocery, Meals
```

## PriceBadge
```
variants   discount-badge (floating on image), inline (in card)
sizes      floating: auto, inline: auto
states     filled
tokens     bg secondary, text on-secondary, radius pill, font xs/800, shadow glow-secondary
a11y       text alternative: "70% off, was ₹420 now ₹140"
used on    S04, S06, S07
notes      Floating badge has fire icon + "UP TO 70% OFF". 
           Inline shows strikethrough original + bold discount price.
```

## PickupWindow
```
variants   badge (on card), detail (on store page), countdown (on active order)
sizes      badge: compact, detail: full width
states     available (green text), closing-soon (amber, < 1hr), closed (grey)
tokens     text success/warning/text-muted, font sm/600, icon clock
a11y       "Pickup window: Today 6:00 PM to 7:00 PM"
used on    S06, S08, S09, S14
notes      Countdown variant shows live mm:ss remaining. Pulses when < 10 min.
```

## ReserveButton
```
variants   primary CTA
sizes      h=56, full width
states     enabled, disabled (sold out, greyed), loading (spinner), success (checkmark morph)
tokens     bg accent, text on-accent, radius xl (28), shadow glow-accent, font lg/700
a11y       button, disabled state announced, loading keeps label for SR
used on    S06
notes      Pizza Amici-style bounce on hover (scale 1.04 rotate -1deg).
           Press: scale 0.97. Loading: spinner replaces text with same width.
           Success: button morphs to green check with confetti burst.
```

## PickupCode
```
variants   large-display (confirmation), mini-peek (order card)
sizes      large: 48px mono font, mini: 14px
states     visible, copied (toast), expired
tokens     font-mono 3xl/800 (large), font-mono sm/600 (mini), bg surface, border dashed accent
a11y       selectable text, copy button
used on    S08, S09
notes      Large code has dashed border box, tap-to-copy. 
           Subtle pulse animation to draw attention.
```

## SwipeToCollect
```
variants   slider
sizes      h=64, full width minus padding
states     idle (thumb at left), swiping (thumb follows finger), confirmed (thumb reaches end, bg fills green)
tokens     bg bg-warm, thumb bg accent, track-fill success, radius pill, font md/600
a11y       button with drag interaction, also tappable as fallback
used on    S08
notes      Satisfying haptic feedback at threshold. 
           Track fills with green gradient as thumb moves.
           On confirm: thumb morphs to checkmark, success ripple.
```

## StarRating
```
variants   input (tappable), display (read-only)
sizes      star: 32px (input), 16px (display)
states     unrated (empty stars), partial (1-4), full (5), disabled
tokens     filled: secondary (amber), empty: border, font sm/400
a11y       radio group, "Rate 1 to 5 stars"
used on    S10, S06 (display)
```

## ImpactCounter
```
variants   meals-saved, co2-avoided, money-saved
sizes      card: 120×100
states     zero (illustrated empty), counting-up (animated number roll)
tokens     bg surface, text accent (number), text-muted (label), font 2xl/800 (number)
a11y       live region for screen reader
used on    S12, S13
notes      Number rolls up with spring easing on screen enter.
           Small leaf/earth/wallet icon above number.
```

## BottomNav
```
variants   student (4 tabs: Discover, Map, Orders, Profile), vendor (3 tabs: Dashboard, History, Settings)
sizes      h=72 + safe-area-bottom
states     tab: default, active (accent icon + label, indicator dot)
tokens     bg surface, border-top border, active text accent, inactive text-muted, font xs/600
a11y       tab bar, active tab announced
used on    all screens
notes      Active tab icon scales up slightly (1.15) with bounce. 
           Floating above content with subtle top shadow.
           Pizza Amici-style: no harsh borders, cream background.
```

## MapPin
```
variants   available (accent green), sold-out (grey), selected (enlarged with label)
sizes      default: 32px, selected: 48px + label
states     default, selected (pop-up with store name), cluster (number badge)
tokens     bg accent/text-muted, shadow md, radius circle
a11y       map marker, store name on select
used on    S05
```

## OrderCard
```
variants   active (with countdown), completed (greyed, check), cancelled (red stripe)
sizes      h=auto, full width
states     active (countdown ticking), ready-for-pickup (accent border pulse), completed, cancelled
tokens     bg surface, radius card, shadow sm, border-left accent/success/danger
a11y       card, status announced
used on    S09
notes      Active cards have left accent border. 
           Countdown badge in top-right with live update.
```

## VendorStatCard
```
variants   bags-available, reserved, collected
sizes      equal-width grid (3 cards)
states     zero, positive count
tokens     bg surface, text 2xl/800, label text-muted sm/500, radius lg, shadow sm
a11y       stat label and value
used on    S14
notes      Each card has subtle icon (box, clock, check) behind the number.
           Count animates on data refresh.
```

## Toast
```
variants   success (green), error (red), info (accent)
sizes      auto width, max 340px
states     entering (slide up + fade), visible (auto-dismiss 3s), exiting (slide down + fade)
tokens     bg success/danger/accent, text white, radius lg, shadow lg, font sm/600
a11y       alert role, auto-dismiss with manual close
used on    global
```

## EmptyState
```
variants   no-deals, no-orders, no-favourites, no-history
sizes      centered in content area
states     visible (when 0 items)
tokens     text-muted, font lg/600 heading + base/400 body, illustration 160px
a11y       heading + description
used on    S04, S09, S11, S17
notes      Each variant has a unique warm illustration (leaf, box, heart, calendar).
           CTA button: "Explore nearby" / "Browse deals" etc.
```

## StoreHeader
```
variants   hero image with gradient overlay
sizes      h=240, full width
states     loaded (image), placeholder (shimmer), error (fallback color)
tokens     radius: bottom-left/right xl, shadow lg, gradient overlay charcoal→transparent
a11y       decorative image with alt text
used on    S06
notes      Parallax-subtle scroll effect. Back button (circle, semi-transparent bg).
           Heart button top-right. Category badge bottom-left floating.
```

## Modal
```
variants   confirmation, error, share, sold-out-interrupt
sizes      width 340, centered
states     opening (scale 0.95→1, fade in), visible, closing (scale 1→0.95, fade out)
tokens     bg surface, radius xl, shadow xl, overlay behind
a11y       dialog role, focus trap, escape to close
used on    S07, S08, S16
notes      Backdrop blur (4px) + dark overlay. 
           Scale + fade animation with bounce easing on enter.
```
