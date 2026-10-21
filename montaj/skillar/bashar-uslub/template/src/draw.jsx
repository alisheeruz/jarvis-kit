// Chizma kutubxonasi: hamma sahna shu bo'laklardan yig'iladi.
// Koordinatalar 1080x1920 kanvasda. Rasm zonasi: y 280..1250 (pastida subtitr turadi).
// Har bir bo'lak: x,y = tayanch nuqta (odatda yerdagi markaz), s = masshtab,
// at = sahna boshidan necha kadr keyin chizila boshlashi, solid = to'ldirilgan siluet.
import {useCurrentFrame, interpolate, Easing, random} from 'remotion';

export const C = {
  bg0: '#00221d', // fonning qorong'i tusi
  bg1: '#0b3a32', // fonning yorug' tusi
  line: '#4f8f80', // ikkinchi darajali chiziqlar (suv, tog', yer)
  ink: '#ead9bd', // asosiy obyekt chiziqlari (odam, qayiq)
  amber: '#d9b595', // urg'u
  glow: '#f2b25c', // yorug'lik
  white: '#f4f1e8',
  dark: '#06120f', // siluet to'ldirish
};

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'};

// Asosiy "siyoh": chiziq at-kadrdan boshlab dur kadr ichida chizilib chiqadi.
export const Ink = ({d, at = 0, dur = 22, w = 2.5, c = C.line, o = 1, fill = 'none'}) => {
  const f = useCurrentFrame();
  const p = interpolate(f, [at, at + dur], [0, 1], {...clamp, easing: Easing.out(Easing.cubic)});
  if (p <= 0) return null;
  return (
    <path
      d={d}
      pathLength={1}
      strokeDasharray={1}
      strokeDashoffset={1 - p}
      stroke={c}
      strokeWidth={w}
      fill={fill}
      fillOpacity={fill === 'none' ? 0 : p}
      opacity={o}
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  );
};

// Guruh: joylash + masshtab. flip = gorizontal ko'zgu (odam chapga qarashi uchun).
export const G = ({x = 0, y = 0, s = 1, flip = false, o = 1, children}) => (
  <g transform={`translate(${x} ${y}) scale(${flip ? -s : s} ${s})`} opacity={o}>
    {children}
  </g>
);

// Vaqt bo'yicha silliq qiymat: v(f, [kadr0, kadr1], [qiymat0, qiymat1])
export const v = (f, frames, values) =>
  interpolate(f, frames, values, {...clamp, easing: Easing.inOut(Easing.cubic)});

// ---------- ODAM ----------
// pose: 'stand' | 'kneel' | 'sit'. Bo'yi s=1 da ~370px. Yuz chizilmaydi (kanal qoidasi).
export const Person = ({x, y, s = 1, at = 0, c = C.ink, pose = 'stand', solid = false, flip = false, w = 2.5}) => {
  const fill = solid ? C.dark : 'none';
  const st = solid ? C.amber : c;
  const sw = solid ? 1.5 : w;
  const P = (d, i, extra = {}) => <Ink key={i} d={d} at={at + i * 4} c={st} w={sw} fill={fill} {...extra} />;
  const head = 'M -26 0 a 26 26 0 1 0 52 0 a 26 26 0 1 0 -52 0';
  if (pose === 'kneel') {
    return (
      <G x={x} y={y} s={s} flip={flip}>
        {P('M -70 0 L 78 0 L 78 -34 Q 40 -44 22 -60 L 12 -150 Q -8 -168 -34 -150 L -48 -60 Q -70 -40 -70 0 Z', 0)}
        <g transform="translate(-12 -196)">{P(head, 1)}</g>
        {P('M -36 -210 Q -12 -240 14 -210', 2, {fill: 'none'})}
        {P('M 4 -140 L 34 -70', 3, {fill: 'none'})}
      </G>
    );
  }
  if (pose === 'sit') {
    return (
      <G x={x} y={y} s={s} flip={flip}>
        {P('M -34 -190 Q 0 -204 32 -190 L 36 -70 L 96 -70 L 96 -4 L 120 -4 L 120 0 L 70 0 L 70 -40 L -34 -40 Z', 0)}
        <g transform="translate(0 -228)">{P(head, 1)}</g>
        {P('M -24 -242 Q 0 -272 24 -242', 2, {fill: 'none'})}
      </G>
    );
  }
  return (
    <G x={x} y={y} s={s} flip={flip}>
      {P('M -16 -56 L -16 -6 L -36 -6 L -36 0 L -3 0 L -3 -56 M 5 -56 L 5 0 L 38 0 L 38 -6 L 18 -6 L 18 -56', 0)}
      {P('M -30 -292 Q -30 -308 0 -310 Q 30 -308 30 -292 L 33 -54 L -33 -54 Z', 1)}
      <g transform="translate(0 -340)">{P(head, 2)}</g>
      {P('M -24 -354 Q 0 -386 24 -354', 3, {fill: 'none'})}
      {P('M 17 -286 L 20 -168 Q 12 -150 6 -168', 4, {fill: 'none'})}
    </G>
  );
};

