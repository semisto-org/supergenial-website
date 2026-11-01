// Génère les pages EN des études de cas (/en/case-studies/) à partir des MÊMES
// drafts bilingues que build.ts (realisations/_drafts/*.json — jamais supprimés).
// Usage : bun realisations/en-build.ts
// POST-BUILD : bun ressources/langswitch.ts (toggle FR/EN) puis bun ressources/mainnav.ts (menu principal).

import { writeFileSync, mkdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { HEAD, OPEN, FOOT, CTA, alt, INDEX_ALT, loadCases, carouselSection, type CaseStudy } from "./build.ts";

const ROOT = dirname(new URL(import.meta.url).pathname);      // .../realisations
const SITE = dirname(ROOT);                                   // repo root
const EN_DIR = join(SITE, "en", "case-studies");

function figures(c: CaseStudy): string {
  return c.images.map((img) => `            <figure class="case-figure animate delay-3">
                <img src="${img.src}" alt="${img.alt_en}" loading="lazy">
                <figcaption>${img.caption_en}</figcaption>
            </figure>`).join("\n");
}

function casePage(c: CaseStudy): string {
  const canonical = `https://www.supergenial.be/en/case-studies/${c.slug_en}/`;
  const live = c.url_live ? ` · <a href="${c.url_live}" target="_blank" rel="noopener noreferrer">Visit the site</a>` : "";
  const stack = c.stack.map((s) => `<span class="stack-tag">${s}</span>`).join(" ");
  return `${HEAD("en", c.title_en + " · Super Génial", c.description_en, c.keywords_en, canonical, alt(c))}
${OPEN("en", alt(c))}
        <article>
            <p class="eyebrow"><a href="/en/case-studies/" class="plain">Case studies</a></p>
            <h1 class="animate delay-1">${c.title_en}</h1>
            <p class="case-problem">The problem: ${c.problem_en.charAt(0).toLowerCase() + c.problem_en.slice(1)}.</p>
            <p class="case-meta animate delay-2"><span>${c.type_en}</span><span>${c.client} · ${c.year}${live}</span><span>${stack}</span></p>
${figures(c)}
            <div class="article-body animate delay-3">
                ${c.body_html_en}
            </div>${carouselSection(c, "en")}
${CTA("en")}
        </article>
${FOOT("en")}`;
}

function indexPage(cases: CaseStudy[]): string {
  const canonical = "https://www.supergenial.be/en/case-studies/";
  const items = cases.map((c) => {
    const thumb = c.images[0] ? `                    <img class="case-thumb" src="${c.images[0].src}" alt="${c.images[0].alt_en}" loading="lazy">\n` : "";
    return `                <a href="/en/case-studies/${c.slug_en}/" class="case-item plain">
${thumb}                    <div class="a-type">${c.type_en} · ${c.client} · ${c.year}</div>
                    <div class="a-problem">${c.problem_en}</div>
                    <div class="a-title">${c.title_en}</div>
                </a>`;
  }).join("\n");
  return `${HEAD("en", "Case studies: tools in production · Super Génial", "Case studies: internal tools, management applications and websites built with AI agents, presented by the business problem they solve.", "case studies, internal tool, management application, AI agents", canonical, INDEX_ALT)}
${OPEN("en", INDEX_ALT)}
        <p class="eyebrow">Case studies</p>
        <h1 class="animate delay-1">Tools used every day.</h1>
        <p class="intro animate delay-3">
            Each project is presented by the problem it solves. I built them with AI agents,
            from specification to go-live, and most of them serve my own organisations first:
            I build for myself before offering it to others.
        </p>
        <img class="illu illu--small" src="/assets/illustrations/laptop-mug.webp" decoding="async" alt="Line drawing: a laptop and a steaming mug by a window" width="800" height="800">
        <div class="article-list animate delay-3">
${items}
        </div>
${CTA("en")}
${FOOT("en")}`;
}

// ---- Build ----
const cases = loadCases();
for (const c of cases) {
  const dir = join(EN_DIR, c.slug_en);
  mkdirSync(dir, { recursive: true });
  writeFileSync(join(dir, "index.html"), casePage(c));
  console.log(`✓ en/case-studies/${c.slug_en}/index.html`);
}
writeFileSync(join(EN_DIR, "index.html"), indexPage(cases));
console.log(`✓ en/case-studies/index.html (${cases.length} case studies)`);
