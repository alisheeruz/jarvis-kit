// Motion-dizayn to'plami. Hamma vaqtlar SONIYADA. Har element <At from to> ichida yashaydi.
// Element ichida useT() — shu elementning boshidan o'tgan soniya va qolgan soniya.
import React, {createContext, useContext} from 'react';
import {AbsoluteFill, Sequence, OffthreadVideo, Img, staticFile, useCurrentFrame, useVideoConfig, interpolate, spring, Easing} from 'remotion';
import {loadFont as loadOnest} from '@remotion/google-fonts/Onest';
import {loadFont as loadAnton} from '@remotion/google-fonts/Anton';
import {loadFont as loadSerif} from '@remotion/google-fonts/InstrumentSerif';

const body = loadOnest('normal', {weights: ['400', '500', '600', '700'], subsets: ['latin', 'latin-ext', 'cyrillic']}).fontFamily;
const display = loadAnton('normal', {weights: ['400'], subsets: ['latin', 'latin-ext']}).fontFamily;
const serif = loadSerif('italic', {weights: ['400'], subsets: ['latin', 'latin-ext']}).fontFamily;
export const FONT = {body, display, serif};

// ---------- MAVZULAR (har video bitta mavzuda) ----------
export const THEMES = {
  // 1-ref: och fon, laym urg'u, yumaloq plashka
  lime: {accent: '#b6e36a', accent2: '#7fb82e', ink: '#141a10', paper: '#f5fbf4', paper2: '#dff3c8', pillBg: '#cdeea0', pillInk: '#2f4d12', pillRadius: 40, glow: '#c8ff6a'},
  // 9-ref: ko'k "shisha" to'rtburchak plashka
  blue: {accent: '#3b82f6', accent2: '#0b3fae', ink: '#ffffff', paper: '#0e2f6e', paper2: '#1d5fd6', pillBg: 'linear-gradient(90deg,#0b2a7a,#2f6fe0)', pillInk: '#ffffff', pillRadius: 4, glow: '#6fb1ff'},
  // 7-ref: qizil-oq jurnal uslubi
  red: {accent: '#d21f2b', accent2: '#7c0d14', ink: '#ffffff', paper: '#120607', paper2: '#5a0b10', pillBg: '#d21f2b', pillInk: '#ffffff', pillRadius: 8, glow: '#ff4654'},
  // 4-ref: qog'oz eksplayner
  paper: {accent: '#d8392b', accent2: '#3f8f5a', ink: '#1b1b1b', paper: '#efe9d8', paper2: '#e3dbc3', pillBg: '#1b1b1b', pillInk: '#ffffff', pillRadius: 2, glow: '#f2c230'},
  // 6-ref: binafsha monoxrom kollaj
  violet: {accent: '#2a2380', accent2: '#6c63e6', ink: '#1c1663', paper: '#c9c8ff', paper2: '#6e66e8', pillBg: '#2a2380', pillInk: '#ffffff', pillRadius: 6, glow: '#b6b1ff'},
  // 2/8-ref: qorong'i UI
  dark: {accent: '#8ab4ff', accent2: '#a78bfa', ink: '#ffffff', paper: '#07070b', paper2: '#1b1c3a', pillBg: 'rgba(255,255,255,0.12)', pillInk: '#ffffff', pillRadius: 40, glow: '#9db8ff'},
};
const ThemeCtx = createContext(THEMES.lime);
export const Theme = ({name, children}) => <ThemeCtx.Provider value={THEMES[name] || name}>{children}</ThemeCtx.Provider>;
export const useTheme = () => useContext(ThemeCtx);