// ---------- TABIAT ----------
// Suv: tasodifiy uzunlikdagi gorizontal chiziqchalar. seed o'zgarsa naqsh o'zgaradi.
export const Water = ({x = 56, y, w = 968, h = 500, rows = 12, at = 0, c = C.line, seed = 'suv'}) => {
  const f = useCurrentFrame();
  const out = [];
  for (let r = 0; r < rows; r++) {
    const yy = y + (r + 0.5) * (h / rows);
    let xx = x + random(`${seed}${r}`) * 80;
    let i = 0;
    while (xx < x + w - 40) {
      const len = 30 + random(`${seed}${r}-${i}`) * 170;
      const drift = Math.sin((f + r * 17 + i * 31) / 40) * 6;
      const x1 = xx + drift;
      const x2 = Math.min(xx + len, x + w) + drift;
      out.push(<Ink key={`${r}-${i}`} d={`M ${x1} ${yy} L ${x2} ${yy}`} at={at + r * 2 + i} dur={14} w={1.5} c={c} o={0.75} />);
      xx += len + 30 + random(`${seed}g${r}-${i}`) * 110;
      i++;
    }
  }
  return <g>{out}</g>;
};

// Yer shtrixi: qiya qisqa chiziqlar.
export const Hatch = ({x = 56, y, w = 968, h = 300, n = 160, at = 0, c = C.line, seed = 'yer'}) => {
  const out = [];
  for (let i = 0; i < n; i++) {
    const px = x + random(`${seed}x${i}`) * w;
    const py = y + random(`${seed}y${i}`) * h;
    const fade = 1 - (py - y) / h;
    out.push(<Ink key={i} d={`M ${px} ${py} l -9 20`} at={at + (i % 20)} dur={8} w={1.3} c={c} o={0.25 + fade * 0.45} />);
  }
  return <g>{out}</g>;
};

export const Hills = ({y, at = 0, c = C.line}) => (
  <g>
    <Ink at={at} dur={40} w={1.5} c={c} o={0.8} d={`M 56 ${y + 60} Q 180 ${y - 30} 320 ${y + 30} T 560 ${y + 10} T 820 ${y + 100} T 1024 ${y + 60}`} />
    <Ink at={at + 8} dur={40} w={1.5} c={c} o={0.6} d={`M 56 ${y + 120} Q 260 ${y + 60} 440 ${y + 90} T 800 ${y + 100} T 1024 ${y + 110}`} />
  </g>
);

export const Horizon = ({y, at = 0, c = C.line, x1 = 56, x2 = 1024, w = 1.5}) => (
  <Ink at={at} dur={30} w={w} c={c} d={`M ${x1} ${y} L ${x2} ${y}`} />
);

export const Tree = ({x, y, s = 1, at = 0, c = C.line, solid = false}) => {
  const fill = solid ? '#123f33' : 'none';
  return (
    <G x={x} y={y} s={s}>
      <Ink at={at} c={solid ? '#3a2a1c' : c} w={solid ? 10 : 2} d="M 0 0 L 0 -150 M 0 -90 L -34 -130 M 0 -110 L 30 -150" />
      {[[-46, -190, 56], [34, -200, 62], [-6, -250, 66], [-70, -140, 40], [66, -150, 42]].map(([cx, cy, r], i) => (
        <Ink key={i} at={at + 6 + i * 3} c={solid ? '#1d5a48' : c} w={1.8} fill={fill} d={`M ${cx - r} ${cy} a ${r} ${r} 0 1 0 ${2 * r} 0 a ${r} ${r} 0 1 0 ${-2 * r} 0`} />
      ))}
    </G>
  );
};

