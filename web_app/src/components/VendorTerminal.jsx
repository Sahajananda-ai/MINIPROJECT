import React, { useState } from 'react';
import { QrCode, CheckCircle2, XCircle, Sparkles, AlertTriangle, ArrowRight, Store, Box, ShieldCheck } from 'lucide-react';
import { verifyPickupCode, generateAiDescription } from '../services/api';

export default function VendorTerminal({ deals, onNewDealCreated }) {
  const [vendorId] = useState(1); // L'Artisan Bakery
  const [pickupInput, setPickupInput] = useState('');
  const [verifying, setVerifying] = useState(false);
  const [verifyResult, setVerifyResult] = useState(null);
  const [verifyError, setVerifyError] = useState(null);

  // AI Mystery Creator state
  const [aiCategory, setAiCategory] = useState('Bakery');
  const [aiItemsText, setAiItemsText] = useState('3 butter croissants, 2 pain au chocolat, 1 almond puff');
  const [aiGenerating, setAiGenerating] = useState(false);
  const [aiResult, setAiResult] = useState(null);

  const handleVerify = async (e) => {
    e?.preventDefault();
    if (!pickupInput.trim()) return;

    setVerifying(true);
    setVerifyResult(null);
    setVerifyError(null);

    try {
      const res = await verifyPickupCode(vendorId, pickupInput.trim());
      if (res && res.success) {
        setVerifyResult(res.order);
        setPickupInput('');
      } else {
        setVerifyError(res?.message || 'Verification failed');
      }
    } catch (err) {
      setVerifyError(err.message || 'Passcode invalid or expired');
    } finally {
      setVerifying(false);
    }
  };

  const handleAiCurate = async () => {
    setAiGenerating(true);
    try {
      const res = await generateAiDescription({
        category: aiCategory,
        itemsText: aiItemsText,
        imageUrl: "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800&auto=format&fit=crop&q=80"
      });
      setAiResult(res);
    } catch (err) {
      console.error(err);
    } finally {
      setAiGenerating(false);
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '24px', paddingBottom: '32px' }}>
      {/* Vendor Header */}
      <div className="paper-card" style={{ padding: '20px', background: '#0E5B4B', color: '#FFFFFF', borderColor: '#083D32' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <div style={{
            width: '48px',
            height: '48px',
            borderRadius: '14px',
            background: 'rgba(255, 255, 255, 0.15)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center'
          }}>
            <Store size={24} color="#FFFFFF" />
          </div>
          <div>
            <div style={{ fontSize: '11px', textTransform: 'uppercase', letterSpacing: '0.06em', opacity: 0.8 }}>
              Partner Vendor Portal
            </div>
            <h2 className="serif-heading" style={{ color: '#FFFFFF', fontSize: '20px' }}>
              L'Artisan Bakery & Cafe
            </h2>
          </div>
        </div>
      </div>

      {/* --- SECTION 1: PICKUP CODE VERIFIER (FIXES BUG 3) --- */}
      <div className="paper-card" style={{ padding: '22px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '6px' }}>
          <ShieldCheck size={18} color="#0E5B4B" />
          <h3 style={{ fontSize: '17px', fontWeight: 700 }}>Customer Pickup Verifier</h3>
        </div>
        <p style={{ fontSize: '13px', color: '#6B6358', marginBottom: '16px' }}>
          Enter or scan the customer's digital pass code. Invalid or already-redeemed passes will be rejected.
        </p>

        <form onSubmit={handleVerify} style={{ display: 'flex', gap: '10px' }}>
          <input
            type="text"
            placeholder="e.g. MB-41-8392"
            value={pickupInput}
            onChange={(e) => setPickupInput(e.target.value.toUpperCase())}
            style={{
              flex: 1,
              padding: '14px 16px',
              borderRadius: '14px',
              border: '1.5px solid #E6DFD1',
              fontFamily: 'var(--font-mono)',
              fontSize: '16px',
              fontWeight: 700,
              letterSpacing: '1px',
              backgroundColor: '#FAF7F0',
              outline: 'none'
            }}
          />
          <button
            type="submit"
            className="btn-primary"
            style={{ padding: '14px 22px' }}
            disabled={verifying || !pickupInput.trim()}
          >
            {verifying ? 'Verifying...' : 'Verify Pass'}
          </button>
        </form>

        {/* Verification Success Feedback */}
        {verifyResult && (
          <div style={{
            marginTop: '16px',
            backgroundColor: '#E8F3F0',
            border: '1.5px solid rgba(14, 91, 75, 0.3)',
            borderRadius: '16px',
            padding: '16px',
            display: 'flex',
            gap: '12px'
          }}>
            <CheckCircle2 size={24} color="#0E5B4B" style={{ flexShrink: 0 }} />
            <div>
              <div style={{ fontWeight: 800, color: '#0E5B4B', fontSize: '15px' }}>
                Verified! Hand Over Mystery Box
              </div>
              <div style={{ fontSize: '13px', color: '#26221D', marginTop: '4px' }}>
                Customer: <strong>{verifyResult.student_name}</strong>
              </div>
              <div style={{ fontSize: '12px', color: '#6B6358' }}>
                {verifyResult.deal_title} • Paid ₹{verifyResult.paid_price}
              </div>
              <div className="pill-badge pill-teal" style={{ marginTop: '8px' }}>
                Status: COLLECTED 🌱
              </div>
            </div>
          </div>
        )}

        {/* Verification Error Feedback */}
        {verifyError && (
          <div style={{
            marginTop: '16px',
            backgroundColor: '#FDF1ED',
            border: '1.5px solid rgba(231, 111, 81, 0.3)',
            borderRadius: '16px',
            padding: '16px',
            display: 'flex',
            gap: '12px'
          }}>
            <XCircle size={24} color="#E76F51" style={{ flexShrink: 0 }} />
            <div>
              <div style={{ fontWeight: 800, color: '#E76F51', fontSize: '14px' }}>
                Pass Verification Failed
              </div>
              <div style={{ fontSize: '13px', color: '#6B6358', marginTop: '2px' }}>
                {verifyError}
              </div>
            </div>
          </div>
        )}
      </div>

      {/* --- SECTION 2: LIVE SURPLUS INVENTORY (FIXES BUG 1) --- */}
      <div className="paper-card" style={{ padding: '22px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px' }}>
          <div>
            <h3 style={{ fontSize: '17px', fontWeight: 700 }}>Active Surplus Batches</h3>
            <p style={{ fontSize: '12px', color: '#6B6358' }}>
              Enforces strict concurrency: when quantity hits 0, reservations automatically halt.
            </p>
          </div>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {deals.map(deal => (
            <div key={deal.id} style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              padding: '14px',
              backgroundColor: '#FAF7F0',
              borderRadius: '14px',
              border: '1px solid #ECE6D8'
            }}>
              <div>
                <div style={{ fontWeight: 700, fontSize: '14px' }}>{deal.title}</div>
                <div style={{ fontSize: '12px', color: '#6B6358' }}>
                  Decays from ₹{deal.start_price} to min ₹{deal.min_price}
                </div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div className={`pill-badge ${deal.quantity > 0 ? 'pill-teal' : 'pill-amber'}`}>
                  {deal.quantity > 0 ? `${deal.quantity} Boxes Left` : 'SOLD OUT'}
                </div>
                <div style={{ fontSize: '11px', color: '#6B6358', marginTop: '4px' }}>
                  Batch #{deal.id}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* --- SECTION 3: AI SENSORY MYSTERY CURATOR --- */}
      <div className="paper-card" style={{ padding: '22px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '6px' }}>
          <Sparkles size={18} color="#E76F51" />
          <h3 style={{ fontSize: '17px', fontWeight: 700 }}>AI Mystery Description Curator</h3>
        </div>
        <p style={{ fontSize: '13px', color: '#6B6358', marginBottom: '14px' }}>
          List surplus kitchen items. The AI curates an appetizing sensory narrative without exposing the exact items to customers!
        </p>

        <div style={{ marginBottom: '12px' }}>
          <label style={{ fontSize: '12px', fontWeight: 700, color: '#6B6358', display: 'block', marginBottom: '4px' }}>
            Category
          </label>
          <select
            value={aiCategory}
            onChange={(e) => setAiCategory(e.target.value)}
            style={{
              width: '100%',
              padding: '10px 12px',
              borderRadius: '12px',
              border: '1.5px solid #E6DFD1',
              backgroundColor: '#FAF7F0',
              fontSize: '13px'
            }}
          >
            <option value="Bakery">Bakery & Viennoiserie</option>
            <option value="Cafe">Artisan Cafe & Deli</option>
            <option value="Restaurant">Gourmet Curries & Meals</option>
            <option value="Pizza">Woodfired Pizzeria</option>
          </select>
        </div>

        <div style={{ marginBottom: '14px' }}>
          <label style={{ fontSize: '12px', fontWeight: 700, color: '#6B6358', display: 'block', marginBottom: '4px' }}>
            Surplus Items in Kitchen (Kept Secret from Buyers)
          </label>
          <textarea
            rows={2}
            value={aiItemsText}
            onChange={(e) => setAiItemsText(e.target.value)}
            style={{
              width: '100%',
              padding: '10px 12px',
              borderRadius: '12px',
              border: '1.5px solid #E6DFD1',
              backgroundColor: '#FAF7F0',
              fontSize: '13px'
            }}
          />
        </div>

        <button
          className="btn-primary"
          style={{ width: '100%', padding: '12px' }}
          onClick={handleAiCurate}
          disabled={aiGenerating}
        >
          <Sparkles size={16} />
          {aiGenerating ? 'AI Synthesizing Sensory Narrative...' : 'Synthesize Mystery Description'}
        </button>

        {aiResult && (
          <div style={{
            marginTop: '16px',
            backgroundColor: '#FAF7F0',
            border: '1.5px solid #E6DFD1',
            borderRadius: '16px',
            padding: '16px'
          }}>
            <div style={{ fontSize: '11px', textTransform: 'uppercase', color: '#E76F51', fontWeight: 800 }}>
              AI Generated Customer Copy
            </div>
            <div style={{ fontWeight: 800, fontSize: '16px', margin: '6px 0 4px', color: '#0E5B4B' }}>
              {aiResult.mystery_title}
            </div>
            <p style={{ fontSize: '13px', color: '#26221D', lineHeight: 1.5 }}>
              {aiResult.mystery_description}
            </p>
            <div style={{ display: 'flex', gap: '8px', marginTop: '10px' }}>
              <span className="pill-badge pill-teal">{aiResult.dietary_tag}</span>
              <span className="pill-badge pill-amber">Surprise Protected</span>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
