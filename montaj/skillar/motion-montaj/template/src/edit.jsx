// Har bir video uchun shu fayl qayta yoziladi: bu — montaj stoli.
// Qatlamlar tartibi = yozilish tartibi (pastdagi kod ustki qatlam). Hamma vaqtlar soniyada.
import {AbsoluteFill, Audio, staticFile} from 'remotion';
import {Theme, At, Footage, Person, Pill, PillCaptions, BigWord, Cutaway, TypeLine, Card, Media, SearchBar, Stat, NameCard, Cursor, PaperBg, Tape, Chart, Bars, Stamp, Kinetic, FONT, useT} from './kit';

export const DURATION = 14; // video uzunligi (soniya)
const VIDEO = null; // 'main.mp4' — public/ ichidagi asosiy video (scripts/prep.sh yasaydi). null = namuna fon.
const MATTE = null; // 'person.webm' — scripts/matte.py chiqargan odam kesimi (0–3 s uchun). null = effekt o'chiq.

// Zoom: keskin punch-zoom ishlatilmaydi (SKILL.md, qat'iy saboq 1) — faqat oxirida bitta sekin 1.07.
const PUNCHES = [
  {t: DURATION - 4, s: 1.07, smooth: 4},
];

const Placeholder = () => {
  const {t} = useT();
  return (
    <AbsoluteFill style={{background: `radial-gradient(80% 60% at 50% ${40 + Math.sin(t) * 3}%, #3a3f45, #101214)`, alignItems: 'center', justifyContent: 'center', fontFamily: FONT.body, color: '#ffffff55', fontSize: 40}}>
      asosiy video (VIDEO = null)
    </AbsoluteFill>
  );
};

export const Reel = () => (
  <Theme name="lime">
    <AbsoluteFill style={{backgroundColor: '#000'}}>
      {/* 1. Asosiy video (ovozi bilan) */}
      {VIDEO ? <Footage src={VIDEO} punches={PUNCHES} dim={[[0, 3, 0.35]]} /> : <Placeholder />}

      {/* 2. Ilgak: yirik so'z ODAM ORQASIDA (Person undan keyin yozilgan) */}
      <At from={0.2} to={3}>
        <BigWord text="DIPLOM" small="haqiqatan ham" script="shartmi?" y={600} size={300} />
      </At>
      {MATTE && (
        <At from={0} to={3}>
          <Person src={MATTE} />
        </At>
      )}

      {/* 3. Plashka-subtitr: 1–3 so'z, ko'krak balandligida. Haqiqiy loyihada:
             import captions from './captions.json';  <PillCaptions captions={captions} skip={[[0, 3], [7, 14]]} /> */}
      <At from={3.0} to={3.8}><Pill text="men" y={1180} /></At>
      <At from={3.8} to={4.6}><Pill text="o'rta maxsus" y={1180} /></At>
      <At from={4.6} to={5.2}><Pill text="ma'lumotliman" y={1180} /></At>
      <At from={5.2} to={6.1}><Pill text="lekin" /></At>
      <At from={6.1} to={7.0}><Pill text="bugun" /></At>

      {/* 4. Kesma sahna: gapiruvchi o'rniga 3.5 soniyalik grafik ekran */}
      <At from={7} to={10.5}>
        <Cutaway>
          <TypeLine text="Mijozlar nimani so'raydi?" x={110} y={330} size={66} />
          <At from={0.9} to={3.5}>
            <SearchBar text="portfolio ko'rsating" x={110} y={520} w={860} />
          </At>
          <Card x={150} y={780} w={470} h={620} delay={1.5} rotate={-4} bg="#e9f6d8" pad={36}>
            <div style={{fontFamily: FONT.body, fontSize: 40, fontWeight: 700, color: '#20350d'}}>Portfolio</div>
            <div style={{fontFamily: FONT.body, fontSize: 150, fontWeight: 700, color: '#20350d', letterSpacing: '-0.05em', marginTop: 120}}>9/10</div>
          </Card>
          <Card x={540} y={920} w={400} h={420} delay={1.9} rotate={5} pad={36}>
            <div style={{fontFamily: FONT.body, fontSize: 40, fontWeight: 700, color: '#555'}}>Diplom</div>
            <div style={{fontFamily: FONT.body, fontSize: 150, fontWeight: 700, color: '#bbb', letterSpacing: '-0.05em', marginTop: 40}}>1/10</div>
          </Card>
          <Cursor from={[900, 1500]} to={[330, 1180]} delay={2.3} />
        </Cutaway>
      </At>

      {/* 5. Eksplayner sahna: qog'oz fon, yorliq, grafik, muhr (boshqa mavzuda) */}
      <At from={10.5} to={14}>
        <Theme name="paper">
          <PaperBg />
          <Tape text="1-tuzoq" x={330} y={260} />
          <Chart
            y={480}
            series={[
              {label: 'DAROMAD', color: '#3f8f5a', step: true, points: [[0, 0.1], [0.25, 0.3], [0.5, 0.52], [0.75, 0.74], [1, 0.95]]},
              {label: 'XARAJAT', color: '#d8392b', step: true, points: [[0, 0.06], [0.25, 0.26], [0.5, 0.48], [0.75, 0.7], [1, 0.91]]},
            ]}
          />
          <Stamp text="Nega?" y={1400} delay={2.4} />
        </Theme>
      </At>

      {/* Ovoz asosiy videodan keladi. Fon musiqasi har doim (~/Montaj/musiqa dan public/ ga): <Audio src={staticFile('music.mp3')} volume={0.12} />
          SFX kesim/flash paytida: <Sequence from={Math.round(t*30)}><Audio src={staticFile('whoosh.mp3')} volume={0.5} /></Sequence> */}
    </AbsoluteFill>
  </Theme>
);