export const Cypress = ({x, y, s = 1, at = 0, c = C.line, solid = false}) => (
  <G x={x} y={y} s={s}>
    <Ink at={at} c={c} w={1.8} fill={solid ? '#0e3a30' : 'none'} d="M 0 0 L 0 -30 Q -34 -120 0 -300 Q 34 -120 0 -30" />
  </G>
);

// Quyosh/oy: r radiusli doira, glow > 0 bo'lsa atrofida yorug'lik.
export const Sun = ({x, y, r = 34, at = 0, c = C.amber, glow = 0.5, id = 'sun'}) => {
  const f = useCurrentFrame();
  const p = v(f, [at, at + 30], [0, 1]);
  return (
    <g>
      <defs>
        <radialGradient id={id}>
          <stop offset="0" stopColor={C.glow} stopOpacity={0.55 * glow} />
          <stop offset="1" stopColor={C.glow} stopOpacity="0" />
        </radialGradient>
      </defs>
      <circle cx={x} cy={y} r={r * 7} fill={`url(#${id})`} opacity={p} />
      <Ink at={at} c={c} w={2} d={`M ${x - r} ${y} a ${r} ${r} 0 1 0 ${2 * r} 0 a ${r} ${r} 0 1 0 ${-2 * r} 0`} />
    </g>
  );
};

// Yumshoq yorug'lik dog'i (chiroq, eshik ortidagi nur, urg'u).
export const Glow = ({x, y, r = 200, o = 0.5, color = C.glow, id}) => (
  <g>
    <defs>
      <radialGradient id={id}>
        <stop offset="0" stopColor={color} stopOpacity={o} />
        <stop offset="1" stopColor={color} stopOpacity="0" />
      </radialGradient>
    </defs>
    <circle cx={x} cy={y} r={r} fill={`url(#${id})`} />
  </g>
);

// Havoda suzuvchi mayda zarrachalar: har sahnada bo'lishi kerak (kadr "tirik" turadi).
export const Dust = ({n = 26, seed = 'chang', y1 = 300, y2 = 1250, c = C.amber}) => {
  const f = useCurrentFrame();
  return (
    <g>
      {Array.from({length: n}).map((_, i) => {
        const bx = 60 + random(`${seed}x${i}`) * 960;
        const by = y1 + random(`${seed}y${i}`) * (y2 - y1);
        const sp = 0.25 + random(`${seed}s${i}`) * 0.5;
        const x = bx + Math.sin((f * sp) / 30 + i) * 22;
        const y = by - ((f * sp * 0.6) % 120);
        const tw = 0.25 + 0.35 * (0.5 + 0.5 * Math.sin(f / 18 + i * 2.1));
        return <circle key={i} cx={x} cy={y} r={1.2 + random(`${seed}r${i}`) * 2} fill={c} opacity={tw} />;
      })}
    </g>
  );
};

// ---------- BUYUMLAR ----------
export const Boat = ({x, y, s = 1, at = 0, c = C.ink, flip = false}) => (
  <G x={x} y={y} s={s} flip={flip}>
    <Ink at={at} dur={30} c={c} w={2.5} d="M -210 -78 Q -190 -10 -120 0 L 130 0 Q 196 -14 212 -70 Q 0 -52 -210 -78 Z" />
    <Ink at={at + 12} dur={24} c={c} w={1.5} o={0.7} d="M -170 -26 Q -60 -40 0 -26 T 170 -30" />
  </G>
);

// Arka/eshik: open 0..1 tavaqalar ochilishi, glow 0..1 ichkaridan nur.
export const Arch = ({x, y, s = 1, at = 0, c = C.ink, open = 1, glow = 0, id = 'arch'}) => {
  const lw = 30 + 80 * open;
  return (
    <G x={x} y={y} s={s}>
      <defs>
        <linearGradient id={id} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor={C.glow} stopOpacity="0" />
          <stop offset="0.45" stopColor={C.glow} stopOpacity={0.55 * glow} />
          <stop offset="1" stopColor="#f6d49a" stopOpacity={0.95 * glow} />
        </linearGradient>
      </defs>
      <path d="M -110 0 L -110 -230 A 110 110 0 0 1 110 -230 L 110 0 Z" fill={glow > 0 ? `url(#${id})` : 'none'} />
      <Ink at={at} dur={34} c={c} w={2.5} d="M -110 0 L -110 -230 A 110 110 0 0 1 110 -230 L 110 0" />
      <Ink at={at + 6} dur={34} c={c} w={1.5} o={0.7} d="M -136 0 L -136 -232 A 136 136 0 0 1 136 -232 L 136 0" />
      <Ink at={at + 14} c={c} w={2} d={`M -136 -250 L ${-136 - lw} -280 L ${-136 - lw} 24 L -136 0`} />
      <Ink at={at + 18} c={c} w={2} d={`M 136 -250 L ${136 + lw} -280 L ${136 + lw} 24 L 136 0`} />
    </G>
  );
};

