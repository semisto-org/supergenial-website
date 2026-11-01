// Génère la page Réalisations (FR) + une page par étude de cas à partir des drafts JSON.
// Usage : bun realisations/build.ts
// Les drafts (_drafts/*.json) sont la SOURCE VERSIONNÉE — ils ne sont jamais supprimés.
// POST-BUILD : bun realisations/en-build.ts puis bun ressources/langswitch.ts et bun ressources/mainnav.ts
// Les pages sortent avec la coquille du site (site.css, favicon, carte de partage, hreflang,
// lien d'évitement, pied de page) : le pipeline complet ne doit laisser aucun diff.

import { readdirSync, readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { join, dirname } from "node:path";

const ROOT = dirname(new URL(import.meta.url).pathname);      // .../realisations
const SITE = dirname(ROOT);                                   // repo root
const DRAFTS = join(ROOT, "_drafts");

export type CaseImage = {
  src: string; alt: string; alt_en: string;
  caption: string; caption_en: string;
};

export type CaseStudy = {
  slug: string; slug_en: string;
  order?: number;                         // position dans la liste (à année égale)
  type: string; type_en: string;          // Site web | App interne | Newsletter…
  client: string; year: string;
  problem: string; problem_en: string;   // le problème métier résolu, affiché en tête
  title: string; title_en: string;
  description: string; description_en: string;
  keywords: string; keywords_en: string;
  url_live?: string;
  stack: string[];
  images: CaseImage[];
  carousel?: {
    title: string; title_en: string;
    intro: string; intro_en: string;
    images: CaseImage[];
  };
  body_html: string; body_html_en: string;
};

// La coquille (head, menu, pied de page, Plausible) vient de tools/site/layout.ts, source unique.
import { head, nav, footer, langPill, sectionOf, NAV_JS, BOOKING, SITE_URL, breadcrumbLd } from "../tools/site/layout.ts";

// alt : { fr, en } = chemins des deux versions, pour les liens hreflang.
export const HEAD = (lang: string, title: string, description: string, _keywords: string, canonical: string, alt: { fr: string; en: string }) =>
  head({
    lang: lang as "fr" | "en", path: canonical.replace(SITE_URL, ""), alt, title, description,
    og: "realisations",
    ogAlt: lang === "fr" ? "Réalisations Super Génial : des outils qui tournent tous les jours" : "Super Génial case studies: tools used every day",
    jsonld: [breadcrumbLd([["Super Génial", lang === "fr" ? "/" : "/en/"], [lang === "fr" ? "Réalisations" : "Case studies", lang === "fr" ? "/realisations/" : "/en/case-studies/"]])],
  });

// Début du <body> : lien d'évitement, <main>, menu.
export const OPEN = (lang: "fr" | "en", alt: { fr: string; en: string }) => `<body>
<a class="skip-link plain" href="#contenu">${lang === "fr" ? "Aller au contenu" : "Skip to content"}</a>
    <main id="contenu">
        ${nav(lang, sectionOf(alt[lang]), langPill(lang, alt))}`;

// Pied de page commun, puis le script du menu mobile.
export const FOOT = (lang: "fr" | "en") => `        ${footer(lang)}
    </main>
${NAV_JS}
</body>
</html>
`;

// Encadré de fin d'étude de cas : le call de 30 minutes.
export const CTA = (lang: "fr" | "en") => lang === "fr"
  ? `            <div class="cta-box animate delay-3">
                <p>Un problème du même genre chez vous&nbsp;? Parlons-en trente minutes.</p>
                <div class="actions"><a href="${BOOKING.fr}" class="btn btn-primary plain" data-booking target="_blank" rel="noopener noreferrer">Réserver un call de 30 minutes <span class="arr">→</span></a><a href="/diagnostic-ia/" class="link-arrow plain">Le Diagnostic IA →</a></div>
            </div>`
  : `            <div class="cta-box animate delay-3">
                <p>A similar problem on your side? Let's talk for thirty minutes.</p>
                <div class="actions"><a href="${BOOKING.en}" class="btn btn-primary plain" data-booking target="_blank" rel="noopener noreferrer">Book a 30-minute call <span class="arr">→</span></a><a href="/en/ai-assessment/" class="link-arrow plain">The AI Assessment →</a></div>
            </div>`;

export const alt = (c: CaseStudy) => ({ fr: `/realisations/${c.slug}/`, en: `/en/case-studies/${c.slug_en}/` });
export const INDEX_ALT = { fr: "/realisations/", en: "/en/case-studies/" };

export function loadCases(): CaseStudy[] {
  const files = readdirSync(DRAFTS).filter((f) => f.endsWith(".json"));
  if (files.length === 0) { console.error("Aucun draft trouvé dans _drafts/"); process.exit(1); }
  return files
    .map((f) => JSON.parse(readFileSync(join(DRAFTS, f), "utf8")) as CaseStudy)
    .sort((a, b) => b.year.localeCompare(a.year) || (a.order ?? 99) - (b.order ?? 99));
}

// Carousel de screenshots — vanilla JS inline, aucune dépendance (CSP stricte).
// lang: "fr" | "en" — choisit alt/caption. Rendu uniquement si c.carousel existe.
export function carouselSection(c: CaseStudy, lang: "fr" | "en"): string {
  if (!c.carousel) return "";
  const t = lang === "fr" ? c.carousel.title : c.carousel.title_en;
  const intro = lang === "fr" ? c.carousel.intro : c.carousel.intro_en;
  const prev = lang === "fr" ? "Image précédente" : "Previous image";
  const next = lang === "fr" ? "Image suivante" : "Next image";
  const goTo = lang === "fr" ? "Aller à l'image" : "Go to image";
  const slides = c.carousel.images.map((img, i) => `                    <figure class="case-carousel-slide">
                        <img src="${img.src}" alt="${lang === "fr" ? img.alt : img.alt_en}" loading="lazy">
                        <figcaption>${lang === "fr" ? img.caption : img.caption_en}</figcaption>
                    </figure>`).join("\n");
  const dots = c.carousel.images.map((_, i) =>
    `<button class="case-carousel-dot" data-index="${i}" aria-label="${goTo} ${i + 1}"${i === 0 ? ' aria-current="true"' : ""}></button>`
  ).join("");
  return `
            <section class="case-carousel animate delay-3" role="region" aria-label="${t}">
                <h2>${t}</h2>
                <p>${intro}</p>
                <div class="case-carousel-track" id="carouselTrack" tabindex="0">
${slides}
                </div>
                <div class="case-carousel-nav">
                    <button class="case-carousel-btn" id="carouselPrev" aria-label="${prev}">‹</button>
                    <span class="case-carousel-count" id="carouselCount">1 / ${c.carousel.images.length}</span>
                    <button class="case-carousel-btn" id="carouselNext" aria-label="${next}">›</button>
                    <div class="case-carousel-dots" id="carouselDots">${dots}</div>
                </div>
            </section>
            <script>
            (function () {
                const track = document.getElementById('carouselTrack');
                const count = document.getElementById('carouselCount');
                const dots = Array.from(document.getElementById('carouselDots').children);
                const total = dots.length;
                let current = 0;
                function slideWidth() { return track.firstElementChild ? track.firstElementChild.getBoundingClientRect().width + 16 : track.clientWidth; }
                function goTo(i) { track.scrollTo({ left: Math.max(0, Math.min(i, total - 1)) * slideWidth(), behavior: 'smooth' }); }
                function sync() {
                    const i = Math.round(track.scrollLeft / slideWidth());
                    if (i === current || i < 0 || i >= total) return;
                    current = i;
                    count.textContent = (i + 1) + ' / ' + total;
                    dots.forEach((d, j) => j === i ? d.setAttribute('aria-current', 'true') : d.removeAttribute('aria-current'));
                }
                track.addEventListener('scroll', () => requestAnimationFrame(sync), { passive: true });
                document.getElementById('carouselPrev').addEventListener('click', () => goTo(current - 1));
                document.getElementById('carouselNext').addEventListener('click', () => goTo(current + 1));
                dots.forEach((d, i) => d.addEventListener('click', () => goTo(i)));
                track.addEventListener('keydown', (e) => {
                    if (e.key === 'ArrowLeft') { e.preventDefault(); goTo(current - 1); }
                    if (e.key === 'ArrowRight') { e.preventDefault(); goTo(current + 1); }
                });
            })();
            </script>`;
}

function figures(c: CaseStudy): string {
  return c.images.map((img) => `            <figure class="case-figure animate delay-3">
                <img src="${img.src}" alt="${img.alt}" loading="lazy">
                <figcaption>${img.caption}</figcaption>
            </figure>`).join("\n");
}

function casePage(c: CaseStudy): string {
  const canonical = `https://www.supergenial.be/realisations/${c.slug}/`;
  const live = c.url_live ? ` · <a href="${c.url_live}" target="_blank" rel="noopener noreferrer">Voir le site</a>` : "";
  const stack = c.stack.map((s) => `<span class="stack-tag">${s}</span>`).join(" ");
  return `${HEAD("fr", c.title + " · Super Génial", c.description, c.keywords, canonical, alt(c))}
${OPEN("fr", alt(c))}
        <article>
            <p class="eyebrow"><a href="/realisations/" class="plain">Réalisations</a></p>
            <h1 class="animate delay-1">${c.title}</h1>
            <p class="case-problem">Le problème&nbsp;: ${c.problem.charAt(0).toLowerCase() + c.problem.slice(1)}.</p>
            <p class="case-meta animate delay-2"><span>${c.type}</span><span>${c.client} · ${c.year}${live}</span><span>${stack}</span></p>
${figures(c)}
            <div class="article-body animate delay-3">
                ${c.body_html}
            </div>${carouselSection(c, "fr")}
${CTA("fr")}
        </article>
${FOOT("fr")}`;
}

function indexPage(cases: CaseStudy[]): string {
  const canonical = "https://www.supergenial.be/realisations/";
  const items = cases.map((c) => {
    const thumb = c.images[0] ? `                    <img class="case-thumb" src="${c.images[0].src}" alt="${c.images[0].alt}" loading="lazy">\n` : "";
    return `                <a href="/realisations/${c.slug}/" class="case-item plain">
${thumb}                    <div class="a-type">${c.type} · ${c.client} · ${c.year}</div>
                    <div class="a-problem">${c.problem}</div>
                    <div class="a-title">${c.title}</div>
                </a>`;
  }).join("\n");
  return `${HEAD("fr", "Réalisations : des outils en production · Super Génial", "Études de cas : outils internes, applications de gestion et sites conçus avec des agents IA, présentés par le problème métier qu'ils résolvent.", "réalisations, études de cas, outil interne, application de gestion, agents IA", canonical, INDEX_ALT)}
${OPEN("fr", INDEX_ALT)}
        <p class="eyebrow">Réalisations</p>
        <h1 class="animate delay-1">Des outils qui tournent tous les jours.</h1>
        <p class="intro animate delay-3">
            Chaque projet est présenté par le problème qu'il résout. Je les ai conçus avec des agents IA,
            de la spécification à la mise en ligne, et la plupart servent d'abord mes propres structures&nbsp;:
            je construis pour moi avant de proposer aux autres.
        </p>
        <img class="illu illu--small" src="/assets/illustrations/laptop-mug.webp" decoding="async" alt="Illustration au trait : un ordinateur portable et une tasse fumante, près d'une fenêtre" width="800" height="800">
        <div class="article-list animate delay-3">
${items}
        </div>
${CTA("fr")}
${FOOT("fr")}`;
}

// ---- Build ----
if (import.meta.main) {
  const cases = loadCases();
  for (const c of cases) {
    const dir = join(ROOT, c.slug);
    mkdirSync(dir, { recursive: true });
    writeFileSync(join(dir, "index.html"), casePage(c));
    console.log(`✓ realisations/${c.slug}/index.html`);
  }
  writeFileSync(join(ROOT, "index.html"), indexPage(cases));
  console.log(`✓ realisations/index.html (${cases.length} études de cas)`);
}
