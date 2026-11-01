// Tarifs FR / EN.
import { page, BOOKING, faqHtml, faqLd, breadcrumbLd, type Lang } from "../layout.ts";

const ALT = { fr: "/tarifs/", en: "/en/pricing/" };
const BK = (l: Lang) => `href="${BOOKING[l]}" data-booking target="_blank" rel="noopener noreferrer"`;

const FAQ: Record<Lang, [string, string][]> = {
  fr: [
    ["Combien coûte un projet sur mesure ?", "Tout dépend de ce qu'il remplace. Pour donner un ordre de grandeur, un outil ciblé sur un seul processus démarre autour de 5 000 €, et un back-office complet qui remplace plusieurs abonnements se chiffre en dizaines de milliers d'euros. Le devis exact, à prix fixe, sort du Diagnostic IA."],
    ["Pourquoi pas une facturation à l'heure ?", "Parce qu'avec les agents IA, la même fonctionnalité peut prendre dix fois moins de temps qu'avant. Facturer à l'heure récompenserait la lenteur. Vous payez un résultat, à un prix connu d'avance."],
    ["C'est quoi un « point » ?", "L'unité des petites évolutions incluses dans l'abonnement, à la place des heures. 1 point : un petit ajustement (un champ, un libellé). 2 points : une petite évolution (un filtre, un e-mail automatique). Environ 5 points : un écran complet. Au-delà du quota, l'évolution est chiffrée à part, d'avance."],
    ["Les points non utilisés sont-ils reportés ?", "Le quota se renouvelle chaque mois et n'est pas cumulable. Si vos besoins grandissent durablement, on ajuste le palier plutôt que d'accumuler."],
    ["Puis-je changer de palier ou résilier ?", "Oui. L'abonnement est sans engagement, modifiable ou résiliable d'un mois à l'autre. Et le code reste à vous dans tous les cas."],
    ["Qui facture ?", "Super Génial est une marque de Marco & Vespucci SRL, société de droit belge (TVA BE 0523.920.556). Les factures sont émises par la SRL et envoyées par Peppol aux entreprises belges."],
  ],
  en: [
    ["How much does a custom project cost?", "It depends on what it replaces. As a rough guide, a tool focused on a single process starts around €5,000, and a complete back-office replacing several subscriptions runs into tens of thousands of euros. The exact fixed-price quote comes out of the AI Assessment."],
    ["Why not bill by the hour?", "Because with AI agents, the same feature can take ten times less time than before. Hourly billing would reward slowness. You pay for a result, at a price known upfront."],
    ["What is a “point”?", "The unit for the small improvements included in the subscription, instead of hours. 1 point: a small tweak (a field, a label). 2 points: a small improvement (a filter, an automatic e-mail). About 5 points: a full screen. Beyond the quota, the change is priced separately, upfront."],
    ["Do unused points roll over?", "The quota renews every month and does not accumulate. If your needs grow for good, we adjust the tier rather than stockpile."],
    ["Can I change tier or cancel?", "Yes. The subscription has no lock-in and can be changed or cancelled from one month to the next. And the code stays yours in every case."],
    ["Who sends the invoices?", "Super Génial is a brand of Marco & Vespucci SRL, a Belgian company (VAT BE 0523.920.556). Invoices are issued by the company and sent over Peppol to Belgian businesses."],
  ],
};

const tiers = (l: Lang) => {
  const fr = l === "fr";
  const T = fr ? [
    ["Essentiel", "390", "Garder l'outil sain et en ligne.", ["Surveillance et alertes", "Maintenance technique et mises à jour", "Correction des bugs", "Documentation tenue à jour", "Réponse sous 72 h"], false],
    ["Évolution", "890", "Maintenir et faire évoluer en continu.", ["Tout l'Essentiel, plus :", "5 points d'évolution par mois", "Réponse sous 48 h", "Point d'avancement trimestriel"], true],
    ["Partenaire", "1 890", "Un copilote produit au quotidien.", ["Tout l'Évolution, plus :", "12 points d'évolution par mois", "Traitement prioritaire", "Réponse sous 24 h", "Feuille de route copilotée"], false],
  ] : [
    ["Essential", "390", "Keep the tool healthy and online.", ["Monitoring and alerts", "Technical maintenance and updates", "Bug fixes", "Documentation kept up to date", "Reply within 72 h"], false],
    ["Evolution", "890", "Maintain and improve continuously.", ["Everything in Essential, plus:", "5 improvement points per month", "Reply within 48 h", "Quarterly progress review"], true],
    ["Partner", "1,890", "A product co-pilot, day to day.", ["Everything in Evolution, plus:", "12 improvement points per month", "Priority handling", "Reply within 24 h", "Co-piloted roadmap"], false],
  ];
  return T.map(([name, amt, f, items, feat]) => `
                    <div class="tier${feat ? " is-featured" : ""}">
                        ${feat ? `<span class="badge">${fr ? "Le plus choisi" : "Most chosen"}</span>` : ""}<h3>${name}</h3>
                        <div class="amount">${fr ? `${amt} €` : `€${amt}`} <small>${fr ? "/ mois HTVA" : "/ month excl. VAT"}</small></div>
                        <p class="for">${f}</p>
                        <ul>${(items as string[]).map((i) => `<li>${i}</li>`).join("")}</ul>
                    </div>`).join("");
};