export const House = ({x, y, s = 1, at = 0, c = C.line, lit = 0, id = 'uy'}) => (
  <G x={x} y={y} s={s}>
    <Ink at={at} dur={30} c={c} w={2} d="M -180 0 L -180 -220 L 180 -220 L 180 0 Z M -196 -220 L 196 -220 L 196 -238 L -196 -238 Z" />
    <defs>
      <radialGradient id={id}>
        <stop offset="0" stopColor="#f6d49a" stopOpacity={lit} />
        <stop offset="1" stopColor={C.glow} stopOpacity={lit * 0.5} />
      </radialGradient>
    </defs>
    <path d="M -120 -70 L -120 -130 A 30 30 0 0 1 -60 -130 L -60 -70 Z" fill={`url(#${id})`} />
    <Ink at={at + 10} c={c} w={2} d="M -120 -70 L -120 -130 A 30 30 0 0 1 -60 -130 L -60 -70 Z M -90 -160 L -90 -70" />
    <Ink at={at + 16} c={c} w={2} d="M 40 0 L 40 -150 L 120 -150 L 120 0 M 80 -150 L 80 0" />
  </G>
);

export const Mosque = ({x, y, s = 1, at = 0, c = C.line}) => (
  <G x={x} y={y} s={s}>
    <Ink at={at} dur={34} c={c} w={2} d="M -150 0 L -150 -170 L 150 -170 L 150 0 M -50 0 L -50 -90 A 50 50 0 0 1 50 -90 L 50 0" />
    <Ink at={at + 8} dur={34} c={c} w={2} d="M -90 -170 Q -100 -290 0 -310 Q 100 -290 90 -170 M 0 -310 L 0 -340" />
    <Ink at={at + 14} c={c} w={2} d="M -210 0 L -210 -330 L -196 -372 L -182 -330 L -182 0 M -216 -280 L -176 -280" />
    <Ink at={at + 18} c={c} w={2} d="M 182 0 L 182 -330 L 196 -372 L 210 -330 L 210 0 M 176 -280 L 216 -280" />
  </G>
);

// Soat: hour/minute — boshlang'ich vaqt, spin — strelka sahna davomida necha soat aylanishi.
export const Clock = ({x, y, r = 110, at = 0, c = C.ink, hour = 6, spin = 2, len = 150}) => {
  const f = useCurrentFrame();
  const h = hour + v(f, [at + 20, at + len], [0, spin]);
  const ha = (h / 12) * 360;
  const ma = h * 360;
  return (
    <G x={x} y={y}>
      <Ink at={at} dur={30} c={c} w={2.5} d={`M ${-r} 0 a ${r} ${r} 0 1 0 ${2 * r} 0 a ${r} ${r} 0 1 0 ${-2 * r} 0`} />
      {Array.from({length: 12}).map((_, i) => {
        const a = (i / 12) * Math.PI * 2;
        return <Ink key={i} at={at + 10 + i} dur={6} c={c} w={1.5} d={`M ${Math.sin(a) * (r - 14)} ${-Math.cos(a) * (r - 14)} L ${Math.sin(a) * (r - 4)} ${-Math.cos(a) * (r - 4)}`} />;
      })}
      <g transform={`rotate(${ha})`}><Ink at={at + 20} c={C.amber} w={4} d={`M 0 8 L 0 ${-r * 0.5}`} /></g>
      <g transform={`rotate(${ma})`}><Ink at={at + 22} c={c} w={2.5} d={`M 0 12 L 0 ${-r * 0.78}`} /></g>
    </G>
  );
};

