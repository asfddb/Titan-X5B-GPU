import React, { useEffect, useState } from 'react';
import './index.css';

function App() {
  const [scrollY, setScrollY] = useState(0);

  useEffect(() => {
    const handleScroll = () => setScrollY(window.scrollY);
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  return (
    <>
      <nav className="navbar">
        <div className="container">
          <div className="nav-brand">TITAN<span className="gradient-text">X5</span></div>
          <div className="nav-links">
            <a href="#overview" className="nav-link">Overview</a>
            <a href="#features" className="nav-link">Features</a>
            <a href="#specs" className="nav-link">Specs</a>
          </div>
        </div>
      </nav>

      <section className="hero" id="overview">
        <div className="container" style={{ display: 'flex', flexWrap: 'wrap', alignItems: 'center' }}>
          <div className="hero-content">
            <h1 className="hero-title">
              Defy Gravity.<br/>
              <span className="gradient-text">Embrace the Future.</span>
            </h1>
            <p className="hero-subtitle">
              The Titan X5 is an ultra-premium quadcopter drone engineered for cinematic brilliance and unparalleled speed. Experience 8K recording and aerospace-grade aerodynamics.
            </p>
            <div>
              <a href="#preorder" className="btn btn-primary">Pre-Order Now</a>
              <a href="#features" className="btn btn-secondary">Explore Features</a>
            </div>
          </div>
          <div className="hero-image-container">
            <img 
              src="/titan_x5.png" 
              alt="Titan X5 Drone" 
              className="hero-image"
              style={{ transform: `translateY(${scrollY * 0.1}px)` }} 
            />
          </div>
        </div>
      </section>

      <section className="features" id="features">
        <div className="container">
          <h2 className="section-title">Beyond <span className="gradient-text">Expectations</span></h2>
          <div className="features-grid">
            <div className="feature-card">
              <div className="feature-icon">❖</div>
              <h3 className="feature-title">8K Cinematic Camera</h3>
              <p className="feature-desc">Capture breathtaking footage with our state-of-the-art 8K 60fps sensor and 3-axis mechanical gimbal stabilization.</p>
            </div>
            <div className="feature-card">
              <div className="feature-icon">⚡</div>
              <h3 className="feature-title">HyperDrive Motors</h3>
              <p className="feature-desc">Reach speeds up to 120km/h in just 2.5 seconds with zero-latency transmission and carbon-fiber reinforced blades.</p>
            </div>
            <div className="feature-card">
              <div className="feature-icon">◎</div>
              <h3 className="feature-title">AI Omni-Sense</h3>
              <p className="feature-desc">Fly with complete confidence. 360-degree obstacle avoidance powered by our advanced neural-net vision system.</p>
            </div>
          </div>
        </div>
      </section>

      <section className="specs" id="specs">
        <div className="container">
          <div className="specs-wrapper">
            <div className="hero-image-container">
              {/* Reuse the image but with different styling or just text */}
              <img src="/titan_x5.png" alt="Titan X5 Detailed" style={{ width: '100%', filter: 'brightness(0.7) sepia(1) hue-rotate(180deg) saturate(3)' }} />
            </div>
            <div className="specs-info">
              <h2 style={{ fontSize: '2.5rem', marginBottom: '1rem' }}>Technical <span className="gradient-text">Specifications</span></h2>
              <p style={{ color: '#888', marginBottom: '2rem' }}>Aerospace materials meet next-generation computing.</p>
              
              <ul className="specs-list">
                <li>
                  <span className="specs-label">Top Speed</span>
                  <span className="specs-value">120 km/h</span>
                </li>
                <li>
                  <span className="specs-label">Max Flight Time</span>
                  <span className="specs-value">45 Minutes</span>
                </li>
                <li>
                  <span className="specs-label">Camera Sensor</span>
                  <span className="specs-value">1" CMOS 48MP</span>
                </li>
                <li>
                  <span className="specs-label">Transmission Range</span>
                  <span className="specs-value">15 km (O3+)</span>
                </li>
                <li>
                  <span className="specs-label">Weight</span>
                  <span className="specs-value">895 g</span>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </section>
      
      <footer style={{ padding: '3rem 0', textAlign: 'center', borderTop: '1px solid rgba(255,255,255,0.1)', marginTop: '5rem' }}>
        <p style={{ color: '#555', fontSize: '0.9rem' }}>© 2026 Titan Aerospace. All rights reserved.</p>
      </footer>
    </>
  );
}

export default App;
