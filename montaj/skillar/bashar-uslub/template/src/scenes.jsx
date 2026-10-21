// Har bir video uchun shu fayl qayta yoziladi.
// Sahna = bitta gap bo'lagining rasmi. from/to — soniyada (captions.json dagi blok vaqtlaridan olinadi).
// Sahna ichida useCurrentFrame() sahna boshidan sanaladi (0 = sahna boshlandi).
import {useCurrentFrame} from 'remotion';
import {C, Ink, v, Person, Hills, Horizon, Hatch, Sun, Dust, House, Tree, Cypress, Basket, Glow, Measure} from './draw';

// 1. Tong, dala, yolg'iz dehqon. Quyosh sekin ko'tariladi.
const Dala = () => {
  const f = useCurrentFrame();
  return (
    <>
      <Sun x={760} y={v(f, [0, 110], [720, 600])} r={30} glow={0.7} id="s1" />
      <Hills y={520} />
      <Horizon y={760} at={6} />
      <Hatch y={790} h={420} at={14} />
      <Person x={330} y={1010} s={0.95} at={20} />
      <Measure x1={250} x2={410} y={1050} at={50} />
      <Dust seed="a" />
    </>
  );
};

// 2. Ikki kishi yuzma-yuz: qo'shni (xira chiziqda) dehqonga gapiryapti.
const Qoshni = () => {
  const f = useCurrentFrame();
  return (
    <>
      <Horizon y={760} />
      <Hatch y={790} h={420} seed="b" />
      <Cypress x={130} y={760} s={0.7} at={4} />
      <Cypress x={200} y={760} s={0.5} at={8} />
      <Person x={360} y={1040} s={1.15} at={6} />
      <Person x={720} y={1040} s={1.15} at={14} c={C.line} flip />
      {/* gap yo'nalishi: qo'shnidan dehqonga qarab uzuq chiziqlar */}
      {[0, 1, 2].map((i) => (
        <Ink key={i} at={40 + i * 8} dur={16} w={1.5} c={C.amber} o={0.8} d={`M 640 ${700 + i * 40} q -90 ${-18 + i * 6} -190 0`} />
      ))}
      <Glow x={360} y={860} r={v(f, [80, 150], [0, 260])} o={0.18} id="g2" />
      <Dust seed="b" />
    </>
  );
};

// 3. Kuz: uy, daraxt va to'lib, porlab turgan savat. Urg'u (yorug'lik) faqat savatda.
const Hosil = () => {
  const f = useCurrentFrame();
  const fill = v(f, [35, 95], [0, 1]);
  return (
    <>
      <Horizon y={900} />
      <House x={330} y={900} s={1.05} at={4} lit={v(f, [20, 60], [0, 0.9])} id="u3" />
      <Tree x={830} y={900} s={1.3} at={10} />
      <Hatch y={930} h={300} n={110} seed="c" at={12} />
      <Basket x={640} y={1090} s={1.5} at={16} fill={fill} id="sv3" />
      <Person x={880} y={1120} s={0.8} at={24} flip />
      <Dust seed="c" n={34} />
    </>
  );
};

export const scenes = [
  {from: 0, to: 4.1, C: Dala, cam: {from: {s: 1.0}, to: {s: 1.07, x: 20}}},
  {from: 4.1, to: 12.1, C: Qoshni, cam: {from: {s: 1.08, x: 60}, to: {s: 1.0, x: -20}}},
  {from: 12.1, to: 17.4, C: Hosil, cam: {from: {s: 1.0, y: 20}, to: {s: 1.1, x: -60, y: -60}}},
];
