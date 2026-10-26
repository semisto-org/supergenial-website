// layout.ts — La coquille commune du site : <head>, menu, pied de page, Plausible.
// Source unique : tools/site/build.ts l'utilise pour les pages principales,
// realisations/build.ts pour les études de cas, ressources/mainnav.ts pour
// remettre le menu et le pied de page à jour sur toutes les autres pages.

export type Lang = "fr" | "en";
export type Section = "diagnostic" | "pricing" | "cases" | "resources" | "reprise" | "legal" | null;

export const SITE_URL = "https://www.supergenial.be";

// Lien « Réserver un call de 30 minutes » : la page de réservation Notion Calendar
// de Michael. Tous les boutons data-booking du site pointent ici.
export const BOOKING: Record<Lang, string> = {
  fr: "https://calendar.notion.so/meet/michaelhulet/supergenial",
  en: "https://calendar.notion.so/meet/michaelhulet/supergenial",
};

// Statistiques de visite : Plausible auto-hébergé (stats.semisto.org).
export const PLAUSIBLE = `<script defer data-domain="supergenial.be" src="https://stats.semisto.org/js/script.js"></script>`;

export const NAV: Record<Lang, { label: string; href: string; key: Section }[]> = {
  fr: [
    { label: "Diagnostic IA", href: "/diagnostic-ia/", key: "diagnostic" },
    { label: "Tarifs", href: "/tarifs/", key: "pricing" },
    { label: "Réalisations", href: "/realisations/", key: "cases" },
    { label: "Ressources", href: "/ressources/", key: "resources" },
  ],
  en: [
    { label: "AI Assessment", href: "/en/ai-assessment/", key: "diagnostic" },
    { label: "Pricing", href: "/en/pricing/", key: "pricing" },
    { label: "Case studies", href: "/en/case-studies/", key: "cases" },
    { label: "Resources", href: "/en/resources/", key: "resources" },
  ],
};

