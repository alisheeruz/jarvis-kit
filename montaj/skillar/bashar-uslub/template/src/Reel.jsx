// Kadr tuzilishi (pastdan yuqoriga): fon -> sahnalar -> pastki qorong'ilik -> ramka -> logotip -> subtitr -> akkaunt nomi.
import {AbsoluteFill, Audio, Img, Sequence, staticFile, useCurrentFrame, useVideoConfig, interpolate, Easing} from 'remotion';
import {C} from './draw';
import {Subtitle, fontFamily} from './Subtitle';
import {project} from './project';
import captions from './captions.json';
import {scenes} from './scenes';

const XF = 14; // sahnalar orasidagi silliq o'tish (kadr). Keskin kesim ishlatilmaydi.
const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'};

// Sahna o'rami: kirish/chiqishda eriydi, butun sahna davomida kamera sekin yaqinlashadi/suriladi.
// cam: {from: {x, y, s}, to: {x, y, s}} — x,y piksel surilish, s masshtab. Berilmasa 1 -> 1.05 yaqinlashish.
const SceneWrap = ({cam, first, last, children}) => {
  const f = useCurrentFrame();
  const {durationInFrames: d} = useVideoConfig();
  const a = {x: 0, y: 0, s: 1, ...(cam?.from || {})};
  const b = {x: 0, y: 0, s: 1.05, ...(cam?.to || {})};
  const p = interpolate(f, [0, d], [0, 1], {...clamp, easing: Easing.inOut(Easing.sin)});
  const fadeIn = first ? 1 : interpolate(f, [0, XF], [0, 1], clamp);
  const fadeOut = last ? 1 : interpolate(f, [d - XF, d], [1, 0], clamp);
  const x = a.x + (b.x - a.x) * p;
  const y = a.y + (b.y - a.y) * p;
  const s = a.s + (b.s - a.s) * p;
  return (
    <AbsoluteFill style={{opacity: fadeIn * fadeOut, filter: `blur(${(1 - fadeIn * fadeOut) * 6}px)`}}>
      <svg viewBox="0 0 1080 1920" width={1080} height={1920}>
        <g transform={`translate(${540 + x} ${760 + y}) scale(${s}) translate(-540 -760)`}>{children}</g>
      </svg>
    </AbsoluteFill>
  );
};

const Corner = ({x, y}) => (
  <path d={`M ${x - 9} ${y} L ${x} ${y - 9} L ${x + 9} ${y} L ${x} ${y + 9} Z`} fill={C.bg0} stroke={C.line} strokeWidth={1.2} />
);

const DefaultLogo = () => (
  <svg width={64} height={82} viewBox="0 0 64 82" fill="none" stroke={C.white} strokeWidth={4} strokeLinejoin="round">
    <path d="M4 80 V34 Q4 14 32 4 Q60 14 60 34 V80 Z" />
    <path d="M20 80 V44 Q20 32 32 28 Q44 32 44 44 V80" />
  </svg>
);

export const Reel = () => {
  const {fps} = useVideoConfig();
  const line = project.style === 'line';
  return (
    <AbsoluteFill style={{backgroundColor: C.bg0}}>
      <AbsoluteFill style={{background: `radial-gradient(120% 70% at 50% 38%, ${C.bg1} 0%, ${C.bg0} 70%, #001512 100%)`}} />

      {scenes.map((sc, i) => {
        const from = Math.max(0, Math.round(sc.from * fps) - (i === 0 ? 0 : XF / 2));
        const to = Math.round(sc.to * fps) + (i === scenes.length - 1 ? fps * 2 : XF / 2);
        const S = sc.C;
        return (
          <Sequence key={i} from={from} durationInFrames={to - from}>
            <SceneWrap cam={sc.cam} first={i === 0} last={i === scenes.length - 1}>
              <S />
            </SceneWrap>
          </Sequence>
        );
      })}

      {/* Subtitr zonasi doim qorong'i: matn har qanday sahnada o'qiladi */}
      <AbsoluteFill style={{background: 'linear-gradient(to bottom, rgba(0,26,22,0) 1160px, rgba(0,20,17,0.94) 1360px, #000d0b 1920px)'}} />
      <AbsoluteFill style={{background: 'radial-gradient(100% 75% at 50% 45%, rgba(0,0,0,0) 55%, rgba(0,0,0,0.45) 100%)'}} />

      {line && (
        <AbsoluteFill>
          <svg viewBox="0 0 1080 1920" width={1080} height={1920} fill="none">
            <rect x={46} y={108} width={988} height={1704} stroke={C.line} strokeWidth={1.2} opacity={0.55} />
            <rect x={56} y={118} width={968} height={1684} stroke={C.line} strokeWidth={0.8} opacity={0.25} />
            <Corner x={46} y={108} />
            <Corner x={1034} y={108} />
            <Corner x={46} y={1812} />
            <Corner x={1034} y={1812} />
          </svg>
        </AbsoluteFill>
      )}

      <div style={{position: 'absolute', top: 161, left: 0, right: 0, display: 'flex', justifyContent: 'center', opacity: 0.92}}>
        {project.logo ? <Img src={staticFile(project.logo)} style={{height: 82}} /> : <DefaultLogo />}
      </div>

      <Subtitle captions={captions} />

      <div style={{position: 'absolute', top: 1588, left: 0, right: 0, textAlign: 'center', fontFamily, fontWeight: 500, fontSize: 27, color: C.white, opacity: 0.9}}>
        {project.watermark}
      </div>

      {project.audio && <Audio src={staticFile(project.audio)} />}
    </AbsoluteFill>
  );
};
