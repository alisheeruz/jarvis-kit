// So'zma-so'z subtitr: aytilmagan so'zlar xira va blur, aytilgan so'z tiniqlashadi,
// kalit so'zlar (hl) aytilganda sarg'ish rangga o'tadi, blok oxirida butun matn blur bo'lib yo'qoladi.
import {useCurrentFrame, useVideoConfig, interpolate} from 'remotion';
import {loadFont} from '@remotion/google-fonts/Onest';
import {C} from './draw';

export const {fontFamily} = loadFont('normal', {weights: ['500', '600'], subsets: ['latin', 'latin-ext', 'cyrillic']});

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'};
const LEAD = 0.12; // blok birinchi so'zdan shuncha oldin (xira holda) ko'rinadi
const OUT = 0.16; // blok shuncha vaqt ichida blur bo'lib chiqadi
const WORD = 0.12; // bitta so'zning tiniqlashish vaqti

export const Subtitle = ({captions}) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const t = f / fps;
  const cap = captions.find((c) => t >= c.s - LEAD && t < c.e);
  if (!cap) return null;

  const enter = interpolate(t, [cap.s - LEAD, cap.s + 0.05], [0, 1], clamp);
  const exit = interpolate(t, [cap.e - OUT, cap.e], [0, 1], clamp);

  return (
    <div
      style={{
        position: 'absolute',
        left: 90,
        right: 90,
        top: 1445,
        transform: 'translateY(-50%)',
        textAlign: 'center',
        fontFamily,
        fontWeight: 600,
        fontSize: 47,
        lineHeight: '59px',
        letterSpacing: '-0.01em',
        opacity: enter * (1 - exit),
        filter: `blur(${exit * 12}px)`,
      }}
    >
      {cap.lines.map((line, li) => (
        <div key={li}>
          {line.map((w, wi) => {
            const p = interpolate(t, [w.s - WORD / 2, w.s + WORD / 2], [0, 1], clamp);
            return (
              <span
                key={wi}
                style={{
                  display: 'inline-block',
                  marginRight: wi < line.length - 1 ? '0.26em' : 0,
                  color: w.hl && p > 0.5 ? C.amber : C.white,
                  opacity: 0.5 + 0.5 * p,
                  filter: `blur(${(1 - p) * 4.5}px)`,
                  transform: `translateY(${(1 - p) * 3}px)`,
                }}
              >
                {w.t}
              </span>
            );
          })}
        </div>
      ))}
    </div>
  );
};
