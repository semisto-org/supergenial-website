// Diagnostic IA FR / EN.
import { page, BOOKING, faqHtml, faqLd, breadcrumbLd, SITE_URL, type Lang } from "../layout.ts";

const ALT = { fr: "/diagnostic-ia/", en: "/en/ai-assessment/" };
const BK = (l: Lang) => `href="${BOOKING[l]}" data-booking target="_blank" rel="noopener noreferrer"`;

const FAQ: Record<Lang, [string, string][]> = {
  fr: [
    ["Pourquoi payer, alors que des audits IA gratuits existent ?", "Un audit gratuit est un argumentaire commercial déguisé : il conclut toujours qu'il faut acheter ce que son auteur vend. Ici, vous payez un travail réel, des interviews, une cartographie, des chiffres, et le rapport vous appartient. Vous pouvez le mettre en œuvre avec moi, avec quelqu'un d'autre, ou seul."],
    ["Et si le diagnostic conclut qu'il n'y a rien d'intéressant à faire ?", "Alors le rapport le dira, avec les raisons. Il y a presque toujours quelques heures par semaine à récupérer ou un abonnement de trop, mais savoir qu'il ne faut pas investir maintenant vous évite des dépenses bien plus grandes qu'un diagnostic."],
    ["Faut-il déjà être « digitalisé » pour que ça ait du sens ?", "Non. Je pars de vos processus réels, même s'ils vivent sur papier, dans des cahiers ou dans la tête de deux personnes. C'est justement là que le diagnostic révèle le plus de valeur."],
    ["Combien de temps ça demande à mon équipe ?", "Environ une heure par personne interviewée, une réunion de cadrage au départ et une restitution d'une heure trente à la fin. Le reste du travail se fait de mon côté."],
    ["Allez-vous me conseiller de tout remplacer par du sur-mesure ?", "Non. Un outil sur mesure a lui aussi un coût mensuel. Ce qui est standard (comptabilité, messagerie) reste souvent mieux servi par un logiciel du marché. Le diagnostic compare les deux options sur cinq ans, honnêtement."],
    ["Existe-t-il des aides publiques pour ce type de mission ?", "Les dispositifs wallons de soutien au numérique et à l'IA (Start IA, chèques-entreprises) évoluent régulièrement. Selon votre situation et le calendrier des appels, je vous oriente vers ce qui existe au moment de votre demande."],
  ],
  en: [
    ["Why pay, when free AI audits exist?", "A free audit is a sales pitch in disguise: it always concludes you should buy what its author sells. Here you pay for real work, interviews, a process map, numbers, and the report is yours. You can implement it with me, with someone else, or on your own."],
    ["What if the assessment finds nothing worth doing?", "Then the report will say so, with the reasons. There are almost always a few hours a week to win back or a subscription too many, but knowing you should not invest now saves you far more than the cost of an assessment."],
    ["Do we need to be “digital” already for this to make sense?", "No. I start from your real processes, even if they live on paper, in notebooks or in two people's heads. That is exactly where the assessment uncovers the most value."],
    ["How much time does it take from my team?", "About one hour per person interviewed, a kick-off meeting and a 90-minute presentation at the end. The rest of the work happens on my side."],
    ["Will you tell me to replace everything with custom software?", "No. A custom tool has a monthly cost too. Standard needs (accounting, e-mail) are often better served by off-the-shelf software. The assessment compares both options over five years, honestly."],
    ["Is there public funding for this kind of work?", "Walloon schemes supporting digital and AI projects (Start IA, chèques-entreprises) change regularly. Depending on your situation and the timing of calls, I point you to what exists when you get in touch."],
  ],
};

