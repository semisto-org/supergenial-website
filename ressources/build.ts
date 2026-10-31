// Génère la page Ressources + une page par article à partir des drafts JSON.
// Usage : bun ressources/build.ts
// Les drafts (_drafts/*.json) sont la source ; les pages HTML sont générées.

import { readdirSync, readFileSync, writeFileSync, mkdirSync, rmSync } from "node:fs";
import { join, dirname } from "node:path";

const ROOT = dirname(new URL(import.meta.url).pathname);
const DRAFTS = join(ROOT, "_drafts");

type Article = {
  n: number;
  slug: string;
  title: string;
  date: string;      // ISO, pour <time> et tri
  date_fr: string;   // affichage humain
  description: string;
  keywords: string;
  body_html: string;
};

const HEAD = (title: string, description: string, keywords: string, canonical: string, extraOg = "") => `<!DOCTYPE html>
<html lang="fr">
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

const CSS = `
* { margin: 0; padding: 0; box-sizing: border-box; }
:root {
    --bg: #ffffff; --text-primary: #171717; --text-secondary: #737373;
    --link-underline: #a3a3a3; --link-hover: #000000;
    --accent-1: #6366f1; --accent-2: #8b5cf6; --glow: rgba(99, 102, 241, 0.15);
    --card-bg: #ffffff; --card-border: #e5e5e5; --soft-bg: #f5f5f5;
}
body::before {
    content: ""; position: fixed; top: 0; left: 0; width: 100%; height: 100%;
    pointer-events: none; opacity: 0.03; z-index: 1000;
    background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)'/%3E%3C/svg%3E");
}
body {
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", "Roboto", "Helvetica Neue", Arial, sans-serif;
    background-color: var(--bg); color: var(--text-primary); line-height: 1.6; font-size: 16px;
    -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale;
}
@keyframes fadeUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
@keyframes gradientShift { 0%, 100% { background-position: 0% 50%; } 50% { background-position: 100% 50%; } }
@keyframes subtitleIn { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
.animate { animation: fadeUp 0.8s ease-out forwards; opacity: 0; }
.delay-1 { animation-delay: 0.1s; } .delay-2 { animation-delay: 0.2s; } .delay-3 { animation-delay: 0.3s; }
main { max-width: 720px; margin: 0 auto; padding: 3rem 1.5rem; position: relative; }
.cursor-glow {
    position: fixed; width: 600px; height: 600px;
    background: radial-gradient(circle at center, var(--glow) 0%, transparent 60%);
    pointer-events: none; z-index: -1; transform: translate(-50%, -50%);
    transition: opacity 0.3s ease; opacity: 0;
}
.cursor-glow.visible { opacity: 1; }
@media (min-width: 768px) { main { margin-top: 4rem; padding: 0 1.5rem 5rem; } body { font-size: 18px; } }
.back-link { display: inline-block; font-size: 14px; color: var(--text-secondary); margin-bottom: 2.5rem; }
h1 { font-size: 32px; font-weight: 600; margin-bottom: 0.5rem; letter-spacing: -0.02em; line-height: 1.2; }
@media (min-width: 768px) { h1 { font-size: 40px; } }
.subtitle {
    font-size: 20px; margin-bottom: 2rem; font-weight: 500; color: var(--accent-1);
    background: linear-gradient(135deg, var(--accent-1), var(--accent-2), var(--accent-1));
    background-size: 200% 200%; -webkit-background-clip: text; -webkit-text-fill-color: transparent;
    background-clip: text; opacity: 0;
    animation: subtitleIn 0.8s ease-out 0.2s forwards, gradientShift 4s ease 0.2s infinite;
}
@media (min-width: 768px) { .subtitle { font-size: 24px; } }
.intro { font-size: 16px; margin-bottom: 0.75rem; color: var(--text-secondary); max-width: 40rem; }
@media (min-width: 768px) { .intro { font-size: 18px; } }
.meta-date { font-size: 14px; color: var(--text-secondary); margin-bottom: 2.5rem; }
/* Article body */
.article-body { max-width: 40rem; }
.article-body h2 { font-size: 22px; font-weight: 600; letter-spacing: -0.01em; margin: 2.5rem 0 0.75rem; }
@media (min-width: 768px) { .article-body h2 { font-size: 26px; } }
.article-body h3 { font-size: 18px; font-weight: 600; margin: 1.75rem 0 0.5rem; }
.article-body p { margin: 1rem 0; }
.article-body ul { margin: 1rem 0 1rem 1.25rem; display: flex; flex-direction: column; gap: 0.4rem; }
.article-body li { line-height: 1.55; }
.article-body strong { font-weight: 600; }
/* CTA box */
.cta-box {
    margin-top: 3rem; padding: 1.5rem 1.35rem; border: 1px solid var(--card-border);
    border-radius: 16px; background-color: var(--card-bg);
}
.cta-box p { margin: 0 0 0.75rem; font-weight: 500; }
.cta-box .cta-btn {
    display: inline-flex; align-items: center; gap: 0.5rem; padding: 0.7rem 1.4rem;
    border-radius: 999px; background: linear-gradient(135deg, var(--accent-1), var(--accent-2));
    color: #fff; font-weight: 500; font-size: 15px;
    box-shadow: 0 6px 18px -6px rgba(99, 102, 241, 0.5); transition: transform 0.2s ease;
}
.cta-box .cta-btn::after { display: none; }
.cta-box .cta-btn:hover { color: #fff; transform: translateY(-2px); }
/* Resources index */
.article-list { display: flex; flex-direction: column; gap: 0; margin-top: 1rem; }
.article-item {
    display: block; padding: 1.5rem 0; border-bottom: 1px solid var(--card-border);
    transition: padding-left 0.2s ease;
}
.article-item:hover { padding-left: 0.4rem; }
.article-item .a-date { font-size: 13px; color: var(--text-secondary); font-variant-numeric: tabular-nums; }
.article-item .a-title { font-size: 19px; font-weight: 600; margin: 0.3rem 0; letter-spacing: -0.01em; }
.article-item .a-desc { font-size: 15px; color: var(--text-secondary); }
a { color: var(--text-primary); text-decoration: none; position: relative; transition: color 0.2s ease; }
a.plain::after, .article-item::after { display: none; }
.article-body a:not(.plain), .intro a { color: var(--text-primary); }
.article-body a::after, .intro a::after {
    content: ''; position: absolute; bottom: -2px; left: 0; width: 100%; height: 1px;
    background: var(--link-underline); transition: background 0.2s ease, transform 0.3s ease; transform-origin: left;
}
a:hover { color: var(--link-hover); }
.article-body a:hover::after, .intro a:hover::after { background: linear-gradient(90deg, var(--accent-1), var(--accent-2)); transform: scaleX(1.05); }
.article-item .a-title, .article-item .a-date, .article-item .a-desc { color: inherit; }
.article-item:hover .a-title { color: var(--link-hover); }
.footnote { margin-top: 3rem; font-size: 13px; color: var(--text-secondary); }
.illu-article { display: block; margin: 1.5rem auto 2rem; max-width: min(340px, 75%); height: auto; }
@media (prefers-reduced-motion: reduce) { .animate, .subtitle { animation: none; opacity: 1; } }
`;

const GLOW_SCRIPT = `
<div class="cursor-glow" id="cursorGlow"></div>
<script>
const glow = document.getElementById('cursorGlow');
let mx=0,my=0,gx=0,gy=0;
window.addEventListener('mousemove',(e)=>{mx=e.clientX;my=e.clientY;glow.classList.add('visible');});
window.addEventListener('mouseleave',()=>glow.classList.remove('visible'));
(function a(){gx+=(mx-gx)*0.1;gy+=(my-gy)*0.1;glow.style.left=gx+'px';glow.style.top=gy+'px';requestAnimationFrame(a);})();
</script>`;

function articlePage(a: Article): string {
  const canonical = `https://www.supergenial.be/ressources/${a.slug}/`;
  const og = `\n    <meta property="article:published_time" content="${a.date}">`;
  return `${HEAD(a.title + " — Super Génial", a.description, a.keywords, canonical, og)}
<body>
    ${GLOW_SCRIPT}
    <main>
        <a href="/ressources/" class="back-link plain">← Toutes les ressources</a>
        <article>
            <h1 class="animate delay-1">${a.title}</h1>
            <p class="meta-date animate delay-2"><time datetime="${a.date}">${a.date_fr}</time> · Super Génial</p>
            <img class="illu-article" src="/assets/illustrations/ressources/${a.slug}.png" decoding="async" alt="Illustration de l'article" width="800" height="800">
            <div class="article-body animate delay-3">
                ${a.body_html}
            </div>
            <div class="cta-box animate delay-3">
                <p>Votre application est concernée ?</p>
                <a href="/maintenance/" class="cta-btn">Faire le point sur votre app <span>→</span></a>
            </div>
        </article>
    </main>
</body>
</html>
`;
}

function indexPage(articles: Article[]): string {
  const canonical = "https://www.supergenial.be/ressources/";
  const items = articles.map((a) => `                <a href="/ressources/${a.slug}/" class="article-item plain">
                    <div class="a-date"><time datetime="${a.date}">${a.date_fr}</time></div>
                    <div class="a-title">${a.title}</div>
                    <div class="a-desc">${a.description}</div>
                </a>`).join("\n");
  return `${HEAD("Ressources — Super Génial", "Guides et repères sur les mises à jour d'applications web : fins de support Rails, Ruby, Ubuntu, migrations et maintenance.", "fin de support, mise à jour rails, migration rails, maintenance application web", canonical)}
<body>
    ${GLOW_SCRIPT}
    <main>
        <a href="/" class="back-link plain">← Super Génial</a>
        <h1 class="animate delay-1">Ressources</h1>
        <p class="subtitle">Ce qui vieillit, et comment y remédier.</p>
        <p class="intro animate delay-3">
            Des repères clairs sur les fins de support et les migrations qui concernent
            votre application web : Rails, Ruby, Ubuntu, bases de données. Écrit pour être
            utile même si vous n'êtes pas développeur. Un doute sur votre app ?
            <a href="/maintenance/">Voyons ça ensemble</a>.
        </p>
        <div class="article-list animate delay-3">
${items}
        </div>
        <p class="footnote">Nouveaux articles régulièrement. Une question précise ? <a href="mailto:team@supergenial.be">team@supergenial.be</a></p>
    </main>
</body>
</html>
`;
}

// ---- Build ----
const files = readdirSync(DRAFTS).filter((f) => f.endsWith(".json"));
if (files.length === 0) { console.error("Aucun draft trouvé dans _drafts/"); process.exit(1); }

const articles: Article[] = files
  .map((f) => JSON.parse(readFileSync(join(DRAFTS, f), "utf8")) as Article)
  .sort((a, b) => b.date.localeCompare(a.date)); // plus récent d'abord

for (const a of articles) {
  const dir = join(ROOT, a.slug);
  mkdirSync(dir, { recursive: true });
  writeFileSync(join(dir, "index.html"), articlePage(a));
  console.log(`✓ ressources/${a.slug}/index.html`);
}

writeFileSync(join(ROOT, "index.html"), indexPage(articles));
console.log(`✓ ressources/index.html (${articles.length} articles)`);

// Nettoyage des drafts (source consommée)
rmSync(DRAFTS, { recursive: true, force: true });
console.log("✓ _drafts/ nettoyé");