const FR = `
        <section class="page-hero">
            <div class="wrap page-hero-grid">
                <div>
                    <p class="eyebrow">Tarifs</p>
                    <h1 class="display display--page">Deux prix fixes. <em>Le reste, sur devis, annoncé d'avance.</em></h1>
                    <p class="lede">Je ne vends pas des heures, je vends des résultats. Le diagnostic et les abonnements ont un prix affiché&nbsp;; chaque construction reçoit un devis à prix fixe, écrit avant de commencer. Aucun compteur d'heures, aucune surprise sur la facture.</p>
                </div>
                <img class="illu-side" src="/assets/illustrations/tarifs-escalier.webp" decoding="async" alt="Illustration au trait : un escalier qui mène à un petit drapeau" width="800" height="800">
            </div>
        </section>

        <section class="sec">
            <div class="wrap">
                <div class="offer">
                    <div class="offer-card is-first">
                        <div class="step">Le point de départ <b>1</b></div>
                        <h3>Diagnostic IA</h3>
                        <div class="price">3 500 € <small>prix fixe, HTVA</small></div>
                        <p>Deux semaines pour chiffrer ce que vos tableurs, vos abonnements et vos tâches répétitives vous coûtent, et décider quoi construire.</p>
                        <ul><li>Interviews, cartographie, inventaire des abonnements</li><li>Top 3 des opportunités, comparées sur cinq ans</li><li>Intégralement déduit si on construit dans les 90 jours</li></ul>
                        <a href="/diagnostic-ia/" class="link-arrow plain">Le Diagnostic en détail →</a>
                    </div>
                    <div class="offer-card">
                        <div class="step">La construction <b>2</b></div>
                        <h3>Votre outil sur mesure</h3>
                        <div class="price">Sur devis <small>prix fixe, écrit avant de commencer</small></div>
                        <p>De la spécification à la mise en ligne, un prix unique pour un outil livré, documenté et en production.</p>
                        <ul><li>Cadrage et spécification écrite</li><li>Développement avec des agents IA, sous ma supervision</li><li>Tests, mise en ligne, prise en main</li><li>Code source remis sur GitHub</li></ul>
                        <a href="#faq" class="link-arrow plain">Les ordres de grandeur →</a>
                    </div>
                    <div class="offer-card">
                        <div class="step">La vie de l'outil <b>3</b></div>
                        <h3>Abonnement</h3>
                        <div class="price">dès 390 € <small>/ mois, HTVA, sans engagement</small></div>
                        <p>Une fois en ligne, l'outil doit être surveillé, tenu à jour et continuer d'évoluer. Un montant fixe, un périmètre clair.</p>
                        <ul><li>Trois paliers, détaillés ci-dessous</li><li>Petites évolutions incluses en points</li><li>Modifiable d'un mois à l'autre</li></ul>
                        <a href="#abonnements" class="link-arrow plain">Comparer les paliers →</a>
                    </div>
                </div>
            </div>
        </section>

        <section class="sec sec--soft" id="abonnements">
            <div class="wrap">
                <p class="eyebrow">Abonnements</p>
                <h2 class="h-sec">Votre outil reste en vie, <em>et continue d'évoluer.</em></h2>
                <p class="sec-intro">L'abonnement remplace les « packs d'heures »&nbsp;: un montant fixe, et un flux de petites évolutions sans renégocier à chaque fois.</p>
                <div class="tiers">${tiers("fr")}
                </div>
                <div class="callout" id="points"><b>C'est quoi un « point »&nbsp;?</b> Plutôt que des heures, j'utilise des points de complexité comme unité de valeur.
                    <ul class="scale"><li><b>1 pt</b>Petit ajustement&nbsp;: un champ, un libellé, une couleur</li><li><b>2 pts</b>Petite évolution&nbsp;: un filtre, un tri, un e-mail automatique</li><li><b>~5 pts</b>Évolution standard&nbsp;: un écran complet</li></ul>
                    Un mois type en Évolution&nbsp;: un filtre de recherche (2 pts), une relance e-mail automatique (2 pts) et un libellé corrigé (1 pt), soit 5 points, inclus. Au-delà du quota, l'évolution est chiffrée à part, avant de commencer.</div>
            </div>
        </section>

        <section class="sec">
            <div class="wrap">
                <div class="door door--flat">
                    <div class="door-k">ou</div>
                    <div>
                        <h3>Vous avez déjà une application qui vieillit&nbsp;?</h3>
                        <p>Je la reprends&nbsp;: audit à prix fixe annoncé d'avance, remise à niveau sur devis, puis l'abonnement de votre choix pour qu'elle ne prenne plus de retard.</p>
                    </div>
                    <a href="/maintenance/" class="btn btn-line plain">Reprise d'application <span class="arr">→</span></a>
                </div>
            </div>
        </section>

        <section class="sec sec--soft" id="faq">
            <div class="wrap">
                <p class="eyebrow">Bon à savoir</p>
                <h2 class="h-sec">Questions fréquentes</h2>
                ${faqHtml(FAQ.fr)}
                <p class="fine">Tarifs hors TVA, en euros. Chaque construction fait l'objet d'une proposition écrite, qui prévaut sur les montants publiés ici.</p>
            </div>
        </section>

        <section class="sec band">
            <div class="wrap contact-band">
                <div>
                    <p class="eyebrow">Une question de budget&nbsp;?</p>
                    <h2 class="h-sec">Parlons chiffres, <em>simplement.</em></h2>
                </div>
                <div>
                    <p>En trente minutes, je vous dis si le diagnostic a du sens chez vous et dans quel ordre de grandeur se situerait une construction.</p>
                    <div class="actions"><a ${BK("fr")} class="btn btn-light plain">Réserver un call de 30 minutes <span class="arr">→</span></a></div>
                    <div class="contact-alt"><a href="mailto:team@supergenial.be">team@supergenial.be</a></div>
                </div>
            </div>
        </section>
`;