// ---------- VAQT ----------
const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'};
export const At = ({from, to, children, z}) => {
  const {fps} = useVideoConfig();
  const a = Math.round(from * fps);
  return (
    <Sequence from={a} durationInFrames={Math.max(1, Math.round(to * fps) - a)} style={z != null ? {zIndex: z} : undefined}>
      {children}
    </Sequence>
  );
};
export const useT = () => {
  const f = useCurrentFrame();
  const {fps, durationInFrames} = useVideoConfig();
  return {t: f / fps, left: (durationInFrames - f) / fps, f, fps};
};
// Kirish: "pop" (0 -> 1.08 -> 1). Chiqish: oxirgi 0.15s da eriydi.
export const usePop = (delay = 0, out = 0.15) => {
  const {t, left, f, fps} = useT();
  const s = spring({frame: f - delay * fps, fps, config: {damping: 13, stiffness: 190, mass: 0.6}});
  const o = interpolate(left, [0, out], [0, 1], clamp);
  return {scale: s, opacity: Math.min(1, s * 1.4) * o, t};
};
export const ease = (t, t0, t1, v0, v1) => interpolate(t, [t0, t1], [v0, v1], {...clamp, easing: Easing.inOut(Easing.cubic)});

// ---------- ASOSIY VIDEO ----------
// punches: [{t, s, x, y, smooth}] — t soniyadan boshlab masshtab s va surilish x,y (px). smooth: shu holatga necha soniyada silliq o'tish
// (berilmasa keskin "zoom-kesim"). dim: [[from, to, kuch]] — matn o'qilishi uchun kadrni qoraytirish.
export const Footage = ({src, punches = [], dim = [], startFrom = 0, style}) => {
  const {t, fps} = useT();
  let cur = {s: 1, x: 0, y: 0};
  for (const p of punches) {
    if (t < p.t) break;
    const target = {s: p.s ?? 1, x: p.x ?? 0, y: p.y ?? 0};
    if (p.smooth) {
      const k = ease(t, p.t, p.t + p.smooth, 0, 1);
      cur = {s: cur.s + (target.s - cur.s) * k, x: cur.x + (target.x - cur.x) * k, y: cur.y + (target.y - cur.y) * k};
    } else cur = target;
  }
  const breathe = 1 + 0.012 * Math.sin(t / 2.3); // kadr hech qachon to'liq qotmaydi
  let d = 0;
  for (const [a, b, k = 0.45] of dim) d = Math.max(d, k * Math.min(ease(t, a, a + 0.25, 0, 1), ease(t, b - 0.25, b, 1, 0)));
  return (
    <AbsoluteFill style={{backgroundColor: '#000', ...style}}>
      <OffthreadVideo
        src={staticFile(src)}
        startFrom={Math.round(startFrom * fps)}
        style={{width: '100%', height: '100%', objectFit: 'cover', transform: `scale(${cur.s * breathe}) translate(${cur.x}px, ${cur.y}px)`}}
      />
      <AbsoluteFill style={{backgroundColor: `rgba(0,0,0,${d})`}} />
    </AbsoluteFill>
  );
};

// Odam kesimi (alfa-kanalli video, scripts/matte.sh yasaydi). Undan OLDIN yozilgan elementlar odam ORQASIDA qoladi.
// from — matte fayli asosiy videoning nechanchi soniyasidan boshlangani; punches Footage niki bilan bir xil bo'lsin.
export const Person = ({src = 'person.webm', punches = []}) => {
  const {t} = useT();
  let cur = {s: 1, x: 0, y: 0};
  for (const p of punches) if (t >= p.t && !p.smooth) cur = {s: p.s ?? 1, x: p.x ?? 0, y: p.y ?? 0};
  const breathe = 1 + 0.012 * Math.sin(t / 2.3);
  return (
    <AbsoluteFill>
      <OffthreadVideo transparent muted src={staticFile(src)} style={{width: '100%', height: '100%', objectFit: 'cover', transform: `scale(${cur.s * breathe}) translate(${cur.x}px, ${cur.y}px)`}} />
    </AbsoluteFill>
  );
};

// ---------- SUBTITR VA TIPOGRAFIKA ----------
// Plashka: 1-3 so'z, ko'krak balandligida (y≈1250). 1- va 9-ref subtitrlari shu.
export const Pill = ({text, y = 1250, x = 540, size = 58, upper = false}) => {
  const th = useTheme();
  const {scale, opacity} = usePop();
  return (
    <div style={{position: 'absolute', left: x, top: y, transform: `translate(-50%,-50%) scale(${0.7 + 0.3 * scale})`, opacity}}>
      <div style={{background: th.pillBg, color: th.pillInk, borderRadius: th.pillRadius, padding: `${size * 0.22}px ${size * 0.62}px`, fontFamily: body, fontWeight: 600, fontSize: size, letterSpacing: '-0.02em', whiteSpace: 'nowrap', textTransform: upper ? 'uppercase' : 'none', boxShadow: `0 0 ${size * 0.6}px ${th.glow}55, inset 0 1px 0 rgba(255,255,255,0.35)`}}>
        {text}
      </div>
    </div>
  );
};

