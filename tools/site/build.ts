// build.ts — Génère les pages principales FR/EN à partir de tools/site/pages/*.ts,
// les pages de redirection des adresses supprimées et la page 404.
// Usage : bun tools/site/build.ts (pipeline complet : tools/README.md).

import { writeFileSync, mkdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { page } from "./layout.ts";
import { home } from "./pages/home.ts";
import { diagnostic } from "./pages/diagnostic.ts";
import { tarifs } from "./pages/tarifs.ts";
import { reprise } from "./pages/reprise.ts";
import { ARTICLES, articlePage, articlePaths, resourcesIndex } from "./pages/articles.ts";

const ROOT = dirname(dirname(dirname(new URL(import.meta.url).pathname)));

// Pages supprimées : GitHub Pages ne sait pas rediriger côté serveur, une page relais
// renvoie vers l'accueil. Sur Semisto OS, ce seront de vraies redirections 301.
const REDIRECTS: [string, string][] = [
  ["communication/index.html", "/"],
  ["en/communication/index.html", "/en/"],
];
const redirect = (to: string) => `<!DOCTYPE html>
<html lang="${to === "/" ? "fr" : "en"}">
<head>
    <meta charset="UTF-8">
    <title>Super Génial</title>
    <meta name="robots" content="noindex">
    <link rel="canonical" href="https://www.supergenial.be${to}">
    <meta http-equiv="refresh" content="0; url=${to}">
</head>
<body>
    <p><a href="${to}">Super Génial</a></p>
</body>
</html>
`;

const notFound = page({
  lang: "fr", path: "/404.html", alt: { fr: "/", en: "/en/" }, wide: true,
  title: "Page introuvable · Super Génial",
  description: "Cette adresse ne mène nulle part. Les liens de cette page vous ramènent vers l'accueil, le Diagnostic IA, les tarifs et les réalisations.",
  og: "home", ogAlt: "Super Génial",
  body: `
        <section class="page-hero">
            <div class="wrap page-hero-grid">
                <div>
                    <p class="eyebrow">Erreur 404</p>
                    <h1 class="display display--page">Cette adresse <em>ne mène nulle part.</em></h1>
                    <p class="lede">Elle a peut-être changé, ou le lien qui vous a amené ici est ancien. <span lang="en">This page does not exist; the links below still work.</span></p>
                    <div class="actions">
                        <a href="/" class="btn btn-primary plain">Retour à l'accueil <span class="arr">→</span></a>
                        <a href="/diagnostic-ia/" class="btn btn-line plain">Le Diagnostic IA</a>
                        <a href="/tarifs/" class="link-arrow plain">Les tarifs →</a>
                        <a href="/realisations/" class="link-arrow plain">Les réalisations →</a>
                    </div>
                </div>
                <img class="illu-side" src="/assets/illustrations/sg-404.webp" decoding="async" alt="Illustration au trait : un petit robot perplexe, une carte à l'envers, devant un pot vide" width="800" height="800">
            </div>
        </section>`,
}).replace("</title>", "</title>\n    <meta name=\"robots\" content=\"noindex\">");

const out: [string, string][] = [
  ["index.html", home("fr")],
  ["en/index.html", home("en")],
  ["diagnostic-ia/index.html", diagnostic("fr")],
  ["en/ai-assessment/index.html", diagnostic("en")],
  ["tarifs/index.html", tarifs("fr")],
  ["en/pricing/index.html", tarifs("en")],
  ["maintenance/index.html", reprise("fr")],
  ["en/maintenance/index.html", reprise("en")],
  ["ressources/index.html", resourcesIndex("fr")],
  ["en/resources/index.html", resourcesIndex("en")],
  ...ARTICLES.flatMap((a): [string, string][] => {
    const p = articlePaths(a);
    return [[`${p.fr.slice(1)}index.html`, articlePage(a, "fr")], [`${p.en.slice(1)}index.html`, articlePage(a, "en")]];
  }),
  ...REDIRECTS.map(([file, to]): [string, string] => [file, redirect(to)]),
  ["404.html", notFound],
];

for (const [rel, html] of out) {
  const file = join(ROOT, rel);
  mkdirSync(dirname(file), { recursive: true });
  writeFileSync(file, html);
  console.log(`✓ ${rel}`);
}