const FR = `
        <section class="page-hero">
            <div class="wrap page-hero-grid">
                <div>
                    <p class="eyebrow">Diagnostic IA · le point de départ</p>
                    <h1 class="display display--page">Deux semaines pour savoir <em>ce qui vous fait perdre du temps et de l'argent.</em></h1>
                    <p class="lede">Tout le monde vous dit que l'IA va changer votre métier. Personne ne vous dit par où commencer, ni ce que ça vaut chez vous. Ce diagnostic répond, avec des chiffres&nbsp;: vos tableurs, vos abonnements, vos tâches répétitives, et ce qu'on peut automatiser en premier.</p>
                    <div class="actions">
                        <a ${BK("fr")} class="btn btn-primary plain">Réserver un call de 30 minutes <span class="arr">→</span></a>
                    </div>
                </div>
                <div class="price-tag">
                    <div class="k">Prix fixe</div>
                    <div class="v">3 500 € <small>HTVA</small></div>
                    <p>Tout compris, annoncé d'avance.</p>
                    <p>Intégralement déduit de la construction si on construit ensemble dans les 90 jours.</p>
                </div>
            </div>
        </section>

        <section class="sec">
            <div class="wrap">
                <p class="eyebrow">Ce que le diagnostic regarde</p>
                <h2 class="h-sec">Trois questions, <em>des réponses chiffrées.</em></h2>
                <div class="tiles tiles--3">
                    <div class="tile"><b>Où passe le temps de votre équipe&nbsp;?</b><span>Les recopies, les vérifications, les relances, les tâches qu'un agent IA pourrait préparer pour qu'un humain valide.</span></div>
                    <div class="tile"><b>Combien vous coûtent vos abonnements&nbsp;?</b><span>L'inventaire complet de vos logiciels en ligne&nbsp;: prix par utilisateur, paliers, fonctions vraiment utilisées, recoupements.</span></div>
                    <div class="tile"><b>Qu'est-ce qui vaut la peine d'être construit&nbsp;?</b><span>Sur-mesure contre abonnements, comparés sur cinq ans. Parfois la bonne réponse est de ne rien construire.</span></div>
                </div>
            </div>
        </section>

        <section class="sec sec--soft">
            <div class="wrap">
                <p class="eyebrow">Le déroulé</p>
                <h2 class="h-sec">Deux semaines, <em>cinq étapes.</em></h2>
                <p class="sec-intro">Je viens chez vous, j'écoute vos équipes décrire leur vraie journée de travail, et je repars avec de quoi cartographier l'entreprise entière. Votre temps&nbsp;: environ une heure par personne interviewée, plus la restitution.</p>
                <ol class="timeline">
                    <li><b>Cadrage</b>Vos priorités, vos contraintes, vos outils et vos abonnements actuels.</li>
                    <li><b>Interviews</b>Les personnes qui font le travail, pas seulement la direction.</li>
                    <li><b>Cartographie</b>Vos processus, vos flux d'information, vos tableurs.</li>
                    <li><b>Analyse</b>Chaque opportunité évaluée en impact (heures, euros) et en faisabilité.</li>
                    <li><b>Restitution</b>Le rapport présenté et discuté avec vous, décisions en main.</li>
                </ol>
            </div>
        </section>

        <section class="sec">
            <div class="wrap">
                <p class="eyebrow">Ce que vous recevez</p>
                <h2 class="h-sec">Un rapport court, <em>fait pour décider.</em></h2>
                <p class="sec-intro">Pas 80 pages de généralités sur l'intelligence artificielle. Un document que vous lisez en une soirée et que vous actionnez le lendemain.</p>
                <div class="tiles">
                    <div class="tile"><b>Le top 3 des opportunités</b><span>Les trois endroits où un outil ou un agent IA rapporte le plus chez vous, chiffrés en heures gagnées et en coût de mise en œuvre.</span></div>
                    <div class="tile"><b>L'inventaire de vos abonnements</b><span>Ce que vous payez, ce que vous utilisez, et l'économie possible sur cinq ans si une partie est remplacée par un outil à vous.</span></div>
                    <div class="tile"><b>La carte de vos processus</b><span>Ce que le diagnostic a vu de votre fonctionnement, souvent une découverte en soi pour la direction.</span></div>
                    <div class="tile"><b>Un plan 30-60-90 jours</b><span>Par quoi commencer, dans quel ordre, et ce que ça demande à vos équipes. Pas un plan à trois ans.</span></div>
                </div>
                <div class="callout"><b>Ce que ce diagnostic n'est pas.</b> Une promesse de « transformation ». Je cherche des heures gagnées et des euros économisés sur un ou deux processus concrets&nbsp;: c'est comme ça que l'IA entre utilement dans une entreprise. Et si rien de sérieux n'émerge, le rapport le dira honnêtement.</div>
            </div>
        </section>

        <section class="sec sec--soft">
            <div class="wrap cols-2">
                <div>
                    <p class="eyebrow">Pourquoi moi</p>
                    <h2 class="h-sec">Vécu, <em>puis construit.</em></h2>
                    <img class="illu-side illu-side--left" src="/assets/illustrations/diagnostic-loupe.webp" decoding="async" alt="Illustration au trait : une loupe posée sur un schéma de processus" width="800" height="800">
                </div>
                <div class="prose">
                    <p>En vingt ans, j'ai été des deux côtés du comptoir&nbsp;: analyste-programmeur, mais aussi co-fondateur d'un magasin, d'un lieu d'accueil avec gîtes et salles, d'une association de formation, de startups et d'e-commerces. Je connais la caisse qui ne croise pas le stock, le planning des réservations qui déborde, les inscriptions gérées à la main, les devis qui traînent.</p>
                    <p>Depuis 2023, je conçois des applications avec des agents IA, et je les installe d'abord dans mes propres structures avant de les proposer aux autres. Quand j'analyse votre entreprise, je ne découvre pas votre métier&nbsp;: je reconnais vos processus, et je sais lesquels un outil ou un agent peut prendre en charge aujourd'hui.</p>
                    <p>Et je construis ce que je recommande. Le rapport n'est pas fait pour dormir dans un tiroir.</p>
                </div>
            </div>
        </section>

        <section class="sec">
            <div class="wrap">
                <p class="eyebrow">Bon à savoir</p>
                <h2 class="h-sec">Questions fréquentes</h2>
                ${faqHtml(FAQ.fr)}
                <p class="fine">Prix hors TVA. Diagnostic mené en Wallonie et à Bruxelles, sur site&nbsp;; ailleurs en Belgique et en Europe, on en parle.</p>
            </div>
        </section>

        <section class="sec band">
            <div class="wrap contact-band">
                <div>
                    <p class="eyebrow">La suite</p>
                    <h2 class="h-sec">On regarde ensemble <em>ce qui coince&nbsp;?</em></h2>
                </div>
                <div>
                    <p>Trente minutes pour voir si un diagnostic a du sens chez vous. Si ce n'est pas le cas, je vous le dirai.</p>
                    <div class="actions"><a ${BK("fr")} class="btn btn-light plain">Réserver un call de 30 minutes <span class="arr">→</span></a></div>
                    <div class="contact-alt"><a href="mailto:team@supergenial.be">team@supergenial.be</a><a href="/tarifs/">Voir tous les tarifs</a></div>
                </div>
            </div>
        </section>
`;

