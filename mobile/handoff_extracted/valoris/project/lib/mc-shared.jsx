// ───────────────────────────────────────────────
// MyCabinet shared design system
// ───────────────────────────────────────────────

const T = {
  bg:      '#FAFAF9',
  bgSunk:  '#F4F3F0',
  card:    '#FFFFFF',
  text:    '#1A1A1A',
  text2:   '#6B6B6B',
  text3:   '#9CA3AF',
  brand:   '#1E3A5F',
  brandH:  '#172E4B',
  brandT:  '#EEF2F7',  // tinted brand background
  amber:   '#D97706',
  amberT:  '#FEF6EC',
  green:   '#059669',
  greenT:  '#ECFDF5',
  red:     '#DC2626',
  redT:    '#FEF2F2',
  gray:    '#9CA3AF',
  border:  '#EEEDEB',
  borderS: '#E5E5E4',
  tint:    '#F4F3F0',
};

// ───────────────────────────────────────────────
// Logo mark
// ───────────────────────────────────────────────
function Logo({ size = 32 }) {
  const r = size * 0.24;
  return (
    <div style={{
      width: size, height: size, borderRadius: r, background: T.brand,
      position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'center',
      flexShrink: 0,
    }}>
      <svg width={size*0.46} height={size*0.46} viewBox="0 0 24 24" fill="none">
        <rect x="3"  y="4"  width="18" height="2.4" rx="1.2" fill="#fff" opacity="0.95"/>
        <rect x="3"  y="10.8" width="18" height="2.4" rx="1.2" fill="#fff" opacity="0.6"/>
        <rect x="3"  y="17.6" width="11" height="2.4" rx="1.2" fill="#fff" opacity="0.35"/>
      </svg>
      <div style={{
        position: 'absolute', top: -2, right: -2,
        width: size*0.24, height: size*0.24, borderRadius: '50%',
        background: T.amber, border: `${Math.max(2, size*0.04)}px solid ${T.bg}`,
      }} />
    </div>
  );
}

// ───────────────────────────────────────────────
// Avatar
// ───────────────────────────────────────────────
function Avatar({ name = 'Marie Martin', size = 36 }) {
  const initials = name.split(' ').map(n => n[0]).slice(0,2).join('');
  return (
    <div style={{
      width: size, height: size, borderRadius: '50%',
      background: '#E8DFD2',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontSize: size*0.4, fontWeight: 600, color: '#73593B',
      letterSpacing: -0.2, flexShrink: 0,
    }}>{initials}</div>
  );
}

// ───────────────────────────────────────────────
// Status pill — green (done), amber (urgent), red (late), gray (upcoming), brand (info)
// ───────────────────────────────────────────────
function Pill({ tone = 'gray', children, dot = true }) {
  const tones = {
    green: { fg: T.green, bg: T.greenT },
    amber: { fg: T.amber, bg: T.amberT },
    red:   { fg: T.red,   bg: T.redT },
    gray:  { fg: T.text2, bg: T.bgSunk },
    brand: { fg: T.brand, bg: T.brandT },
  };
  const c = tones[tone];
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 5,
      padding: '3px 9px', borderRadius: 999,
      fontSize: 11, fontWeight: 600, color: c.fg, background: c.bg,
      letterSpacing: 0.1, lineHeight: 1.4, whiteSpace: 'nowrap',
    }}>
      {dot && <span style={{ width: 5, height: 5, borderRadius: '50%', background: c.fg }} />}
      {children}
    </span>
  );
}