// Savat/chelak: fill 0..1 ichidagi "rizq" (to'lgan sari porlaydi).
export const Basket = ({x, y, s = 1, at = 0, c = C.ink, fill = 0, id = 'savat'}) => (
  <G x={x} y={y} s={s}>
    {fill > 0 && <Glow x={0} y={-100} r={150} o={0.5 * fill} id={id} />}
    {fill > 0 && <ellipse cx={0} cy={-96} rx={78} ry={20 + 16 * fill} fill="#f1c98a" opacity={fill} />}
    <Ink at={at} dur={26} c={c} w={2.5} d="M -90 -96 L -64 0 L 64 0 L 90 -96 M -90 -96 a 90 16 0 1 0 180 0 a 90 16 0 1 0 -180 0" />
    <Ink at={at + 10} c={c} w={1.3} o={0.7} d="M -80 -64 L 80 -64 M -72 -32 L 72 -32 M -40 -96 L -30 0 M 0 -80 L 0 0 M 40 -96 L 30 0" />
  </G>
);

export const Book = ({x, y, s = 1, at = 0, c = C.ink}) => (
  <G x={x} y={y} s={s}>
    <Ink at={at} dur={30} c={c} w={2.5} d="M 0 -150 Q -90 -176 -200 -150 L -200 20 Q -90 -6 0 20 Q 90 -6 200 20 L 200 -150 Q 90 -176 0 -150 L 0 20" />
    {Array.from({length: 6}).map((_, i) => (
      <Ink key={i} at={at + 14 + i * 3} dur={12} c={c} w={1.3} o={0.6} d={`M -176 ${-124 + i * 22} Q -90 ${-146 + i * 22} -24 ${-124 + i * 22} M 24 ${-124 + i * 22} Q 90 ${-146 + i * 22} 176 ${-124 + i * 22}`} />
    ))}
  </G>
);

// Osma chiroq: yonib turadi va sekin tebranadi.
export const Lamp = ({x, y = 280, len = 300, at = 0, c = C.ink, id = 'chiroq'}) => {
  const f = useCurrentFrame();
  const sway = Math.sin(f / 35) * 2.5;
  const on = v(f, [at + 14, at + 30], [0, 1]) * (0.9 + 0.1 * Math.sin(f / 5));
  return (
    <g transform={`rotate(${sway} ${x} ${y})`}>
      <Glow x={x} y={y + len + 30} r={420} o={0.3 * on} id={id} />
      <Ink at={at} c={c} w={1.5} d={`M ${x} ${y} L ${x} ${y + len}`} />
      <circle cx={x} cy={y + len + 30} r={28} fill="#f8dfae" opacity={on} />
      <Ink at={at + 8} c={c} w={2} d={`M ${x - 28} ${y + len + 30} a 28 28 0 1 0 56 0 a 28 28 0 1 0 -56 0 M ${x - 12} ${y + len + 4} L ${x - 12} ${y + len - 10} L ${x + 12} ${y + len - 10} L ${x + 12} ${y + len + 4}`} />
    </g>
  );
};

// Qabr toshi / belgi tosh.
export const Stone = ({x, y, s = 1, at = 0, c = C.line}) => (
  <G x={x} y={y} s={s}>
    <Ink at={at} c={c} w={2} d="M -26 0 L -26 -60 A 26 26 0 0 1 26 -60 L 26 0 M -70 0 Q 0 -22 70 0" />
  </G>
);

// Yo'l: uzoqqa ketuvchi perspektiva (ikki chiziq bir nuqtaga yig'iladi).
export const Road = ({x = 540, yFar, yNear = 1250, wNear = 520, at = 0, c = C.line}) => (
  <g>
    <Ink at={at} dur={36} c={c} w={1.8} d={`M ${x - wNear / 2} ${yNear} L ${x - 8} ${yFar}`} />
    <Ink at={at + 4} dur={36} c={c} w={1.8} d={`M ${x + wNear / 2} ${yNear} L ${x + 8} ${yFar}`} />
  </g>
);

// O'lchov chizig'i: "chizma" uslubining imzo detali (obyekt yonidagi nozik belgilar).
export const Measure = ({x1, x2, y, at = 0, c = C.line}) => (
  <Ink at={at} c={c} w={1.2} o={0.7} d={`M ${x1} ${y} L ${x2} ${y} M ${x1} ${y - 8} L ${x1} ${y + 8} M ${x2} ${y - 8} L ${x2} ${y + 8} M ${(x1 + x2) / 2} ${y - 5} L ${(x1 + x2) / 2} ${y + 5}`} />
);