const EN = `
        <section class="page-hero">
            <div class="wrap page-hero-grid">
                <div>
                    <p class="eyebrow">AI Assessment · the starting point</p>
                    <h1 class="display display--page">Two weeks to find out <em>what costs you time and money.</em></h1>
                    <p class="lede">Everyone tells you AI will change your business. Nobody tells you where to start, or what it is worth for you. This assessment answers with numbers: your spreadsheets, your subscriptions, your repetitive tasks, and what to automate first.</p>
                    <div class="actions">
                        <a ${BK("en")} class="btn btn-primary plain">Book a 30-minute call <span class="arr">→</span></a>
                    </div>
                </div>
                <div class="price-tag">
                    <div class="k">Fixed price</div>
                    <div class="v">€3,500 <small>excl. VAT</small></div>
                    <p>All included, agreed upfront.</p>
                    <p>Fully deducted from the build if we build together within 90 days.</p>
                </div>
            </div>
        </section>

        <section class="sec">
            <div class="wrap">
                <p class="eyebrow">What the assessment looks at</p>
                <h2 class="h-sec">Three questions, <em>answers in numbers.</em></h2>
                <div class="tiles tiles--3">
                    <div class="tile"><b>Where does your team's time go?</b><span>Copying, checking, chasing, the tasks an AI agent could prepare for a human to approve.</span></div>
                    <div class="tile"><b>What do your subscriptions really cost?</b><span>A full inventory of your online software: per-user prices, tiers, features actually used, overlaps.</span></div>
                    <div class="tile"><b>What is worth building?</b><span>Custom versus subscriptions, compared over five years. Sometimes the right answer is to build nothing.</span></div>
                </div>
            </div>
        </section>

        <section class="sec sec--soft">
            <div class="wrap">
                <p class="eyebrow">How it runs</p>
                <h2 class="h-sec">Two weeks, <em>five steps.</em></h2>
                <p class="sec-intro">I come to you, listen to your teams describe their real working day, and leave with enough to map the whole company. Your time: about one hour per person interviewed, plus the presentation.</p>
                <ol class="timeline">
                    <li><b>Scoping</b>Your priorities, constraints, current tools and subscriptions.</li>
                    <li><b>Interviews</b>The people who do the work, not just management.</li>
                    <li><b>Mapping</b>Your processes, information flows and spreadsheets.</li>
                    <li><b>Analysis</b>Each opportunity rated for impact (hours, euros) and feasibility.</li>
                    <li><b>Presentation</b>The report presented and discussed with you, decisions in hand.</li>
                </ol>
            </div>
        </section>

        <section class="sec">
            <div class="wrap">
                <p class="eyebrow">What you get</p>
                <h2 class="h-sec">A short report, <em>built for deciding.</em></h2>
                <p class="sec-intro">Not 80 pages of AI generalities. A document you read in an evening and act on the next day.</p>
                <div class="tiles">
                    <div class="tile"><b>The top 3 opportunities</b><span>The three places where a tool or an AI agent pays off most for you, costed in hours saved and implementation cost.</span></div>
                    <div class="tile"><b>Your subscriptions inventory</b><span>What you pay, what you use, and the possible savings over five years if part of it is replaced by a tool you own.</span></div>
                    <div class="tile"><b>A map of your processes</b><span>What the assessment saw of how you work, often a discovery in itself for management.</span></div>
                    <div class="tile"><b>A 30-60-90 day plan</b><span>Where to start, in which order, and what it asks of your teams. Not a three-year plan.</span></div>
                </div>
                <div class="callout"><b>What this assessment is not.</b> A promise of “transformation”. I look for hours saved and euros spared on one or two concrete processes: that is how AI usefully enters a company. And if nothing serious comes up, the report will say so honestly.</div>
            </div>
        </section>

        <section class="sec sec--soft">
            <div class="wrap cols-2">
                <div>
                    <p class="eyebrow">Why me</p>
                    <h2 class="h-sec">Lived it, <em>then built it.</em></h2>
                    <img class="illu-side illu-side--left" src="/assets/illustrations/diagnostic-loupe.webp" decoding="async" alt="Line drawing: a magnifying glass over a process diagram" width="800" height="800">
                </div>
                <div class="prose">
                    <p>Over twenty years I have been on both sides of the counter: analyst-programmer, but also co-founder of a shop, a guest house with venues, a training association, start-ups and online shops. I know the till that doesn't match the stock, the overflowing booking calendar, registrations handled by hand, quotes that drag on.</p>
                    <p>Since 2023 I have been building applications with AI agents, and I install them in my own organisations first before offering them to others. When I analyse your company, I am not discovering your business: I recognise your processes, and I know which ones a tool or an agent can take on today.</p>
                    <p>And I build what I recommend. The report is not meant to sleep in a drawer.</p>
                </div>
            </div>
        </section>

        <section class="sec">
            <div class="wrap">
                <p class="eyebrow">Good to know</p>
                <h2 class="h-sec">Frequently asked questions</h2>
                ${faqHtml(FAQ.en)}
                <p class="fine">Prices excl. VAT. Assessment carried out on site in Wallonia and Brussels; elsewhere in Belgium and Europe, let's talk.</p>
            </div>
        </section>

        <section class="sec band">
            <div class="wrap contact-band">
                <div>
                    <p class="eyebrow">Next step</p>
                    <h2 class="h-sec">Shall we look at <em>what's stuck?</em></h2>
                </div>
                <div>
                    <p>Thirty minutes to see whether an assessment makes sense for you. If it doesn't, I will tell you.</p>
                    <div class="actions"><a ${BK("en")} class="btn btn-light plain">Book a 30-minute call <span class="arr">→</span></a></div>
                    <div class="contact-alt"><a href="mailto:team@supergenial.be">team@supergenial.be</a><a href="/en/pricing/">See all pricing</a></div>
                </div>
            </div>
        </section>
`;