// captions.json (bashar-uslub/scripts/align.py formati) dan avtomatik plashka-subtitr: har blok qatori = bitta plashka.
export const PillCaptions = ({captions, y = 1250, size = 58, skip = [], upper}) => (
  <>
    {captions.flatMap((c, ci) =>
      c.lines.map((line, li) => {
        const from = line[0].s;
        const nextLine = c.lines[li + 1];
        const to = nextLine ? nextLine[0].s : c.e;
        if (skip.some(([a, b]) => from >= a && from < b)) return null; // katta sarlavha yoki kesma sahna paytida subtitr o'chadi
        return (
          <At key={`${ci}-${li}`} from={from} to={to}>
            <Pill text={line.map((w) => w.t).join(' ')} y={y} size={size} upper={upper} />
          </At>
        );
      })
    )}
  </>
);

// Yirik so'z: tor bosh harfli shrift. small — ustidagi/ostidagi mayda izoh. Person dan oldin qo'yilsa odam orqasida qoladi.
export const BigWord = ({text, small, smallBelow = false, y = 620, x = 540, size = 230, color, glow = true, rotate = 0, script}) => {
  const th = useTheme();
  const {t, left} = useT();
  const k = ease(t, 0, 0.28, 0, 1);
  const o = interpolate(left, [0, 0.18], [0, 1], clamp);
  const sm = small && <div style={{fontFamily: body, fontWeight: 500, fontSize: size * 0.2, color: '#fff', opacity: 0.9, letterSpacing: '-0.01em', margin: `${size * 0.02}px 0`}}>{small}</div>;
  return (
    <div style={{position: 'absolute', left: x, top: y, transform: `translate(-50%,-50%) rotate(${rotate}deg) scale(${1.25 - 0.25 * k})`, opacity: k * o, filter: `blur(${(1 - k) * 14}px)`, textAlign: 'center', whiteSpace: 'nowrap'}}>
      {!smallBelow && sm}
      <div style={{fontFamily: display, fontSize: size, lineHeight: 0.95, color: color || th.accent, textTransform: 'uppercase', textShadow: glow ? `0 0 ${size * 0.25}px ${th.glow}99` : 'none'}}>{text}</div>
      {script && <div style={{fontFamily: serif, fontStyle: 'italic', fontSize: size * 0.42, color: '#fff', marginTop: -size * 0.16, transform: 'rotate(-5deg)'}}>{script}</div>}
      {smallBelow && sm}
    </div>
  );
};

// Bosma mashinka matni + miltillovchi kursor.
export const TypeLine = ({text, x = 120, y = 400, size = 64, color, speed = 22, weight = 500, center = false}) => {
  const th = useTheme();
  const {t} = useT();
  const n = Math.min(text.length, Math.floor(t * speed));
  return (
    <div style={{position: 'absolute', left: center ? 0 : x, right: center ? 0 : undefined, top: y, textAlign: center ? 'center' : 'left', fontFamily: body, fontWeight: weight, fontSize: size, letterSpacing: '-0.03em', color: color || th.ink, whiteSpace: 'pre'}}>
      {text.slice(0, n)}
      <span style={{opacity: Math.floor(t * 2.5) % 2 ? 0 : 1, fontWeight: 300}}>|</span>
    </div>
  );
};

