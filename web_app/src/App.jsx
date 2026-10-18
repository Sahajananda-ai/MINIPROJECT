import React, { useState, useEffect } from 'react';
import { 
  Compass, Map, Ticket, Store, Sparkles, Clock, MapPin, 
  ChevronRight, Footprints, Flame, AlertCircle, ShoppingBag, 
  Leaf, Award, QrCode, ArrowUpRight
} from 'lucide-react';
import { fetchActiveDeals } from './services/api';
import CheckoutModal from './components/CheckoutModal';
import RouteNavigationModal from './components/RouteNavigationModal';
import VendorTerminal from './components/VendorTerminal';

export default function App() {
  const [role, setRole] = useState('student'); // 'student' | 'vendor'
  const [activeTab, setActiveTab] = useState('discover'); // 'discover' | 'map' | 'passes'
  const [deals, setDeals] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState('All');

  // Modals state
  const [selectedDealForCheckout, setSelectedDealForCheckout] = useState(null);
  const [selectedVendorForRoute, setSelectedVendorForRoute] = useState(null);

  // Student active orders state
  const [myOrders, setMyOrders] = useState([
    {
      id: 991,
      deal_id: 41,
      pickup_code: "MB-41-7291",
      vendor_name: "L'Artisan Bakery & Cafe",
      shop_category: "Bakery",
      paid_price: 140,
      original_value: 420,
      savings: 280,
      status: "PAID",
      latitude: 28.6145,
      longitude: 77.2095
    }
  ]);

  useEffect(() => {
    async function load() {
      setLoading(true);
      const data = await fetchActiveDeals();
      setDeals(data);
      setLoading(false);
    }
    load();
  }, []);

  const handleOrderPlaced = (newOrder) => {
    // Decrement deal quantity locally to immediately reflect inventory drop
    setDeals(prev => prev.map(d => {
      if (d.id === newOrder.deal_id) {
        return { ...d, quantity: Math.max(0, d.quantity - 1) };
      }
      return d;
    }));

    setMyOrders(prev => [newOrder, ...prev]);
    setActiveTab('passes');
  };

  const filteredDeals = deals.filter(deal => {
    if (selectedCategory === 'All') return true;
    return deal.vendor?.shop_category?.toLowerCase() === selectedCategory.toLowerCase();
  });

  return (
    <div className="paper-grain">
      <div className="app-viewport">
        {/* --- GLOBAL TOP BRANDING BAR --- */}
        <header style={{
          backgroundColor: '#0E5B4B',
          color: '#FFFFFF',
          padding: '16px 20px 14px',
          borderBottom: '2px solid #083D32'
        }}>
          {/* Top Ticker & Role Switcher */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '11px', opacity: 0.9 }}>
              <Leaf size={14} color="#E9C46A" />
              <span>Campus Food Rescue Network</span>
            </div>

            {/* Role Switcher Pill */}
            <div style={{
              display: 'flex',
              backgroundColor: '#083D32',
              borderRadius: '999px',
              padding: '3px',
              border: '1px solid rgba(255,255,255,0.1)'
            }}>
              <button
                onClick={() => setRole('student')}
                style={{
                  background: role === 'student' ? '#FAF7F0' : 'transparent',
                  color: role === 'student' ? '#0E5B4B' : 'rgba(255,255,255,0.7)',
                  border: 'none',
                  borderRadius: '999px',
                  padding: '4px 10px',
                  fontSize: '11px',
                  fontWeight: 800,
                  cursor: 'pointer',
                  transition: 'all 0.15s ease'
                }}
              >
                Student
              </button>
              <button
                onClick={() => setRole('vendor')}
                style={{
                  background: role === 'vendor' ? '#FAF7F0' : 'transparent',
                  color: role === 'vendor' ? '#0E5B4B' : 'rgba(255,255,255,0.7)',
                  border: 'none',
                  borderRadius: '999px',
                  padding: '4px 10px',
                  fontSize: '11px',
                  fontWeight: 800,
                  cursor: 'pointer',
                  transition: 'all 0.15s ease'
                }}
              >
                Store Portal
              </button>
            </div>
          </div>

          {/* Logo & Headline */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
            <div>
              <h1 className="serif-heading" style={{ color: '#FFFFFF', fontSize: '24px', letterSpacing: '-0.03em' }}>
                SaveBite
              </h1>
              <p style={{ fontSize: '12px', opacity: 0.85, marginTop: '1px' }}>
                Too Good To Go • Campus Mystery Vaults
              </p>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: '15px', fontWeight: 800, color: '#E9C46A' }}>
                ₹1,420
              </div>
              <div style={{ fontSize: '10px', opacity: 0.8, textTransform: 'uppercase', letterSpacing: '0.04em' }}>
                Student Savings
              </div>
            </div>
          </div>
        </header>

        {/* --- MAIN BODY CONTENT --- */}
        <main style={{ flex: 1, padding: '18px 18px 80px', overflowY: 'auto' }}>
          {/* VENDOR VIEW */}
          {role === 'vendor' && (
            <VendorTerminal deals={deals} onNewDealCreated={() => {}} />
          )}

          {/* STUDENT VIEW */}
          {role === 'student' && (
            <>
              {/* --- TAB 1: DISCOVER --- */}
              {activeTab === 'discover' && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
                  {/* Category Filter Chips */}
                  <div style={{ display: 'flex', gap: '8px', overflowX: 'auto', paddingBottom: '4px' }}>
                    {['All', 'Bakery', 'Cafe', 'Restaurant'].map(cat => (
                      <button
                        key={cat}
                        onClick={() => setSelectedCategory(cat)}
                        style={{
                          padding: '7px 14px',
                          borderRadius: '999px',
                          border: selectedCategory === cat ? '1.5px solid #0E5B4B' : '1px solid #E6DFD1',
                          backgroundColor: selectedCategory === cat ? '#0E5B4B' : '#FFFFFF',
                          color: selectedCategory === cat ? '#FFFFFF' : '#6B6358',
                          fontSize: '12px',
                          fontWeight: 700,
                          cursor: 'pointer',
                          whiteSpace: 'nowrap',
                          transition: 'all 0.15s ease'
                        }}
                      >
                        {cat}
                      </button>
                    ))}
                  </div>

                  {/* Mystery Boxes Feed */}
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '18px' }}>
                    {filteredDeals.map(deal => {
                      const orig = deal.original_value || 420;
                      const price = deal.start_price ? Math.round(deal.start_price * 0.75) : 140;
                      const discountPct = Math.round(((orig - price) / orig) * 100);
                      const isSoldOut = deal.quantity <= 0;

                      return (
                        <div key={deal.id} className="paper-card" style={{ overflow: 'hidden' }}>
                          {/* Image Cover */}
                          <div style={{ position: 'relative', height: '170px' }}>
                            <img
                              src={deal.image_url}
                              alt={deal.title}
                              style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                            />
                            {/* Overlay Gradient */}
                            <div style={{
                              position: 'absolute',
                              inset: 0,
                              background: 'linear-gradient(to top, rgba(0,0,0,0.6) 0%, transparent 60%)'
                            }} />

                            {/* Top Badges */}
                            <div style={{
                              position: 'absolute',
                              top: '12px',
                              left: '12px',
                              right: '12px',
                              display: 'flex',
                              justifyContent: 'space-between',
                              alignItems: 'center'
                            }}>
                              <span className="pill-badge pill-amber">
                                Save {discountPct}% OFF
                              </span>
                              <span style={{
                                backgroundColor: 'rgba(255,255,255,0.92)',
                                color: '#0E5B4B',
                                padding: '4px 10px',
                                borderRadius: '999px',
                                fontSize: '11px',
                                fontWeight: 800
                              }}>
                                {isSoldOut ? 'SOLD OUT' : `${deal.quantity} Boxes Left`}
                              </span>
                            </div>

                            {/* Bottom Title on Image */}
                            <div style={{ position: 'absolute', bottom: '12px', left: '14px', right: '14px' }}>
                              <h3 style={{ color: '#FFFFFF', fontSize: '17px', fontWeight: 800 }}>
                                {deal.title}
                              </h3>
                              <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: 'rgba(255,255,255,0.85)', fontSize: '12px', marginTop: '2px' }}>
                                <span>{deal.vendor?.name}</span>
                                <span>•</span>
                                <span>★ {deal.vendor?.rating || 4.9}</span>
                              </div>
                            </div>
                          </div>

                          {/* Card Content */}
                          <div style={{ padding: '16px' }}>
                            {/* Culinary Sensory Narrative (Specific Items Concealed!) */}
                            <p style={{ fontSize: '13px', color: '#6B6358', lineHeight: 1.5, marginBottom: '14px' }}>
                              {deal.description}
                            </p>

                            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '14px' }}>
                              <span className="pill-badge pill-teal">
                                {deal.dietary_tag}
                              </span>
                              <span style={{ fontSize: '11px', color: '#9B9387' }}>
                                Fresh surplus rescued daily
                              </span>
                            </div>

                            {/* Pricing & CTA */}
                            <div style={{
                              borderTop: '1px solid #ECE6D8',
                              paddingTop: '12px',
                              display: 'flex',
                              justifyContent: 'space-between',
                              alignItems: 'center'
                            }}>
                              <div>
                                <span style={{ fontSize: '12px', textDecoration: 'line-through', color: '#9B9387', marginRight: '6px' }}>
                                  ₹{orig}
                                </span>
                                <span style={{ fontSize: '22px', fontWeight: 800, color: '#0E5B4B' }}>
                                  ₹{price}
                                </span>
                              </div>

                              <div style={{ display: 'flex', gap: '8px' }}>
                                <button
                                  className="btn-secondary"
                                  style={{ padding: '8px 12px' }}
                                  title="View Real Walking Route"
                                  onClick={() => setSelectedVendorForRoute(deal.vendor)}
                                >
                                  <Footprints size={16} />
                                </button>
                                <button
                                  className="btn-primary"
                                  style={{ padding: '9px 18px' }}
                                  disabled={isSoldOut}
                                  onClick={() => setSelectedDealForCheckout(deal)}
                                >
                                  {isSoldOut ? 'Sold Out' : 'Reserve Box'}
                                </button>
                              </div>
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* --- TAB 2: RADAR MAP --- */}
              {activeTab === 'map' && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                  <div className="paper-card" style={{ padding: '18px' }}>
                    <div className="pill-badge pill-teal" style={{ marginBottom: '8px' }}>
                      <MapPin size={12} /> Campus Food Radar
                    </div>
                    <h2 className="serif-heading" style={{ fontSize: '20px' }}>
                      Surplus Near Student Plaza
                    </h2>
                    <p style={{ fontSize: '13px', color: '#6B6358', marginTop: '2px' }}>
                      Tap any campus spot to see real walking route & street steps.
                    </p>
                  </div>

                  {/* Stylized Paper Map View */}
                  <div style={{
                    height: '240px',
                    backgroundColor: '#EBE5D8',
                    borderRadius: '24px',
                    position: 'relative',
                    overflow: 'hidden',
                    border: '1.5px solid #DDD6C6',
                    boxShadow: 'inset 0 2px 10px rgba(0,0,0,0.06)'
                  }}>
                    <svg width="100%" height="100%" style={{ position: 'absolute', inset: 0 }}>
                      <path d="M 0 60 Q 140 40 280 100 T 500 80" stroke="#FAF7F0" strokeWidth="30" fill="none" />
                      <path d="M 60 220 L 140 120 L 300 100 L 440 20" stroke="#FAF7F0" strokeWidth="24" fill="none" />
                      <circle cx="200" cy="120" r="12" fill="#0E5B4B" opacity="0.2" />
                      <circle cx="200" cy="120" r="6" fill="#0E5B4B" />
                    </svg>

                    {deals.map((deal, idx) => {
                      const pos = [
                        { top: '35%', left: '65%' },
                        { top: '60%', left: '30%' },
                        { top: '20%', left: '80%' }
                      ][idx % 3];

                      return (
                        <button
                          key={deal.id}
                          onClick={() => setSelectedVendorForRoute(deal.vendor)}
                          style={{
                            position: 'absolute',
                            ...pos,
                            backgroundColor: '#E76F51',
                            color: '#FFFFFF',
                            border: '2px solid #FFFFFF',
                            padding: '6px 10px',
                            borderRadius: '999px',
                            fontWeight: 800,
                            fontSize: '11px',
                            boxShadow: '0 4px 12px rgba(0,0,0,0.2)',
                            cursor: 'pointer',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '4px'
                          }}
                        >
                          <MapPin size={12} />
                          {deal.vendor?.name?.split(' ')[0]}
                        </button>
                      );
                    })}
                  </div>

                  {/* Store List with Real Route Buttons */}
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                    {deals.map(deal => (
                      <div
                        key={deal.id}
                        className="paper-card"
                        style={{
                          padding: '14px 16px',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'space-between'
                        }}
                      >
                        <div>
                          <div style={{ fontWeight: 700, fontSize: '15px' }}>{deal.vendor?.name}</div>
                          <div style={{ fontSize: '12px', color: '#6B6358' }}>
                            {deal.vendor?.shop_category} • 450m from you
                          </div>
                        </div>
                        <button
                          className="btn-primary"
                          style={{ padding: '8px 14px', fontSize: '12px' }}
                          onClick={() => setSelectedVendorForRoute(deal.vendor)}
                        >
                          <Footprints size={14} /> Real Route
                        </button>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* --- TAB 3: MY PASSES --- */}
              {activeTab === 'passes' && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                  <div className="paper-card" style={{ padding: '18px' }}>
                    <div className="pill-badge pill-teal" style={{ marginBottom: '8px' }}>
                      <Ticket size={12} /> Digital Food Rescues
                    </div>
                    <h2 className="serif-heading" style={{ fontSize: '20px' }}>
                      Active Pickup Passes
                    </h2>
                    <p style={{ fontSize: '13px', color: '#6B6358', marginTop: '2px' }}>
                      Show this pass at store counter. Once verified, food waste is avoided!
                    </p>
                  </div>

                  {myOrders.length === 0 ? (
                    <div className="paper-card" style={{ padding: '32px', textAlign: 'center' }}>
                      <p style={{ color: '#6B6358', fontSize: '14px' }}>No active passes yet.</p>
                      <button 
                        className="btn-primary" 
                        style={{ marginTop: '14px' }}
                        onClick={() => setActiveTab('discover')}
                      >
                        Explore Mystery Boxes
                      </button>
                    </div>
                  ) : (
                    myOrders.map(order => (
                      <div key={order.pickup_code} className="ticket-pass" style={{ padding: '20px' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <div>
                            <span className="pill-badge pill-teal" style={{ marginBottom: '4px' }}>
                              Ready for Pickup
                            </span>
                            <h3 className="serif-heading" style={{ fontSize: '18px' }}>
                              {order.vendor_name}
                            </h3>
                          </div>
                          <div style={{ textAlign: 'right' }}>
                            <div style={{ fontSize: '18px', fontWeight: 800, color: '#0E5B4B' }}>
                              ₹{order.paid_price}
                            </div>
                            <div style={{ fontSize: '11px', color: '#6B6358' }}>
                              Saved ₹{order.savings}
                            </div>
                          </div>
                        </div>

                        {/* Ticket Divider */}
                        <div className="ticket-divider">
                          <div className="ticket-dashed-line" />
                        </div>

                        {/* Code & Actions */}
                        <div style={{
                          backgroundColor: '#FAF7F0',
                          padding: '12px',
                          borderRadius: '14px',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'space-between',
                          border: '1px solid #E6DFD1'
                        }}>
                          <div>
                            <div style={{ fontSize: '10px', textTransform: 'uppercase', color: '#9B9387', fontWeight: 800 }}>
                              Passcode
                            </div>
                            <div style={{
                              fontFamily: 'var(--font-mono)',
                              fontSize: '18px',
                              fontWeight: 800,
                              color: '#0E5B4B',
                              letterSpacing: '1.5px'
                            }}>
                              {order.pickup_code}
                            </div>
                          </div>
                          <button
                            className="btn-secondary"
                            style={{ padding: '8px 12px', fontSize: '12px' }}
                            onClick={() => setSelectedVendorForRoute({ name: order.vendor_name, latitude: order.latitude, longitude: order.longitude })}
                          >
                            <Footprints size={14} /> Walk Route
                          </button>
                        </div>
                      </div>
                    ))
                  )}
                </div>
              )}
            </>
          )}
        </main>

        {/* --- BOTTOM NAVIGATION BAR (STUDENT ONLY) --- */}
        {role === 'student' && (
          <nav style={{
            position: 'absolute',
            bottom: 0,
            left: 0,
            right: 0,
            backgroundColor: '#FFFFFF',
            borderTop: '1.5px solid #E6DFD1',
            display: 'flex',
            justifyContent: 'space-around',
            padding: '10px 0 14px',
            boxShadow: '0 -4px 16px rgba(45, 38, 28, 0.04)'
          }}>
            {[
              { id: 'discover', label: 'Discover', icon: Compass },
              { id: 'map', label: 'Campus Map', icon: Map },
              { id: 'passes', label: 'My Passes', icon: Ticket }
            ].map(tab => {
              const Icon = tab.icon;
              const isActive = activeTab === tab.id;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  style={{
                    background: 'none',
                    border: 'none',
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    gap: '4px',
                    color: isActive ? '#0E5B4B' : '#9B9387',
                    fontWeight: isActive ? 800 : 600,
                    fontSize: '11px',
                    cursor: 'pointer',
                    padding: '4px 16px',
                    transition: 'color 0.15s ease'
                  }}
                >
                  <Icon size={20} color={isActive ? '#0E5B4B' : '#9B9387'} />
                  {tab.label}
                </button>
              );
            })}
          </nav>
        )}

        {/* --- MODAL DIALOGS --- */}
        {selectedDealForCheckout && (
          <CheckoutModal
            deal={selectedDealForCheckout}
            onClose={() => setSelectedDealForCheckout(null)}
            onOrderPlaced={handleOrderPlaced}
          />
        )}

        {selectedVendorForRoute && (
          <RouteNavigationModal
            vendor={selectedVendorForRoute}
            onClose={() => setSelectedVendorForRoute(null)}
          />
        )}
      </div>
    </div>
  );
}