const serviceLd = (lang: Lang) => ({
  "@context": "https://schema.org",
  "@type": "Service",
  name: lang === "fr" ? "Diagnostic IA" : "AI Assessment",
  serviceType: lang === "fr" ? "Diagnostic IA et inventaire des abonnements logiciels" : "AI assessment and software subscriptions inventory",
  provider: { "@id": SITE_URL + "/#business" },
  areaServed: ["Wallonie", "Bruxelles"],
  url: SITE_URL + ALT[lang],
  offers: { "@type": "Offer", price: "3500", priceCurrency: "EUR", priceSpecification: { "@type": "PriceSpecification", price: "3500", priceCurrency: "EUR", valueAddedTaxIncluded: false } },
});

export const diagnostic = (lang: Lang) => page({
  lang, path: ALT[lang], alt: ALT, wide: true,
  title: lang === "fr" ? "Diagnostic IA pour entreprises à impact · Super Génial" : "AI Assessment for impact-driven companies · Super Génial",
  description: lang === "fr"
    ? "Deux semaines et 3 500 € pour chiffrer ce que vos tableurs, vos abonnements et vos tâches répétitives vous coûtent, et ce qu'il faut automatiser en premier."
    : "Two weeks and €3,500 to cost what your spreadsheets, subscriptions and repetitive tasks take from you, and what to automate first.",
  og: "diagnostic", ogAlt: lang === "fr" ? "Diagnostic IA : deux semaines pour savoir ce qui vous fait perdre du temps et de l'argent" : "AI Assessment: two weeks to find out what costs you time and money",
  jsonld: [serviceLd(lang), faqLd(FAQ[lang]), breadcrumbLd([["Super Génial", lang === "fr" ? "/" : "/en/"], [lang === "fr" ? "Diagnostic IA" : "AI Assessment", ALT[lang]]])],
  body: lang === "fr" ? FR : EN,
});