// ---------- KESMA SAHNA (grafik ekran) ----------
// Gapiruvchi o'rniga 2-5 soniyaga to'liq ekranli grafik. Ichiga TypeLine, Card, Stat va h.k. qo'yiladi.
export const Cutaway = ({children, streaks = true}) => {
  const th = useTheme();
  const {t, left} = useT();
  const k = Math.min(ease(t, 0, 0.3, 0, 1), ease(left, 0, 0.25, 0, 1));
  return (
    <AbsoluteFill style={{opacity: k, filter: `blur(${(1 - k) * 18}px)`, transform: `scale(${1.06 - 0.06 * k})`}}>
      <AbsoluteFill style={{background: `radial-gradient(120% 80% at 70% 60%, ${th.paper2} 0%, ${th.paper} 65%)`}} />
      {streaks &&
        [0, 1, 2, 3, 4, 5, 6].map((i) => (
          <div key={i} style={{position: 'absolute', left: 620 + i * 62, top: 500 + ((i * 137) % 300) - t * 40, width: 26, height: 900, background: `linear-gradient(to bottom, transparent, ${th.accent}66, transparent)`, opacity: 0.5}} />
        ))}
      {children}
    </AbsoluteFill>
  );
};

// Yumaloq burchakli kartochka: delay soniyadan keyin "pop" bo'lib chiqadi, keyin sekin suzadi.
export const Card = ({x, y, w, h, delay = 0, children, bg = '#ffffff', radius = 36, rotate = 0, pad = 0, border}) => {
  const th = useTheme();
  const {scale, opacity, t} = usePop(delay);
  const float = Math.sin((t + x / 300) * 1.4) * 7;
  return (
    <div style={{position: 'absolute', left: x, top: y + float, width: w, height: h, transform: `scale(${0.6 + 0.4 * scale}) rotate(${rotate}deg)`, opacity, borderRadius: radius, background: bg, boxShadow: '0 30px 70px rgba(0,0,0,0.22), 0 4px 14px rgba(0,0,0,0.10)', overflow: 'hidden', padding: pad, boxSizing: 'border-box', border: border ?? `2px solid ${th.accent}88`}}>
      {children}
    </div>
  );
};

// Kartochka ichidagi rasm/video (b-roll, skrinshot). src — public/ ichidagi fayl.
export const Media = ({src, zoom = 1.12}) => {
  const {t} = useT();
  const st = {width: '100%', height: '100%', objectFit: 'cover', transform: `scale(${1 + (zoom - 1) * Math.min(1, t / 4)})`};
  return /\.(mp4|mov|webm)$/i.test(src) ? <OffthreadVideo muted src={staticFile(src)} style={st} /> : <Img src={staticFile(src)} style={st} />;
};

// Qidiruv/chat qatori: matn teriladi, o'ngda yuborish tugmasi.
export const SearchBar = ({text, x = 140, y = 800, w = 800, delay = 0}) => {
  const th = useTheme();
  const {scale, opacity, t} = usePop(delay);
  const n = Math.max(0, Math.min(text.length, Math.floor((t - delay - 0.25) * 20)));
  const sent = t - delay > 0.4 + text.length / 20;
  return (
    <div style={{position: 'absolute', left: x, top: y, width: w, height: 132, transform: `scale(${0.8 + 0.2 * scale})`, opacity, borderRadius: 40, background: '#fff', boxShadow: `0 24px 60px rgba(0,0,0,0.18), 0 0 0 2px ${th.accent}66`, display: 'flex', alignItems: 'center', padding: '0 26px 0 44px', boxSizing: 'border-box', fontFamily: body, fontSize: 44, fontWeight: 500, color: '#1a1a1a', letterSpacing: '-0.02em'}}>
      <div style={{flex: 1, whiteSpace: 'nowrap', overflow: 'hidden'}}>{text.slice(0, n)}<span style={{opacity: Math.floor(t * 2.5) % 2 ? 0 : 1}}>|</span></div>
      <div style={{width: 84, height: 84, borderRadius: 42, background: th.accent2, transform: `scale(${sent ? 0.86 : 1})`, display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontSize: 46}}>↑</div>
    </div>
  );
};

// Katta raqam: 0 dan value gacha sanab chiqadi. prefix/suffix: "$", "%", " mln".
export const Stat = ({value, prefix = '', suffix = '', label, x = 540, y = 700, size = 220, decimals = 0, color, dur = 0.9}) => {
  const th = useTheme();
  const {scale, opacity, t} = usePop();
  const v = value * ease(t, 0.05, dur, 0, 1);
  const txt = v.toFixed(decimals).replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
  return (
    <div style={{position: 'absolute', left: x, top: y, transform: `translate(-50%,-50%) scale(${0.85 + 0.15 * scale})`, opacity, textAlign: 'center', whiteSpace: 'nowrap'}}>
      <div style={{fontFamily: body, fontWeight: 700, fontSize: size, letterSpacing: '-0.05em', color: color || th.ink, lineHeight: 1}}>{prefix}{txt}{suffix}</div>
      {label && <div style={{fontFamily: body, fontWeight: 500, fontSize: size * 0.24, color: color || th.ink, opacity: 0.8, marginTop: size * 0.1}}>{label}</div>}
    </div>
  );
};

