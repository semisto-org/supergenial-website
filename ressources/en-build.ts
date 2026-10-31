// en-build.ts — Génère les pages EN des articles + l'index EN, et injecte le
// sélecteur de langue dans les pages FR existantes.
// Source : _drafts-bi/*.json (produits par la traduction). Usage : bun ressources/en-build.ts
// POST-BUILD OBLIGATOIRE : lancer ensuite `bun ressources/langswitch.ts` (toggle de
// langue FR/EN) puis `bun ressources/mainnav.ts` (menu principal du site).

import { readdirSync, readFileSync, writeFileSync, mkdirSync, existsSync, rmSync } from "node:fs";
import { join, dirname } from "node:path";

const ROOT = dirname(new URL(import.meta.url).pathname);      // .../ressources
const SITE = dirname(ROOT);                                   // repo root
const DRAFTS = join(ROOT, "_drafts-bi");
const EN_RES = join(SITE, "en", "resources");

type BiArticle = {
  n: number; fr_slug: string; en_slug: string; date: string; date_en: string;
  title_en: string; desc_en: string; keywords_en: string; body_html_en: string;
};

const CSS = readFileSync(join(ROOT, "_css.txt"), "utf8");

const HEAD = (title: string, description: string, keywords: string, canonical: string, extraOg = "") => `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${title}</title>
    <meta name="author" content="Michael Hulet">
    <meta name="description" content="${description}">
    <meta name="keywords" content="${keywords}">
    <meta property="og:title" content="${title}">
    <meta property="og:description" content="${description}">
    <meta property="og:type" content="website">
    <meta property="og:url" content="${canonical}">
    <link rel="canonical" href="${canonical}">${extraOg}
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700&family=Geist+Mono:wght@400;500&display=swap" rel="stylesheet">
    <style>${CSS}</style>
</head>`;

const GLOW = `
<div class="cursor-glow" id="cursorGlow"></div>
<script>
const glow = document.getElementById('cursorGlow');
let mx=0,my=0,gx=0,gy=0;
window.addEventListener('mousemove',(e)=>{mx=e.clientX;my=e.clientY;glow.classList.add('visible');});
window.addEventListener('mouseleave',()=>glow.classList.remove('visible'));
(function a(){gx+=(mx-gx)*0.1;gy+=(my-gy)*0.1;glow.style.left=gx+'px';glow.style.top=gy+'px';requestAnimationFrame(a);})();
</script>`;

function enArticlePage(a: BiArticle): string {
  const canonical = `https://www.supergenial.be/en/resources/${a.en_slug}/`;
  const og = `\n    <meta property="article:published_time" content="${a.date}">`;
  return `${HEAD(a.title_en + " — Super Génial", a.desc_en, a.keywords_en, canonical, og)}
<body>
    ${GLOW}
    <main>
        <a href="/en/resources/" class="back-link plain">← All resources</a> · <a href="/ressources/${a.fr_slug}/" class="plain">Français</a>
        <article>
            <h1 class="animate delay-1">${a.title_en}</h1>
            <p class="meta-date animate delay-2"><time datetime="${a.date}">${a.date_en}</time> · Super Génial</p>
            <div class="article-body animate delay-3">
                ${a.body_html_en}
            </div>
            <div class="cta-box animate delay-3">
                <p>Is your application affected?</p>
                <a href="/en/maintenance/" class="cta-btn">Get a read on your app <span>→</span></a>
            </div>
        </article>
    </main>
</body>
</html>
`;
}

function enIndexPage(articles: BiArticle[]): string {
  const canonical = "https://www.supergenial.be/en/resources/";
  const items = articles.map((a) => `                <a href="/en/resources/${a.en_slug}/" class="article-item plain">
                    <div class="a-date"><time datetime="${a.date}">${a.date_en}</time></div>
                    <div class="a-title">${a.title_en}</div>
                    <div class="a-desc">${a.desc_en}</div>
                </a>`).join("\n");
  return `${HEAD("Resources — Super Génial", "Clear guides on web-app upgrades: Rails, Ruby and Ubuntu end-of-life, migrations and maintenance.", "end of life, rails upgrade, rails migration, web application maintenance", canonical)}
<body>
    ${GLOW}
    <main>
        <a href="/en/" class="back-link plain">← Super Génial</a> · <a href="/ressources/" class="plain">Français</a>
        <h1 class="animate delay-1">Resources</h1>
        <p class="subtitle">What ages, and how to fix it.</p>
        <p class="intro animate delay-3">
            Clear pointers on the end-of-life dates and migrations that affect your web
            application: Rails, Ruby, Ubuntu, databases. Written to be useful even if you're
            not a developer. Unsure about your app? <a href="/en/maintenance/">Let's take a look</a>.
        </p>
        <div class="article-list animate delay-3">
${items}
        </div>
        <p class="footnote">New articles regularly. A specific question? <a href="mailto:team@supergenial.be">team@supergenial.be</a></p>
    </main>
</body>
</html>
`;
}

// Injecte un lien de langue dans une page FR existante, après le back-link plain.
function injectFrSwitch(filePath: string, enHref: string) {
  if (!existsSync(filePath)) { console.error(`  ⚠ FR introuvable : ${filePath}`); return; }
  let html = readFileSync(filePath, "utf8");
  if (html.includes('data-langswitch')) return; // idempotent
  const m = html.match(/(<a href="\/(?:ressources\/[^"]*|)" class="back-link plain">[^<]*<\/a>)/);
  if (!m) { console.error(`  ⚠ back-link non trouvé : ${filePath}`); return; }
  const inject = `${m[1]} · <a href="${enHref}" class="plain" data-langswitch>English</a>`;
  html = html.replace(m[1], inject);
  writeFileSync(filePath, html);
}

// ---- Build ----
const files = readdirSync(DRAFTS).filter((f) => f.endsWith(".json"));
if (files.length === 0) { console.error("Aucun draft dans _drafts-bi/"); process.exit(1); }

const articles: BiArticle[] = files
  .map((f) => JSON.parse(readFileSync(join(DRAFTS, f), "utf8")) as BiArticle)
  .sort((a, b) => b.date.localeCompare(a.date));

for (const a of articles) {
  const dir = join(EN_RES, a.en_slug);
  mkdirSync(dir, { recursive: true });
  writeFileSync(join(dir, "index.html"), enArticlePage(a));
  console.log(`✓ en/resources/${a.en_slug}/index.html`);
  // switcher côté FR
  injectFrSwitch(join(ROOT, a.fr_slug, "index.html"), `/en/resources/${a.en_slug}/`);
}

mkdirSync(EN_RES, { recursive: true });
writeFileSync(join(EN_RES, "index.html"), enIndexPage(articles));
console.log(`✓ en/resources/index.html (${articles.length} articles)`);

// switcher sur l'index FR des ressources
injectFrSwitch(join(ROOT, "index.html"), "/en/resources/");

rmSync(DRAFTS, { recursive: true, force: true });
console.log("✓ _drafts-bi/ nettoyé");
