import React, { useState, useEffect } from 'react';
import { Lock, Timer, ShieldCheck, CheckCircle, QrCode, ArrowRight, X, AlertCircle } from 'lucide-react';
import confetti from 'canvas-confetti';
import { createOrder } from '../services/api';

export default function CheckoutModal({ deal, onClose, onOrderPlaced }) {
  const [timeLeft, setTimeLeft] = useState(300); // 5-minute Redis ephemeral lock
  const [paymentMethod, setPaymentMethod] = useState('UPI');
  const [processing, setProcessing] = useState(false);
  const [completedOrder, setCompletedOrder] = useState(null);
  const [error, setError] = useState(null);

  // Calculate live dynamic decay price
  const originalValue = deal.original_value || 420;
  const reservedPrice = deal.start_price ? Math.round(deal.start_price * 0.75) : 140;
  const savings = Math.max(0, originalValue - reservedPrice);
  const discountPct = Math.round((savings / originalValue) * 100);

  // 5-minute ephemeral lock timer
  useEffect(() => {
    if (completedOrder) return;
    const interval = setInterval(() => {
      setTimeLeft(prev => {
        if (prev <= 1) {
          clearInterval(interval);
          return 0;
        }
        return prev - 1;
      });
    }, 1000);
    return () => clearInterval(interval);
  }, [completedOrder]);

  const formatTime = (secs) => {
    const m = Math.floor(secs / 60);
    const s = secs % 60;
    return `${m}:${s.toString().padStart(2, '0')}`;
  };

  const handlePay = async () => {
    setProcessing(true);
    setError(null);
    try {
      const res = await createOrder(deal.id, 1, paymentMethod);
      if (res && res.order) {
        setCompletedOrder(res.order);
        onOrderPlaced?.(res.order);

        // Confetti burst on successful food rescue
        confetti({
          particleCount: 80,
          spread: 70,
          origin: { y: 0.6 },
          colors: ['#0E5B4B', '#E76F51', '#E9C46A']
        });
      }
    } catch (err) {
      setError(err.message || 'Payment simulation failed');
    } finally {
      setProcessing(false);
    }
  };

  return (
    <div style={{
      position: 'fixed',
      inset: 0,
      backgroundColor: 'rgba(25, 20, 15, 0.65)',
      backdropFilter: 'blur(6px)',
      zIndex: 1000,
      display: 'flex',
      alignItems: 'flex-end',
      justifyContent: 'center'
    }}>
      <div style={{
        backgroundColor: '#FAF7F0',
        width: '100%',
        maxWidth: '480px',
        maxHeight: '92vh',
        borderTopLeftRadius: '28px',
        borderTopRightRadius: '28px',
        border: '1.5px solid #E6DFD1',
        boxShadow: '0 -10px 40px rgba(0, 0, 0, 0.2)',
        overflowY: 'auto',
        padding: '24px',
        display: 'flex',
        flexDirection: 'column',
        gap: '18px'
      }}>
        {/* Header */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <h2 className="serif-heading" style={{ fontSize: '22px' }}>
              {completedOrder ? 'Pickup Pass Granted! 🎉' : 'Lock Your Mystery Box'}
            </h2>
            <p style={{ fontSize: '13px', color: '#6B6358' }}>
              {completedOrder ? 'Show code or QR at counter upon arrival' : deal.vendor?.name}
            </p>
          </div>
          <button 
            onClick={onClose}
            style={{
              background: '#EBE5D8',
              border: 'none',
              borderRadius: '50%',
              width: '36px',
              height: '36px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              cursor: 'pointer'
            }}
          >
            <X size={18} color="#26221D" />
          </button>
        </div>

        {error && (
          <div style={{
            backgroundColor: '#FDF1ED',
            color: '#E76F51',
            padding: '12px 16px',
            borderRadius: '14px',
            fontSize: '13px',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            border: '1px solid rgba(231, 111, 81, 0.3)'
          }}>
            <AlertCircle size={16} />
            {error}
          </div>
        )}

        {/* --- VIEW 1: PRE-PAYMENT CHECKOUT --- */}
        {!completedOrder && (
          <>
            {/* Redis Ephemeral Lock Countdown Banner */}
            <div style={{
              backgroundColor: timeLeft < 60 ? '#FDF1ED' : '#E8F3F0',
              border: `1.5px solid ${timeLeft < 60 ? 'rgba(231,111,81,0.4)' : 'rgba(14,91,75,0.25)'}`,
              padding: '14px 18px',
              borderRadius: '18px'
            }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <Lock size={16} color={timeLeft < 60 ? '#E76F51' : '#0E5B4B'} />
                  <span style={{ fontSize: '12px', fontWeight: 800, textTransform: 'uppercase', color: timeLeft < 60 ? '#E76F51' : '#0E5B4B', letterSpacing: '0.04em' }}>
                    Redis Concurrency Lock
                  </span>
                </div>
                <div style={{
                  fontFamily: 'var(--font-mono)',
                  fontSize: '18px',
                  fontWeight: 700,
                  color: timeLeft < 60 ? '#E76F51' : '#0E5B4B'
                }}>
                  {formatTime(timeLeft)}
                </div>
              </div>
              <div style={{
                height: '6px',
                backgroundColor: 'rgba(0,0,0,0.08)',
                borderRadius: '999px',
                overflow: 'hidden'
              }}>
                <div style={{
                  height: '100%',
                  width: `${(timeLeft / 300) * 100}%`,
                  backgroundColor: timeLeft < 60 ? '#E76F51' : '#0E5B4B',
                  transition: 'width 1s linear'
                }} />
              </div>
              <p style={{ fontSize: '11px', color: '#6B6358', marginTop: '6px', textAlign: 'center' }}>
                Box reserved exclusively for you. Inventory is protected against double-booking.
              </p>
            </div>

            {/* Order Bill Breakdown Card */}
            <div className="paper-card" style={{ padding: '18px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
                <div>
                  <h3 style={{ fontSize: '16px', fontWeight: 700 }}>{deal.title}</h3>
                  <span style={{ fontSize: '12px', color: '#6B6358' }}>{deal.dietary_tag}</span>
                </div>
                <div className="pill-badge pill-amber">
                  Save {discountPct}%
                </div>
              </div>

              <div style={{ borderTop: '1px solid #ECE6D8', paddingTop: '12px', display: 'flex', flexDirection: 'column', gap: '8px', fontSize: '13px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', color: '#6B6358' }}>
                  <span>Original Food Value</span>
                  <span style={{ textDecoration: 'line-through' }}>₹{originalValue}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', color: '#0E5B4B', fontWeight: 600 }}>
                  <span>Decay Surplus Discount</span>
                  <span>-₹{savings}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', color: '#6B6358' }}>
                  <span>Eco-Packaging Fee</span>
                  <span style={{ color: '#0E5B4B', fontWeight: 700 }}>FREE</span>
                </div>
                <div style={{
                  borderTop: '1.5px dashed #D9D2C3',
                  paddingTop: '10px',
                  marginTop: '4px',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'baseline'
                }}>
                  <span style={{ fontSize: '15px', fontWeight: 800 }}>Total Pay</span>
                  <span style={{ fontSize: '24px', fontWeight: 800, color: '#0E5B4B' }}>₹{reservedPrice}</span>
                </div>
              </div>
            </div>

            {/* Payment Method Selector */}
            <div>
              <label style={{ fontSize: '12px', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.04em', color: '#6B6358', display: 'block', marginBottom: '8px' }}>
                Payment Method
              </label>
              <div style={{ display: 'flex', gap: '10px' }}>
                {['UPI', 'CARD'].map(method => (
                  <button
                    key={method}
                    type="button"
                    onClick={() => setPaymentMethod(method)}
                    style={{
                      flex: 1,
                      padding: '12px',
                      borderRadius: '14px',
                      border: paymentMethod === method ? '2px solid #0E5B4B' : '1.5px solid #E6DFD1',
                      background: paymentMethod === method ? '#E8F3F0' : '#FFFFFF',
                      color: paymentMethod === method ? '#0E5B4B' : '#26221D',
                      fontWeight: 700,
                      fontSize: '13px',
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      gap: '8px'
                    }}
                  >
                    <ShieldCheck size={16} />
                    {method === 'UPI' ? 'Instant UPI' : 'Card / Bank'}
                  </button>
                ))}
              </div>
            </div>

            {/* Pay Button */}
            <button
              className="btn-primary"
              style={{ width: '100%', padding: '16px', fontSize: '15px' }}
              onClick={handlePay}
              disabled={processing || timeLeft === 0}
            >
              {processing ? 'Confirming with Redis Lock...' : `Pay ₹${reservedPrice} & Lock Pass`}
              <ArrowRight size={18} />
            </button>
          </>
        )}

        {/* --- VIEW 2: POST-PAYMENT DIGITAL PASS --- */}
        {completedOrder && (
          <div className="ticket-pass" style={{ padding: '24px', textAlign: 'center' }}>
            <div style={{
              width: '64px',
              height: '64px',
              borderRadius: '50%',
              backgroundColor: '#E8F3F0',
              color: '#0E5B4B',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              margin: '0 auto 14px'
            }}>
              <CheckCircle size={36} />
            </div>

            <div className="pill-badge pill-teal" style={{ marginBottom: '8px' }}>
              Reserved & Paid
            </div>
            <h3 className="serif-heading" style={{ fontSize: '20px', marginBottom: '4px' }}>
              {completedOrder.vendor_name || deal.vendor?.name}
            </h3>
            <p style={{ fontSize: '12px', color: '#6B6358', marginBottom: '16px' }}>
              Pickup before store closing hours
            </p>

            {/* Ticket Divider with Notches */}
            <div className="ticket-divider">
              <div className="ticket-dashed-line" />
            </div>

            {/* Passcode & QR Code */}
            <div style={{
              backgroundColor: '#FAF7F0',
              padding: '16px',
              borderRadius: '16px',
              border: '1.5px solid #E6DFD1',
              margin: '14px 0'
            }}>
              <div style={{
                fontFamily: 'var(--font-mono)',
                fontSize: '26px',
                fontWeight: 800,
                letterSpacing: '3px',
                color: '#0E5B4B',
                marginBottom: '4px'
              }}>
                {completedOrder.pickup_code}
              </div>
              <p style={{ fontSize: '11px', color: '#6B6358', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                Single-Use Pickup Verification Code
              </p>
            </div>

            {/* QR Code Graphic */}
            <div style={{
              display: 'inline-flex',
              padding: '12px',
              borderRadius: '16px',
              backgroundColor: '#FFFFFF',
              border: '1px solid #ECE6D8',
              boxShadow: '0 2px 8px rgba(0,0,0,0.04)',
              marginBottom: '18px'
            }}>
              <QrCode size={110} color="#0E5B4B" />
            </div>

            <button 
              className="btn-primary" 
              style={{ width: '100%', padding: '14px' }}
              onClick={onClose}
            >
              Done • View in My Passes
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