// Ism kartochkasi (oxirgi chaqiriq yoki tanishtirish): avatar + ism + izoh + tugma.
export const NameCard = ({name, handle, button, avatar, x = 540, y = 1380, w = 620}) => {
  const th = useTheme();
  const {scale, opacity} = usePop();
  return (
    <div style={{position: 'absolute', left: x, top: y, width: w, transform: `translate(-50%,-50%) scale(${0.7 + 0.3 * scale})`, opacity, background: 'rgba(255,255,255,0.94)', borderRadius: 40, padding: 30, boxSizing: 'border-box', fontFamily: body, boxShadow: `0 30px 80px rgba(0,0,0,0.35), 0 0 0 3px ${th.accent}`}}>
      <div style={{display: 'flex', alignItems: 'center', gap: 22}}>
        <div style={{width: 92, height: 92, borderRadius: 46, background: th.accent, overflow: 'hidden', flexShrink: 0}}>{avatar && <Img src={staticFile(avatar)} style={{width: '100%', height: '100%', objectFit: 'cover'}} />}</div>
        <div>
          <div style={{fontSize: 40, fontWeight: 700, color: '#151515', letterSpacing: '-0.02em'}}>{name}</div>
          {handle && <div style={{fontSize: 28, color: '#666'}}>{handle}</div>}
        </div>
      </div>
      {button && <div style={{marginTop: 24, background: th.accent, color: th.pillInk, borderRadius: 24, textAlign: 'center', padding: '18px 0', fontSize: 34, fontWeight: 600}}>{button}</div>}
    </div>
  );
};

// Sichqoncha kursori: from -> to nuqtaga boradi va bosadi (kichrayib-qaytadi).
export const Cursor = ({from: a, to: b, delay = 0, dur = 0.6}) => {
  const {t} = useT();
  const k = ease(t, delay, delay + dur, 0, 1);
  const click = ease(t, delay + dur, delay + dur + 0.1, 1, 0.8) + ease(t, delay + dur + 0.1, delay + dur + 0.22, 0, 0.2);
  return (
    <svg width={64} height={64} viewBox="0 0 24 24" style={{position: 'absolute', left: a[0] + (b[0] - a[0]) * k, top: a[1] + (b[1] - a[1]) * k, transform: `scale(${click})`, opacity: ease(t, delay - 0.15, delay, 0, 1), filter: 'drop-shadow(0 4px 6px rgba(0,0,0,0.35))'}}>
      <path d="M4 2 L4 19 L8.5 15 L11.5 22 L14.5 20.7 L11.6 14 L18 14 Z" fill="#fff" stroke="#111" strokeWidth={1.3} strokeLinejoin="round" />
    </svg>
  );
};

// ---------- EKSPLAYNER (yuzsiz tushuntirish, 4- va 6-ref) ----------
// Qog'oz fon: mayda katak va chetlari qoraygan.
export const PaperBg = ({color, rays = false}) => {
  const th = useTheme();
  const {t} = useT();
  const c = color || th.paper;
  return (
    <AbsoluteFill style={{backgroundColor: c}}>
      {rays && <AbsoluteFill style={{background: `repeating-conic-gradient(from ${t * 4}deg at 50% 45%, rgba(255,255,255,0.16) 0deg 9deg, transparent 9deg 18deg)`}} />}
      <AbsoluteFill style={{backgroundImage: 'radial-gradient(rgba(0,0,0,0.07) 1.2px, transparent 1.2px)', backgroundSize: '14px 14px'}} />
      <AbsoluteFill style={{background: 'radial-gradient(90% 70% at 50% 45%, transparent 55%, rgba(0,0,0,0.22) 100%)'}} />
    </AbsoluteFill>
  );
};

