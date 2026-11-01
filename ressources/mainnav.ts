// mainnav.ts — Remet la coquille commune (menu, pied de page, Plausible, polices) sur
// toutes les pages FR et EN, y compris celles qui ne sont pas générées par
// tools/site/build.ts (anciens articles, mentions légales). La coquille vient de
// tools/site/layout.ts, source unique.
// Idempotent (marqueurs <!--mainnav-->, <!--sitefoot-->, /*mainnavjs*/). Étape de
// post-build, TOUJOURS après langswitch.ts. Usage : bun ressources/mainnav.ts

import { readFileSync, writeFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { execSync } from "node:child_process";
import { nav, footer, sectionOf, NAV_JS, PLAUSIBLE, fingerprintAssets } from "../tools/site/layout.ts";

const ROOT = dirname(dirname(new URL(import.meta.url).pathname)); // repo root

const files = execSync(`find . \\( -name index.html -o -name 404.html \\) -not -path "./node_modules/*" -not -path "./tools/*"`, { cwd: ROOT })
  .toString()
  .trim()
  .split("\n")
  .map((f) => f.replace(/^\.\//, ""));

let done = 0;
const skipped: string[] = [];
for (const rel of files) {
  const file = join(ROOT, rel);
  let html = readFileSync(file, "utf8");
  if (!html.includes("<main")) continue; // pages de redirection
  const lang: "fr" | "en" = rel.startsWith("en/") ? "en" : "fr";

  const pillMatch = html.match(/<div class="lang-switch"[\s\S]*?<\/div>/);
  if (!pillMatch) {
    skipped.push(`${rel} (pas de lang-switch — lancer langswitch.ts d'abord)`);
    continue;
  }
  const head = nav(lang, sectionOf("/" + rel.replace(/index\.html$|404\.html$/, "")), pillMatch[0]);

  if (html.includes("<!--mainnav-->")) {
    html = html.replace(/<!--mainnav-->[\s\S]*?<!--\/mainnav-->/, head);
  } else {
    const topbar = html.match(/<div class="topbar[^"]*">[\s\S]*?<\/div>\s*<\/div>/);
    if (!topbar) { skipped.push(`${rel} (pas de .topbar)`); continue; }
    html = html.replace(topbar[0], head);
  }

  if (html.includes("<!--sitefoot-->")) {
    html = html.replace(/<!--sitefoot-->[\s\S]*?<!--\/sitefoot-->/, footer(lang));
  } else if (/<footer class="site-foot">/.test(html)) {
    html = html.replace(/<footer class="site-foot">[\s\S]*?<\/footer>/, footer(lang));
  } else {
    html = html.replace("</main>", `        ${footer(lang)}\n    </main>`);
  }

  if (html.includes("/*mainnavjs*/")) {
    html = html.replace(/<script>\/\*mainnavjs\*\/[\s\S]*?<\/script>/, NAV_JS);
  } else {
    html = html.replace("</body>", NAV_JS + "\n</body>");
  }

  if (!html.includes("stats.semisto.org")) html = html.replace("</head>", `    ${PLAUSIBLE}\n</head>`);
  html = fingerprintAssets(html);

  writeFileSync(file, html);
  done++;
}
if (skipped.length) console.error(`\n⚠ ignorées :\n  ${skipped.join("\n  ")}`);
console.log(`✓ coquille commune sur ${done} pages.`);
