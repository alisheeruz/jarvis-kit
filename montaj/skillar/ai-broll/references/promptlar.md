# Prompt formulalari

## Rasm prompti

```
[plan turi], [kim/nima — tashqi ko'rinishi bilan], [bitta harakat], [joy va 2–3 detal],
[yorug'lik manbai va yo'nalishi], [kayfiyat]
```

Plan turlari: `wide establishing shot`, `medium shot from behind`, `close-up of hands`,
`over-the-shoulder`, `silhouette against a bright doorway`, `top-down view of a table`.

Uslub bloki (`plan.json` → `style`) promptga avtomatik qo'shiladi, kadr promptida takrorlamang.

Yomon: `a sad family` — mavhum, generator o'zi to'qiydi.
Yaxshi: `Medium shot from behind: a husband and wife sit at opposite ends of a low table,
not looking at each other, two untouched tea bowls between them. A frosted window above them
lets in cold blue light.`

## Harakat prompti (image-to-video)

```
[kamera: slow push-in / slow pan left / static]. [BITTA asosiy harakat]. [muhit harakati:
dust, smoke, fabric, leaves, light flicker]. Everything else stays still. Calm, slow motion.
```

- Odamga katta harakat bermang (yugurish, burilish) — tana buziladi. Yurish orqadan, qo'l
  harakati, bosh egish — xavfsiz.
- Kadr 5 soniya bo'lsa, harakat 5 soniyada tugamasin: "continuously", "gently" so'zlari bilan
  uzluksiz qiling, shunda kesim silliq chiqadi.

## A. Jonli illyustratsiya — uslub bloki (2-reference)

```
Painterly digital illustration, semi-realistic with soft brushwork. Deep teal and dark blue
shadows dominate the frame; a single warm golden light source (oil lamp, lantern, sunlit
doorway or window) glows and casts volumetric rays with floating dust. Figures are faceless
silhouettes or seen from behind, in modest traditional Central Asian clothing. Uzbek interior
details: carved wooden doors, suzani textiles, ceramic teapots, arched niches. Cinematic,
quiet, contemplative mood. The lower third of the frame fades into deep empty shadow.
```

Kadr misollari (reference'dan):

| Gap | Rasm | Harakat |
|---|---|---|
| "eridan yashirmasligi" | Close-up: a hand lifts a glowing golden patterned shawl out of a carved chest, lantern beside it | The shawl rises and ripples as if weightless; lantern flame flickers. Slow push-in. |
| "erkakning ko'zi boshqalarida" | Wide: a man's silhouette walks away down a foggy night street, one street lamp, lit windows far ahead | He walks slowly away; fog drifts. Static camera. |
| "tashqariga chiqqanda" | Silhouette of a woman in a doorway opening carved doors onto bright golden daylight | Doors swing open, light floods in, her long shadow stretches. Slow push-in. |
| "er-xotin o'rtasida sovuqchilik" | Medium: two figures sit apart at a low table under a frost-covered window, all in cold blue | Faint steam from one tea bowl; snow falls outside. Static. |
| chaqiriq | Top-down: an open book, a ceramic teapot and tea bowl on a patterned carpet, light beam from a door ajar | Pages turn slowly; steam rises. Slow push-in. |

Rang ham ma'no tashiydi: iliq oltin = yaxshi holat, sovuq ko'k = muammo. Reference shu qarama-
qarshilikda qurilgan.

## B. Stiker-kollaj — uslub bloklari (3-reference)

Fon:

```
Rich detailed digital illustration of [joy], warm evening light, saturated reds and golds,
Uzbek ornaments and suzani patterns, slightly stylized like a storybook, no people, empty
foreground floor area for characters to stand on.
```

Personaj (har biri alohida, keyin `sticker.py`):

```
Full-body cartoon character, [yosh, jins, kiyim, poza, mimika], clean bold outlines, flat
cel shading, standing, isolated on a plain pure white background, no shadow, no props cut off.
```

Bir personajning bir necha holati kerak bo'lsa (gapiryapti / hayron / xursand) — birinchi
rasmni `refs` ga qo'yib, "same character, same outfit, now [yangi poza]" deb so'rang.

Ustiga qo'yiladigan grafika (montajda, AI emas): tepada sarlavha plashkasi (oq yoki sariq fon,
qora bosh harflar), hisob tablosi, nutq pufakchalari, raqamli kartochka ("4/10" → "8.5/10").
O'tmishni ko'rsatish uchun kadr oq-qora qilinadi.

## C. Dunyoni almashtirish — video-to-video prompt (1-reference)

```
Transform the scene into [dunyo]. Keep the person's face, expression, lip movement, pose and
camera framing exactly the same. Change the clothing to [kiyim], the background to [muhit],
add [1–2 jonli detal: walking zombies / horses and dust / cigar smoke]. Cinematic lighting,
photorealistic.
```

Reference'dagi dunyolar: zombi apokalipsisi (chang, qurigan daraxtlar, yirtiq kiyim), yovvoyi
g'arb (kovboy shlyapasi, arava, yog'och shaharcha, quyosh botishi), mafiya kabineti (smoking,
sigara tutuni, yog'och panel). Har dunyo 3–7 soniya, keyin asl kadrga qaytadi — "mana asli"
effekti tomoshabinni ushlab turadi.

Yaxshi natija uchun asl kadr: kamera qimirlamasin, yuz yaxshi yoritilgan, qo'llar yuzni
yopmasin, fon sodda bo'lsin.