// Yirtilgan qog'oz yorlig'i: sarlavha ("1-TUZOQ", "YECHIM"). tilt — qiyalik.
export const Tape = ({text, x = 540, y = 220, size = 96, bg, color = '#fff', tilt = -2, delay = 0}) => {
  const th = useTheme();
  const {scale, opacity} = usePop(delay);
  return (
    <div style={{position: 'absolute', left: x, top: y, transform: `translate(-50%,-50%) rotate(${tilt}deg) scale(${1.5 - 0.5 * scale})`, opacity}}>
      <div style={{background: bg || th.accent, color, fontFamily: display, fontSize: size, lineHeight: 1, padding: `${size * 0.16}px ${size * 0.34}px ${size * 0.1}px`, textTransform: 'uppercase', whiteSpace: 'nowrap', clipPath: 'polygon(1% 6%, 12% 0, 30% 5%, 52% 1%, 74% 6%, 99% 2%, 100% 92%, 82% 100%, 60% 95%, 38% 100%, 15% 94%, 0 98%)', boxShadow: '0 8px 18px rgba(0,0,0,0.25)'}}>
        {text}
      </div>
    </div>
  );
};

// Stiker: public/ ichidagi shaffof PNG (ai-broll/scripts/sticker.py chiqargan). "Pop" bo'lib chiqadi, sekin tebranadi.
export const Sticker = ({src, x, y, h = 700, delay = 0, flip = false, wobble = 1.5}) => {
  const {scale, opacity, t} = usePop(delay);
  return (
    <Img src={staticFile(src)} style={{position: 'absolute', left: x, top: y, height: h, transform: `translate(-50%,-100%) scale(${(flip ? -1 : 1) * (0.5 + 0.5 * scale)}, ${0.5 + 0.5 * scale}) rotate(${Math.sin(t * 1.7) * wobble}deg)`, transformOrigin: '50% 100%', opacity, filter: 'drop-shadow(0 14px 18px rgba(0,0,0,0.3))'}} />
  );
};

// Qog'oz varaqdagi grafik. series: [{label, color, points: [[x,y]...], step}] — x,y 0..1 oralig'ida. Chiziqlar navbat bilan chizilib chiqadi.
export const Chart = ({x = 110, y = 560, w = 860, h = 620, series, title, delay = 0}) => {
  const {scale, opacity, t} = usePop(delay);
  const P = 70;
  return (
    <div style={{position: 'absolute', left: x, top: y, width: w, height: h, transform: `rotate(-1deg) scale(${0.85 + 0.15 * scale})`, opacity, background: '#f8f5ea', boxShadow: '0 16px 34px rgba(0,0,0,0.28)', backgroundImage: 'linear-gradient(rgba(0,0,0,0.07) 1px, transparent 1px), linear-gradient(90deg, rgba(0,0,0,0.07) 1px, transparent 1px)', backgroundSize: '34px 34px'}}>
      {title && <div style={{position: 'absolute', left: P, top: 22, fontFamily: body, fontWeight: 700, fontSize: 30, color: '#222', letterSpacing: '0.04em'}}>{title}</div>}
      <svg width={w} height={h} style={{position: 'absolute', inset: 0}}>
        <path d={`M ${P} ${P} L ${P} ${h - P} L ${w - P / 2} ${h - P}`} fill="none" stroke="#222" strokeWidth={4} />
        {series.map((s, i) => {
          const pts = s.points.map(([px, py]) => [P + px * (w - 1.6 * P), h - P - py * (h - 2 * P)]);
          let d = `M ${pts[0][0]} ${pts[0][1]}`;
          for (let j = 1; j < pts.length; j++) d += s.step ? ` L ${pts[j][0]} ${pts[j - 1][1]} L ${pts[j][0]} ${pts[j][1]}` : ` L ${pts[j][0]} ${pts[j][1]}`;
          const p = ease(t, delay + 0.3 + i * 0.9, delay + 1.2 + i * 0.9, 0, 1);
          const last = pts[pts.length - 1];
          return (
            <g key={i}>
              <path d={d} fill="none" stroke={s.color} strokeWidth={8} strokeLinejoin="round" strokeLinecap="round" pathLength={1} strokeDasharray={1} strokeDashoffset={1 - p} opacity={p > 0 ? 1 : 0} />
              <text x={Math.min(last[0], w - 260)} y={last[1] + (i % 2 ? 54 : -24)} fontFamily={body} fontWeight={700} fontSize={34} fill={s.color} opacity={ease(t, delay + 1.0 + i * 0.9, delay + 1.3 + i * 0.9, 0, 1)}>{s.label}</text>
            </g>
          );
        })}
      </svg>
    </div>
  );
};

