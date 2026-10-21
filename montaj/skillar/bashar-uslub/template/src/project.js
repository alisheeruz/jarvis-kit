// Har bir video uchun shu faylni o'zgartiring.
export const project = {
  // public/ ichidagi ovoz fayli nomi. Ovozsiz sinov uchun null.
  audio: null,
  // Subtitr ostidagi kichik yozuv (o'z akkauntingiz nomi).
  watermark: 'sizning.akkaunt',
  // public/ ichidagi logotip (oq, shaffof fonli PNG/SVG). null bo'lsa oddiy arka belgisi chiziladi.
  logo: null,
  // 'line' = yupqa chiziqli "chizma" uslubi, 'flat' = to'ldirilgan siluet uslubi.
  // Faqat ramka burchaklari va fon tusiga ta'sir qiladi; sahnalar o'zi scenes.jsx da.
  style: 'line',
  // Oxirgi subtitrdan keyin qoladigan soniya.
  tail: 0.6,
};