// ───────────────────────────────────────────────
// Icons — Lucide-style, line, 1.7 stroke
// ───────────────────────────────────────────────
function Icon({ name, size = 20, color = 'currentColor', strokeWidth = 1.7 }) {
  const common = {
    width: size, height: size, viewBox: '0 0 24 24', fill: 'none',
    stroke: color, strokeWidth, strokeLinecap: 'round', strokeLinejoin: 'round',
  };
  const paths = {
    home:        <><path d="M3 11l9-8 9 8"/><path d="M5 10v10h14V10"/></>,
    folder:      <><path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V7z"/></>,
    calendar:    <><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 10h18M8 3v4M16 3v4"/></>,
    sparkles:    <><path d="M12 4l1.5 4L18 9.5l-4.5 1.5L12 15l-1.5-4.5L6 9.5 10.5 8z"/><path d="M18 16l.7 1.8L20.5 18l-1.8.7L18 20.5l-.7-1.8L15.5 18l1.8-.7z"/></>,
    chevR:       <><path d="M9 18l6-6-6-6"/></>,
    chevL:       <><path d="M15 18l-6-6 6-6"/></>,
    chevD:       <><path d="M6 9l6 6 6-6"/></>,
    chevU:       <><path d="M18 15l-6-6-6 6"/></>,
    search:      <><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></>,
    filter:      <><path d="M3 5h18l-7 9v6l-4-2v-4z"/></>,
    plus:        <><path d="M12 5v14M5 12h14"/></>,
    bell:        <><path d="M6 8a6 6 0 0 1 12 0c0 7 3 8 3 8H3s3-1 3-8"/><path d="M10 21h4"/></>,
    file:        <><path d="M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"/><path d="M14 3v6h6"/></>,
    fileText:    <><path d="M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"/><path d="M14 3v6h6M8 13h8M8 17h6"/></>,
    receipt:     <><path d="M5 3v18l3-2 2 2 2-2 2 2 2-2 3 2V3z"/><path d="M9 8h6M9 12h6M9 16h4"/></>,
    check:       <><path d="M5 12l5 5L20 7"/></>,
    checkCircle: <><circle cx="12" cy="12" r="9"/><path d="M8 12l3 3 5-6"/></>,
    alert:       <><path d="M12 9v4M12 17h.01"/><circle cx="12" cy="12" r="9"/></>,
    x:           <><path d="M6 6l12 12M18 6L6 18"/></>,
    eye:         <><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/></>,
    mic:         <><rect x="9" y="3" width="6" height="12" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/></>,
    send:        <><path d="M21 3L3 11l7 3 3 7z"/></>,
    arrowUp:     <><path d="M12 19V5M5 12l7-7 7 7"/></>,
    upload:      <><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><path d="M17 8l-5-5-5 5M12 3v12"/></>,
    camera:      <><path d="M3 8h4l2-3h6l2 3h4v12H3z"/><circle cx="12" cy="13" r="4"/></>,
    image:       <><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="9" cy="9" r="2"/><path d="M21 15l-5-5-9 9"/></>,
    lock:        <><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></>,
    user:        <><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></>,
    settings:    <><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1A1.7 1.7 0 0 0 4.6 9a1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/></>,
    thumbsUp:    <><path d="M7 22V11M2 13v7a2 2 0 0 0 2 2h13.5a2 2 0 0 0 2-1.7l1.4-9A2 2 0 0 0 19 9h-5.5L15 4a2 2 0 0 0-2-2L7 11"/></>,
    thumbsDown:  <><path d="M17 2v11M22 11V4a2 2 0 0 0-2-2H6.5a2 2 0 0 0-2 1.7L3.1 12.7A2 2 0 0 0 5 15h5.5L9 20a2 2 0 0 0 2 2l6-9"/></>,
    refresh:     <><path d="M21 12a9 9 0 1 1-3-6.7L21 8"/><path d="M21 3v5h-5"/></>,
    clock:       <><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></>,
    building:    <><rect x="4" y="3" width="16" height="18" rx="1"/><path d="M9 8h2M9 12h2M9 16h2M13 8h2M13 12h2M13 16h2"/></>,
    logout:      <><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"/></>,
    grid:        <><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/></>,
    list:        <><path d="M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01"/></>,
    trash:       <><path d="M3 6h18M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/></>,
    edit:        <><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.4 2.6a2 2 0 0 1 2.8 2.8L12 14.6l-4 1 1-4z"/></>,
    info:        <><circle cx="12" cy="12" r="9"/><path d="M12 16v-4M12 8h.01"/></>,
    link:        <><path d="M10 13a5 5 0 0 0 7.1.1l3-3a5 5 0 0 0-7.1-7.1l-1.7 1.7"/><path d="M14 11a5 5 0 0 0-7.1-.1l-3 3a5 5 0 0 0 7.1 7.1l1.7-1.7"/></>,
    chat:        <><path d="M21 11.5a8.4 8.4 0 0 1-9 8.4 8.4 8.4 0 0 1-3.8-.9L3 21l1.9-5.1A8.4 8.4 0 0 1 12 3a8.4 8.4 0 0 1 9 8.5z"/></>,
  };
  return <svg {...common}>{paths[name]}</svg>;
}

// ───────────────────────────────────────────────
// Bottom nav
// ───────────────────────────────────────────────
function BottomNav({ active = 'home' }) {
  const items = [
    { key: 'home',     label: 'Accueil',    icon: 'home' },
    { key: 'docs',     label: 'Documents',  icon: 'folder' },
    { key: 'cal',      label: 'Calendrier', icon: 'calendar' },
    { key: 'agent',    label: 'Assistant',  icon: 'sparkles' },
  ];
  return (
    <div style={{
      borderTop: `1px solid ${T.border}`, background: 'rgba(250,250,249,0.92)',
      backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
      padding: '8px 0 28px',
      display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)',
    }}>
      {items.map(it => {
        const isActive = it.key === active;
        const color = isActive ? T.brand : T.text3;
        return (
          <div key={it.key} style={{
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
            paddingTop: 4,
          }}>
            <Icon name={it.icon} size={22} color={color} strokeWidth={isActive ? 2 : 1.6}/>
            <span style={{
              fontSize: 10.5, fontWeight: isActive ? 600 : 500, color,
              letterSpacing: 0.1,
            }}>{it.label}</span>
          </div>
        );
      })}
    </div>
  );
}

// ───────────────────────────────────────────────
// Status bar — simplified, drawn-in (matches iOS frame styling)
// We rely on IOSDevice for the chrome; this is for top-of-content spacing.
// ───────────────────────────────────────────────
function TopSafeArea() {
  return <div style={{ height: 60 }} />;
}

// expose
Object.assign(window, { T, Logo, Avatar, Pill, Icon, BottomNav, TopSafeArea });