// Ustunli taqqoslash: bars: [{label, value, color, caption}] — eng katta qiymat to'liq balandlik.
export const Bars = ({x = 160, y = 520, w = 760, h = 640, bars, delay = 0, suffix = ''}) => {
  const {t} = useT();
  const max = Math.max(...bars.map((b) => b.value));
  const bw = (w / bars.length) * 0.56;
  return (
    <div style={{position: 'absolute', left: x, top: y, width: w, height: h, borderBottom: '5px solid #222'}}>
      {bars.map((b, i) => {
        const k = ease(t, delay + i * 0.5, delay + 0.7 + i * 0.5, 0, 1);
        const bh = (b.value / max) * (h - 110) * k;
        const cx = (w / bars.length) * (i + 0.5);
        return (
          <div key={i}>
            <div style={{position: 'absolute', left: cx - bw / 2, bottom: 0, width: bw, height: bh, background: b.color}} />
            <div style={{position: 'absolute', left: cx - 200, width: 400, bottom: bh + 14, textAlign: 'center', fontFamily: body, fontWeight: 700, fontSize: 60, color: '#1b1b1b', opacity: k, letterSpacing: '-0.03em'}}>{(b.value * k).toFixed(b.value % 1 ? 1 : 0)}{suffix}</div>
            <div style={{position: 'absolute', left: cx - 200, width: 400, bottom: -56, textAlign: 'center', fontFamily: body, fontWeight: 600, fontSize: 28, color: '#333'}}>{b.label}</div>
          </div>
        );
      })}
    </div>
  );
};

// Muhr: "NEGA?", "YECHIM" — tepadan urilib tushadi.
export const Stamp = ({text, x = 540, y = 900, size = 130, color, tilt = -8, delay = 0}) => {
  const th = useTheme();
  const {t} = useT();
  const k = ease(t, delay, delay + 0.14, 0, 1);
  const c = color || th.accent;
  return (
    <div style={{position: 'absolute', left: x, top: y, transform: `translate(-50%,-50%) rotate(${tilt}deg) scale(${2.4 - 1.4 * k})`, opacity: k, border: `10px solid ${c}`, color: c, fontFamily: display, fontSize: size, lineHeight: 1, padding: `${size * 0.14}px ${size * 0.3}px ${size * 0.06}px`, borderRadius: 14, textTransform: 'uppercase', whiteSpace: 'nowrap', background: 'rgba(255,255,255,0.35)'}}>
      {text}
    </div>
  );
};

// Kinetik qator: so'zlar birin-ketin chiqadi; [so'z, 'big'|'small'|'accent'] juftliklari. 6-ref tipografikasi.
export const Kinetic = ({words, x = 540, y = 400, size = 110, gap = 0.22, align = 'center', color}) => {
  const th = useTheme();
  const {t} = useT();
  return (
    <div style={{position: 'absolute', left: align === 'center' ? 0 : x, right: align === 'center' ? 0 : undefined, top: y, textAlign: align, lineHeight: 0.98}}>
      {words.map(([w, kind = 'big'], i) => {
        const k = ease(t, i * gap, i * gap + 0.2, 0, 1);
        const big = kind !== 'small';
        return (
          <span key={i} style={{display: kind === 'small' ? 'inline-block' : 'block', fontFamily: big ? display : serif, fontStyle: big ? 'normal' : 'italic', fontSize: big ? size : size * 0.34, color: kind === 'accent' ? th.accent2 : color || th.ink, textTransform: big ? 'uppercase' : 'none', opacity: k, transform: `translateY(${(1 - k) * 30}px)`, marginRight: kind === 'small' ? 12 : 0}}>
            {w}
          </span>
        );
      })}
    </div>
  );
};