const EN = `
        <section class="page-hero">
            <div class="wrap page-hero-grid">
                <div>
                    <p class="eyebrow">Pricing</p>
                    <h1 class="display display--page">Two fixed prices. <em>The rest on quote, agreed upfront.</em></h1>
                    <p class="lede">I don't sell hours, I sell results. The assessment and the subscriptions have a published price; each build gets a fixed-price quote, written before work starts. No hour counter, no surprise on the invoice.</p>
                </div>
                <img class="illu-side" src="/assets/illustrations/tarifs-escalier.webp" decoding="async" alt="Line drawing: a staircase leading to a small flag" width="800" height="800">
            </div>
        </section>

        <section class="sec">
            <div class="wrap">
                <div class="offer">
                    <div class="offer-card is-first">
                        <div class="step">The starting point <b>1</b></div>
                        <h3>AI Assessment</h3>
                        <div class="price">€3,500 <small>fixed price, excl. VAT</small></div>
                        <p>Two weeks to cost what your spreadsheets, subscriptions and repetitive tasks take from you, and decide what to build.</p>
                        <ul><li>Interviews, process map, subscriptions inventory</li><li>Top 3 opportunities, compared over five years</li><li>Fully deducted if we build within 90 days</li></ul>
                        <a href="/en/ai-assessment/" class="link-arrow plain">The Assessment in detail →</a>
                    </div>
                    <div class="offer-card">
                        <div class="step">The build <b>2</b></div>
                        <h3>Your custom tool</h3>
                        <div class="price">On quote <small>fixed price, written before we start</small></div>
                        <p>From specification to go-live, one price for a tool delivered, documented and in production.</p>
                        <ul><li>Scoping and written specification</li><li>Development with AI agents, under my supervision</li><li>Testing, go-live, onboarding</li><li>Source code handed over on GitHub</li></ul>
                        <a href="#faq" class="link-arrow plain">Rough budgets →</a>
                    </div>
                    <div class="offer-card">
                        <div class="step">The tool's life <b>3</b></div>
                        <h3>Subscription</h3>
                        <div class="price">from €390 <small>/ month, excl. VAT, no lock-in</small></div>
                        <p>Once live, the tool needs monitoring, updates and continued improvement. A fixed amount, a clear scope.</p>
                        <ul><li>Three tiers, detailed below</li><li>Small improvements included as points</li><li>Changeable month to month</li></ul>
                        <a href="#subscriptions" class="link-arrow plain">Compare tiers →</a>
                    </div>
                </div>
            </div>
        </section>

        <section class="sec sec--soft" id="subscriptions">
            <div class="wrap">
                <p class="eyebrow">Subscriptions</p>
                <h2 class="h-sec">Your tool stays alive, <em>and keeps improving.</em></h2>
                <p class="sec-intro">The subscription replaces “bundles of hours”: a fixed amount, and a steady flow of small improvements without renegotiating every time.</p>
                <div class="tiers">${tiers("en")}
                </div>
                <div class="callout" id="points"><b>What is a “point”?</b> Instead of hours, I use complexity points as the unit of value.
                    <ul class="scale"><li><b>1 pt</b>Small tweak: a field, a label, a colour</li><li><b>2 pts</b>Small improvement: a filter, a sort, an automatic e-mail</li><li><b>~5 pts</b>Standard improvement: a full screen</li></ul>
                    A typical month on Evolution: a search filter (2 pts), an automatic reminder e-mail (2 pts) and a corrected label (1 pt), 5 points, included. Beyond the quota, the change is priced separately, before work starts.</div>
            </div>
        </section>

        <section class="sec">
            <div class="wrap">
                <div class="door door--flat">
                    <div class="door-k">or</div>
                    <div>
                        <h3>Already have an application that is ageing?</h3>
                        <p>I take it over: a fixed-price audit agreed upfront, an upgrade on quote, then the subscription of your choice so it never falls behind again.</p>
                    </div>
                    <a href="/en/maintenance/" class="btn btn-line plain">Application take-over <span class="arr">→</span></a>
                </div>
            </div>
        </section>

        <section class="sec sec--soft" id="faq">
            <div class="wrap">
                <p class="eyebrow">Good to know</p>
                <h2 class="h-sec">Frequently asked questions</h2>
                ${faqHtml(FAQ.en)}
                <p class="fine">Prices excl. VAT, in euros. Each build comes with a written proposal, which prevails over the amounts published here.</p>
            </div>
        </section>

        <section class="sec band">
            <div class="wrap contact-band">
                <div>
                    <p class="eyebrow">A budget question?</p>
                    <h2 class="h-sec">Let's talk numbers, <em>plainly.</em></h2>
                </div>
                <div>
                    <p>In thirty minutes I will tell you whether the assessment makes sense for you, and the rough budget a build would need.</p>
                    <div class="actions"><a ${BK("en")} class="btn btn-light plain">Book a 30-minute call <span class="arr">→</span></a></div>
                    <div class="contact-alt"><a href="mailto:team@supergenial.be">team@supergenial.be</a></div>
                </div>
            </div>
        </section>
`;

export const tarifs = (lang: Lang) => page({
  lang, path: ALT[lang], alt: ALT, wide: true,
  title: lang === "fr" ? "Tarifs : diagnostic, construction, abonnement · Super Génial" : "Pricing: assessment, build, subscription · Super Génial",
  description: lang === "fr"
    ? "Diagnostic IA à 3 500 €, outils sur mesure sur devis à prix fixe, abonnements de 390 à 1 890 € par mois, sans engagement. Jamais à l'heure."
    : "AI Assessment at €3,500, custom tools on fixed-price quote, subscriptions from €390 to €1,890 a month, no lock-in. Never by the hour.",
  og: "tarifs", ogAlt: lang === "fr" ? "Tarifs Super Génial : deux prix fixes, le reste sur devis" : "Super Génial pricing: two fixed prices, the rest on quote",
  jsonld: [faqLd(FAQ[lang]), breadcrumbLd([["Super Génial", lang === "fr" ? "/" : "/en/"], [lang === "fr" ? "Tarifs" : "Pricing", ALT[lang]]])],
  body: lang === "fr" ? FR : EN,
});
