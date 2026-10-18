import React, { useState, useEffect } from 'react';
import { Navigation, Clock, MapPin, X, ExternalLink, Footprints, ChevronRight } from 'lucide-react';
import { fetchWalkingRoute } from '../services/api';

export default function RouteNavigationModal({ vendor, onClose }) {
  const [routeData, setRouteData] = useState(null);
  const [loading, setLoading] = useState(true);

  // Student campus coordinates (e.g., Student Center Plaza)
  const studentLat = 28.6139;
  const studentLng = 77.2090;

  const vendorLat = vendor?.latitude || 28.6145;
  const vendorLng = vendor?.longitude || 77.2095;

  useEffect(() => {
    async function loadRoute() {
      setLoading(true);
      const data = await fetchWalkingRoute(studentLng, studentLat, vendorLng, vendorLat);
      setRouteData(data);
      setLoading(false);
    }
    loadRoute();
  }, [vendorLat, vendorLng]);

  const openGoogleMapsWalking = () => {
    const url = `https://www.google.com/maps/dir/?api=1&origin=${studentLat},${studentLng}&destination=${vendorLat},${vendorLng}&travelmode=walking`;
    window.open(url, '_blank');
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
        maxHeight: '90vh',
        borderTopLeftRadius: '28px',
        borderTopRightRadius: '28px',
        border: '1.5px solid #E6DFD1',
        boxShadow: '0 -10px 40px rgba(0, 0, 0, 0.2)',
        overflowY: 'auto',
        padding: '24px',
        display: 'flex',
        flexDirection: 'column',
        gap: '20px'
      }}>
        {/* Header */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <div className="pill-badge pill-teal" style={{ marginBottom: '6px' }}>
              <Footprints size={12} />
              Real Street Route
            </div>
            <h2 className="serif-heading" style={{ fontSize: '20px' }}>
              {vendor?.name || 'Mystery Partner'}
            </h2>
            <p style={{ fontSize: '13px', color: '#6B6358' }}>
              Walking directions from Student Plaza
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

        {/* Real Route Street Visualization Canvas */}
        <div style={{
          position: 'relative',
          height: '200px',
          backgroundColor: '#EBE5D8',
          borderRadius: '20px',
          overflow: 'hidden',
          border: '1.5px solid #DDD6C6',
          boxShadow: 'inset 0 2px 8px rgba(0,0,0,0.06)'
        }}>
          {/* Stylized Paper Street Map Background */}
          <svg width="100%" height="100%" style={{ position: 'absolute', inset: 0 }}>
            {/* Street Grid */}
            <path d="M 20 50 Q 120 40 220 80 T 420 70" stroke="#FAF7F0" strokeWidth="24" fill="none" />
            <path d="M 80 180 L 140 100 L 260 90 L 380 40" stroke="#FAF7F0" strokeWidth="20" fill="none" />
            <path d="M 140 100 L 180 190 L 320 180" stroke="#FAF7F0" strokeWidth="16" fill="none" />

            {/* Walking Path Polyline (Emerald route with dash animation) */}
            <path 
              d="M 60 160 Q 140 105 240 92 T 360 55" 
              stroke="#0E5B4B" 
              strokeWidth="6" 
              strokeDasharray="8 6"
              strokeLinecap="round"
              fill="none" 
            />

            {/* Start Pin: Student location */}
            <circle cx="60" cy="160" r="10" fill="#0E5B4B" opacity="0.2" />
            <circle cx="60" cy="160" r="6" fill="#0E5B4B" />

            {/* Destination Pin: Vendor */}
            <g transform="translate(350, 32)">
              <circle cx="10" cy="20" r="12" fill="#E76F51" opacity="0.25" />
              <path d="M10 0 C5 0 1 4 1 9 C1 16 10 24 10 24 C10 24 19 16 19 9 C19 4 15 0 10 0 Z" fill="#E76F51" />
              <circle cx="10" cy="9" r="4" fill="#FFFFFF" />
            </g>
          </svg>

          {/* Map Overlay Badge */}
          <div style={{
            position: 'absolute',
            bottom: '12px',
            left: '12px',
            backgroundColor: '#FFFFFF',
            padding: '6px 12px',
            borderRadius: '12px',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            boxShadow: '0 4px 12px rgba(0,0,0,0.1)',
            fontSize: '12px',
            fontWeight: 700,
            color: '#0E5B4B',
            border: '1px solid #E6DFD1'
          }}>
            <Clock size={14} />
            {loading ? 'Calculating road route...' : `${routeData?.durationMinutes || 6} min • ${routeData?.distanceMeters || 480} meters`}
          </div>
        </div>

        {/* Step-by-Step Road Directions */}
        <div style={{
          backgroundColor: '#FFFFFF',
          padding: '16px',
          borderRadius: '18px',
          border: '1.5px solid #E6DFD1'
        }}>
          <h4 style={{ fontSize: '13px', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.05em', color: '#6B6358', marginBottom: '12px' }}>
            Turn-by-Turn Route
          </h4>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            {routeData?.steps?.map((step, idx) => (
              <div key={idx} style={{ display: 'flex', alignItems: 'center', gap: '10px', fontSize: '13px', color: '#26221D' }}>
                <div style={{
                  width: '22px',
                  height: '22px',
                  borderRadius: '50%',
                  backgroundColor: '#E8F3F0',
                  color: '#0E5B4B',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontSize: '11px',
                  fontWeight: 800,
                  flexShrink: 0
                }}>
                  {idx + 1}
                </div>
                <span>{step}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Action Buttons */}
        <div style={{ display: 'flex', gap: '12px' }}>
          <button 
            className="btn-primary" 
            style={{ flex: 1, padding: '14px' }}
            onClick={openGoogleMapsWalking}
          >
            <Navigation size={18} />
            Start GPS Walk
            <ExternalLink size={14} style={{ opacity: 0.8 }} />
          </button>
          <button 
            className="btn-secondary" 
            style={{ padding: '14px 20px' }}
            onClick={onClose}
          >
            Done
          </button>
        </div>
      </div>
    </div>
  );
}