export function sectionOf(path: string): Section {
  const p = path.replace(/^\//, "");
  if (/^(diagnostic-ia|en\/ai-assessment)\//.test(p)) return "diagnostic";
  if (/^(tarifs|en\/pricing)\//.test(p)) return "pricing";
  if (/^(realisations|en\/case-studies)\//.test(p)) return "cases";
  if (/^(ressources|en\/resources)\//.test(p)) return "resources";
  if (/^(maintenance|en\/maintenance)\//.test(p)) return "reprise";
  if (/^(mentions-legales|en\/legal)\//.test(p)) return "legal";
  return null;
}

const GLOBE = `<svg class="lang-globe" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M3 12h18"/><ellipse cx="12" cy="12" rx="4.2" ry="9"/></svg>`;
const BURGER = `<svg class="i-burger" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><path d="M4 7h16M4 12h16M4 17h16"/></svg><svg class="i-close" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><path d="M6 6l12 12M18 6L6 18"/></svg>`;

export const langPill = (lang: Lang, alt: { fr: string; en: string }) =>
  `<div class="lang-switch" aria-label="Language / Langue">${GLOBE}` +
  `<a href="${alt.fr}"${lang === "fr" ? ' class="is-active"' : ""}>FR</a>` +
  `<a href="${alt.en}"${lang === "en" ? ' class="is-active"' : ""}>EN</a></div>`;

export function nav(lang: Lang, active: Section, pill: string): string {
  const links = NAV[lang]
    .map((l) => `<a href="${l.href}" class="plain"${l.key === active ? ' aria-current="page"' : ""}>${l.label}</a>`)
    .join("");
  const home = lang === "fr" ? "/" : "/en/";
  const t = lang === "fr"
    ? { nav: "Navigation principale", menu: "Ouvrir le menu", cta: "Réserver un call" }
    : { nav: "Main navigation", menu: "Open menu", cta: "Book a call" };
  return (
    `<!--mainnav--><header class="site-head"><nav class="site-nav" aria-label="${t.nav}">` +
    `<a href="${home}" class="brand plain"><span class="brand-mark" aria-hidden="true"></span>Super Génial</a>` +
    `<button class="nav-toggle plain" type="button" aria-expanded="false" aria-controls="site-menu" aria-label="${t.menu}">${BURGER}</button>` +
    `<div class="nav-menu" id="site-menu">${links}</div>` +
    pill +
    `<a href="${BOOKING[lang]}" class="nav-cta plain" data-booking target="_blank" rel="noopener noreferrer">${t.cta}</a>` +
    `</nav></header><!--/mainnav-->`
  );
}

const SOCIAL = `<div class="foot-social">
            <a href="https://www.linkedin.com/in/michaelhulet/" rel="noopener noreferrer" target="_blank" aria-label="LinkedIn"><svg width="17" height="17" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M4.98 3.5a2.5 2.5 0 1 1 0 5 2.5 2.5 0 0 1 0-5ZM3 9h4v12H3V9Zm7 0h3.8v1.7h.05c.53-1 1.83-2.05 3.77-2.05 4.03 0 4.78 2.65 4.78 6.1V21h-4v-5.5c0-1.31-.02-3-1.83-3-1.83 0-2.11 1.43-2.11 2.9V21h-4V9Z"/></svg></a>
            <a href="https://github.com/mhulet" rel="noopener noreferrer" target="_blank" aria-label="GitHub"><svg width="17" height="17" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M12 2C6.48 2 2 6.48 2 12c0 4.42 2.87 8.17 6.84 9.5.5.09.66-.22.66-.48v-1.7c-2.78.6-3.37-1.34-3.37-1.34-.45-1.16-1.11-1.47-1.11-1.47-.91-.62.07-.6.07-.6 1 .07 1.53 1.03 1.53 1.03.89 1.53 2.34 1.09 2.91.83.09-.65.35-1.09.63-1.34-2.22-.25-4.56-1.11-4.56-4.94 0-1.09.39-1.98 1.03-2.68-.1-.25-.45-1.27.1-2.65 0 0 .84-.27 2.75 1.02a9.5 9.5 0 0 1 5 0c1.91-1.29 2.75-1.02 2.75-1.02.55 1.38.2 2.4.1 2.65.64.7 1.03 1.59 1.03 2.68 0 3.84-2.34 4.69-4.57 4.94.36.31.68.92.68 1.85v2.74c0 .27.16.58.67.48A10 10 0 0 0 22 12c0-5.52-4.48-10-10-10Z"/></svg></a>
            <a href="https://t.me/supergenialdotbe" rel="noopener noreferrer" target="_blank" aria-label="Telegram"><svg width="17" height="17" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M21.6 4.3 18.5 19c-.2 1-.9 1.3-1.8.8l-4.9-3.6-2.4 2.3c-.3.3-.5.5-1 .5l.3-4.9 8.9-8c.4-.3-.1-.5-.6-.2L5.9 13 1.1 11.5c-1-.3-1-1 .2-1.5l19-7.3c.9-.3 1.6.2 1.3 1.6Z"/></svg></a>
        </div>`;

export function footer(lang: Lang): string {
  const fr = lang === "fr";
  const links = fr
    ? [["/", "Accueil"], ["/diagnostic-ia/", "Diagnostic IA"], ["/tarifs/", "Tarifs"], ["/maintenance/", "Reprise d'application"], ["/realisations/", "Réalisations"], ["/ressources/", "Ressources"], ["/mentions-legales/", "Mentions légales"]]
    : [["/en/", "Home"], ["/en/ai-assessment/", "AI Assessment"], ["/en/pricing/", "Pricing"], ["/en/maintenance/", "Application take-over"], ["/en/case-studies/", "Case studies"], ["/en/resources/", "Resources"], ["/en/legal/", "Legal notice"]];
  const brand = fr
    ? `Moins de tableurs, <em>plus de mission.</em>`
    : `Fewer spreadsheets, <em>more mission.</em>`;
  const cta = fr ? "Réserver un call de 30 minutes" : "Book a 30-minute call";
  const legal = fr
    ? `Super Génial est une marque de <strong>Marco &amp; Vespucci SRL</strong>, société à responsabilité limitée de droit belge. Numéro d'entreprise et de TVA&nbsp;: BE&nbsp;0523.920.556. Siège&nbsp;: rue Ernest Feron 64, 5310 Eghezée, Belgique. Contact&nbsp;: <a href="mailto:team@supergenial.be">team@supergenial.be</a>. Éditeur responsable&nbsp;: Michael Hulet.`
    : `Super Génial is a brand of <strong>Marco &amp; Vespucci SRL</strong>, a Belgian private limited company. Company and VAT number: BE&nbsp;0523.920.556. Registered office: rue Ernest Feron 64, 5310 Eghezée, Belgium. Contact: <a href="mailto:team@supergenial.be">team@supergenial.be</a>. Publisher: Michael Hulet.`;
  return `<!--sitefoot--><footer class="site-foot">
            <div class="foot-top"><p class="foot-brand">${brand}</p><a href="${BOOKING[lang]}" class="btn btn-primary plain" data-booking target="_blank" rel="noopener noreferrer">${cta} <span class="arr">→</span></a></div>
            <nav class="foot-nav" aria-label="${fr ? "Pied de page" : "Footer"}">
                ${links.map(([h, l]) => `<a href="${h}" class="plain">${l}</a>`).join("\n                ")}
            </nav>
            <p class="foot-legal">${legal}</p>
            ${SOCIAL}
        </footer><!--/sitefoot-->`;
}

export const NAV_JS = `<script>/*mainnavjs*/(function(){var n=document.querySelector(".site-nav"),t=document.querySelector(".nav-toggle");if(!n||!t)return;t.addEventListener("click",function(){var o=n.classList.toggle("open");t.setAttribute("aria-expanded",o?"true":"false")});})();</script>`;

export type HeadOpts = {
  lang: Lang;
  path: string;                       // chemin de la page, ex. "/tarifs/"
  alt: { fr: string; en: string };    // chemins FR et EN (hreflang)
  title: string;
  description: string;
  og: string;                         // nom de la carte dans /assets/og/, sans extension
  ogAlt: string;
  jsonld?: object[];
  published?: string;                 // articles
  type?: "website" | "article";
};

export function head(o: HeadOpts): string {
  const url = SITE_URL + o.path;
  const og = `${SITE_URL}/assets/og/${o.og}.jpg`;
  const ld = (o.jsonld ?? []).map((j) => `\n    <script type="application/ld+json">${JSON.stringify(j)}</script>`).join("");
  return `<!DOCTYPE html>
<html lang="${o.lang}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${o.title}</title>
    <meta name="description" content="${o.description}">
    <meta name="author" content="Michael Hulet">
    <link rel="icon" href="/assets/favicon.svg" type="image/svg+xml">
    <link rel="apple-touch-icon" href="/assets/favicon.svg">
    <meta property="og:type" content="${o.type ?? "website"}">
    <meta property="og:title" content="${o.title}">
    <meta property="og:description" content="${o.description}">
    <meta property="og:url" content="${url}">
    <meta property="og:image" content="${og}">
    <meta property="og:image:width" content="1200">
    <meta property="og:image:height" content="630">
    <meta property="og:image:alt" content="${o.ogAlt}">
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="${o.title}">
    <meta name="twitter:description" content="${o.description}">
    <meta name="twitter:image" content="${og}">${o.published ? `\n    <meta property="article:published_time" content="${o.published}">` : ""}
    <link rel="canonical" href="${url}">
    <link rel="alternate" hreflang="fr" href="${SITE_URL}${o.alt.fr}">
    <link rel="alternate" hreflang="en" href="${SITE_URL}${o.alt.en}">
    <link rel="alternate" hreflang="x-default" href="${SITE_URL}${o.alt.fr}">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=EB+Garamond:ital,wght@0,400..600;1,400..600&family=Inter:wght@400..700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="/assets/css/site.css">
    ${PLAUSIBLE}${ld}
</head>`;
}

// Page complète. wide = pages larges (accueil, offres) ; sinon colonne de lecture.
export function page(o: HeadOpts & { body: string; wide?: boolean; bodyClass?: string }): string {
  const skip = o.lang === "fr" ? "Aller au contenu" : "Skip to content";
  return `${head(o)}
<body${o.bodyClass ? ` class="${o.bodyClass}"` : ""}>
<a class="skip-link plain" href="#contenu">${skip}</a>
    <main id="contenu"${o.wide ? ' class="wide"' : ""}>
        ${nav(o.lang, sectionOf(o.path), langPill(o.lang, o.alt))}
${o.body}
        ${footer(o.lang)}
    </main>
${NAV_JS}
</body>
</html>
`;
}

// ── Données structurées ──
export const orgLd = (lang: Lang) => ({
  "@context": "https://schema.org",
  "@type": "ProfessionalService",
  "@id": SITE_URL + "/#business",
  name: "Super Génial",
  legalName: "Marco & Vespucci SRL",
  url: SITE_URL + (lang === "fr" ? "/" : "/en/"),
  description: lang === "fr"
    ? "Outils internes et agents IA sur mesure pour les entreprises à impact de 5 à 100 personnes, Diagnostic IA à prix fixe et reprise d'applications web existantes."
    : "Custom internal tools and AI agents for impact-driven companies of 5 to 100 people, a fixed-price AI Assessment and take-over of existing web applications.",
  email: "team@supergenial.be",
  founder: { "@type": "Person", name: "Michael Hulet", url: "https://www.linkedin.com/in/michaelhulet/" },
  areaServed: [{ "@type": "Place", name: "Wallonie" }, { "@type": "Place", name: "Bruxelles" }, { "@type": "Place", name: "Europe" }],
  knowsAbout: ["internal tools", "AI agents", "custom business software", "Ruby on Rails", "web application maintenance", "legacy application modernization"],
  sameAs: ["https://www.linkedin.com/in/michaelhulet/", "https://github.com/mhulet", "https://t.me/supergenialdotbe"],
  vatID: "BE0523920556",
  address: { "@type": "PostalAddress", streetAddress: "Rue Ernest Feron 64", postalCode: "5310", addressLocality: "Eghezée", addressCountry: "BE" },
});

export const breadcrumbLd = (items: [string, string][]) => ({
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  itemListElement: items.map(([name, path], i) => ({ "@type": "ListItem", position: i + 1, name, item: SITE_URL + path })),
});

export const faqLd = (qa: [string, string][]) => ({
  "@context": "https://schema.org",
  "@type": "FAQPage",
  mainEntity: qa.map(([q, a]) => ({ "@type": "Question", name: q, acceptedAnswer: { "@type": "Answer", text: a.replace(/<[^>]+>/g, "") } })),
});

export const faqHtml = (qa: [string, string][]) =>
  `<div class="faq">\n${qa.map(([q, a]) => `                <details><summary>${q}</summary><p>${a}</p></details>`).join("\n")}\n            </div>`;
