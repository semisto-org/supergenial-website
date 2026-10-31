// Accueil FR / EN.
import { page, BOOKING, orgLd, type Lang } from "../layout.ts";

const ALT = { fr: "/", en: "/en/" };
const BK = (l: Lang) => `href="${BOOKING[l]}" data-booking target="_blank" rel="noopener noreferrer"`;

const ICON_CODE = `<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m8 7-5 5 5 5M16 7l5 5-5 5M13.5 4l-3 16"/></svg>`;
const ICON_LOCK = `<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="4" y="10.5" width="16" height="10" rx="2.5"/><path d="M8 10.5V7.5a4 4 0 0 1 8 0v3"/></svg>`;

const PROOFS = {
  fr: [
    ["/realisations/claudy/", "/assets/realisations/claudy/calendrier.webp", "Calendrier d'occupation des gîtes et espaces d'un tiers-lieu", "Outil interne", "Réservations, paiements, reporting et vie collective dans un seul outil", "Claudy · Les 4 Sources"],
    ["/realisations/tranches-de-vie/", "/assets/realisations/tranches-de-vie/admin-fournee.webp", "Back-office de planification des fournées d'une boulangerie", "E-commerce et production", "Les commandes en ligne planifient chaque fournée, au gramme près", "Tranches de Vie"],
    ["/realisations/terranova/", "/assets/realisations/terranova/projets.webp", "Liste des projets d'une plateforme collaborative", "Plateforme sur mesure", "Un outil de projet taillé pour son métier, à la place d'un logiciel générique", "Terranova · Semisto"],
  ],
  en: [
    ["/en/case-studies/claudy/", "/assets/realisations/claudy/calendrier.webp", "Occupancy calendar of a shared estate's lodges and venues", "Internal tool", "Bookings, payments, reporting and community life in one tool", "Claudy · Les 4 Sources"],
    ["/en/case-studies/tranches-de-vie/", "/assets/realisations/tranches-de-vie/admin-fournee.webp", "Back-office planning a bakery's batches", "E-commerce and production", "Online orders plan every bake, down to the gram", "Tranches de Vie"],
    ["/en/case-studies/terranova/", "/assets/realisations/terranova/projets.webp", "Project list of a collaborative platform", "Custom platform", "A project tool built for the work, instead of generic software", "Terranova · Semisto"],
  ],
};

const proofs = (l: Lang) => PROOFS[l].map(([href, src, alt, k, h, who]) => `
                    <a href="${href}" class="proof plain">
                        <div class="shot"><img src="${src}" alt="${alt}" loading="lazy" width="1600" height="1000"></div>
                        <div class="body"><div class="k">${k}</div><h3>${h}</h3><div class="who">${who}</div></div>
                    </a>`).join("");

const REFS = `<a class="plain" href="https://www.d-ici.be" target="_blank" rel="noopener noreferrer"><img class="sq" src="/assets/logos/dici.webp" alt="d'ici" width="120" height="120" loading="lazy"></a>
                    <a class="plain" href="https://www.silvea.org" target="_blank" rel="noopener noreferrer"><img src="/assets/logos/silvea.webp" alt="Silvéa" width="322" height="120" loading="lazy"></a>
                    <a class="plain" href="https://www.upcyclinarium.com" target="_blank" rel="noopener noreferrer"><img class="sq" src="/assets/logos/upcyclinarium.svg" alt="Upcyclinarium" width="400" height="400" loading="lazy"></a>
                    <a class="plain" href="https://www.novabirra.com" target="_blank" rel="noopener noreferrer"><img src="/assets/logos/novabirra.webp" alt="Novabirra" width="298" height="120" loading="lazy"></a>
                    <a class="plain" href="https://www.semisto.org" target="_blank" rel="noopener noreferrer"><img src="/assets/logos/semisto.webp" alt="Semisto" width="261" height="120" loading="lazy"></a>
                    <a class="plain" href="https://www.les4sources.be" target="_blank" rel="noopener noreferrer"><img class="sq" src="/assets/logos/les-4-sources.webp" alt="Les 4 Sources" width="75" height="120" loading="lazy"></a>
                    <a href="https://tranchesdevie.les4sources.be" target="_blank" rel="noopener noreferrer">Tranches de Vie</a>
                    <a href="https://www.petitkiwi.be" target="_blank" rel="noopener noreferrer">Petit Kiwi</a>
                    <a class="txt" href="https://www.notranet.net" target="_blank" rel="noopener noreferrer">Compagnies des Notaires du Hainaut, de Namur et du Luxembourg</a>`;

const FR = `
        <section class="hero">
            <div class="wrap hero-grid">
                <div>
                    <p class="eyebrow">Outils internes et agents IA sur mesure</p>
                    <h1 class="display">Vos outils sur mesure, <em>qui travaillent à votre place.</em></h1>
                    <p class="lede">Je remplace vos tableurs, vos tâches répétitives et vos abonnements empilés par <strong>des outils internes et des agents IA construits pour votre entreprise</strong>. Le code vous appartient, et votre équipe retrouve du temps pour sa mission.</p>
                    <div class="actions">
                        <a ${BK("fr")} class="btn btn-primary plain">Réserver un call de 30 minutes <span class="arr">→</span></a>
                        <a href="/diagnostic-ia/" class="btn btn-line plain">Le Diagnostic IA</a>
                    </div>
                    <div class="hero-for" aria-label="Pour qui">
                        <span>Pour les entreprises à impact</span><span>5 à 100 personnes</span>
                    </div>
                </div>
                <figure class="hero-avatar"><img src="/assets/brand/supergenial-avatar.svg" alt="L'avatar de Super Génial : un bloc noir qui sourit" width="512" height="512"><figcaption><a href="#lettre">Michael Hulet, depuis Les 4 Sources, à Yvoir</a></figcaption></figure>
            </div>
        </section>

        <section class="sec letter-sec" id="lettre">
            <div class="wrap letter">
                <div class="letter-photo-wrap"><img class="letter-photo" src="/assets/lieu/michael-hulet.webp" alt="Portrait de Michael Hulet" width="400" height="400" loading="lazy"></div>
                <div class="letter-body">
                    <p class="eyebrow">Un mot avant de commencer</p>
                    <p class="letter-hello">Bonjour, je m'appelle Michael.</p>
                    <p>Je code en freelance depuis 2004. Ce qui m'a appris à construire des outils utiles, c'est d'en être régulièrement l'un des utilisateurs&nbsp;: un magasin, un lieu d'accueil avec gîtes et salles, un e-commerce, une association. Je connais la caisse qui ne croise pas le stock, le planning de réservations qui déborde, les inscriptions gérées à la main.</p>
                    <p>Depuis 2023, je construis avec des agents IA les outils dont mes propres structures ont besoin. <em>Claudy</em> fait tourner Les 4 Sources, le tiers-lieu où je vis à Yvoir. Pour l'association Semisto, <em>My Semisto</em> porte la dynamique collective et <em>Terranova</em> cartographie les projets des équipes. Ce qui a fait ses preuves chez nous, je le propose aux entreprises qui portent elles aussi une mission durable.</p>
                    <p>Avec Super Génial, vous avez un seul interlocuteur, un code qui vous appartient et des outils pensés pour durer.</p>
                    <p class="letter-sign">Michael</p>
                </div>
            </div>
            <script>(function(){var w=document.querySelectorAll(".letter-photo-wrap");if(!("IntersectionObserver" in window)){w.forEach(function(e){e.classList.add("in")});return}var o=new IntersectionObserver(function(es){es.forEach(function(e){if(e.isIntersecting){e.target.classList.add("in");o.unobserve(e.target)}})},{threshold:.35});w.forEach(function(e){o.observe(e)})})();</script>
        </section>

        <section class="sec">
            <div class="wrap">
                <p class="eyebrow">Ce qui coûte cher sans se voir</p>
                <h2 class="h-sec">Deux fuites silencieuses <em>dans votre budget.</em></h2>
                <div class="pains">
                    <div class="pain">
                        <div class="num">01</div>
                        <h3>Les tableurs qui font tourner l'entreprise</h3>
                        <p>Commandes, inscriptions, stocks, plannings : tout passe par un fichier que tout le monde craint d'ouvrir. Il ne coûte rien à l'achat. Il se paie en heures de recopie, en erreurs et en dépendance à une seule personne.</p>
                        <ul><li>Une information saisie deux ou trois fois</li><li>Des versions qui se contredisent</li><li>Une seule personne qui sait comment ça marche</li></ul>
                    </div>
                    <div class="pain">
                        <div class="num">02</div>
                        <h3>Les abonnements qui s'empilent</h3>
                        <p>Formulaires, agenda, e-mailing, CRM, automatisations pour relier le tout. Chaque abonnement est raisonnable. Leur somme ne l'est plus, et elle grimpe à chaque nouvelle personne dans l'équipe.</p>
                        <ul><li>Un prix par utilisateur qui suit votre croissance</li><li>Des paliers qui sautent au mauvais moment</li><li>Des outils complets payés pour trois fonctions</li></ul>
                    </div>
                </div>
                <p class="pains-foot">Un outil sur mesure ne convient pas à tout le monde : il a lui aussi un coût mensuel. <strong>Le Diagnostic IA fait le calcul avec vous, sur cinq ans, avant de construire quoi que ce soit.</strong></p>
            </div>
        </section>

        <section class="sec" id="offre">
            <div class="wrap">
                <div class="sec-head">
                    <div>
                        <p class="eyebrow">L'offre</p>
                        <h2 class="h-sec">Trois temps, <em>une seule personne responsable.</em></h2>
                    </div>
                    <a href="/tarifs/" class="link-arrow plain">Tous les tarifs →</a>
                </div>
                <div class="offer">
                    <div class="offer-card is-first">
                        <div class="step">Le point de départ <b>1</b></div>
                        <h3>Diagnostic IA</h3>
                        <div class="price">3 500 € <small>prix fixe, HTVA</small></div>
                        <p>Deux semaines pour savoir où l'IA et le sur-mesure vous font gagner le plus.</p>
                        <ul><li>Interviews de vos équipes</li><li>Inventaire de vos tableurs et de vos abonnements</li><li>Top 3 des opportunités, chiffrées sur cinq ans</li><li>Déduit si on construit ensuite</li></ul>
                        <a href="/diagnostic-ia/" class="link-arrow plain">Le Diagnostic en détail →</a>
                    </div>
                    <div class="offer-card">
                        <div class="step">La construction <b>2</b></div>
                        <h3>Votre outil sur mesure</h3>
                        <div class="price">Sur devis <small>prix fixe annoncé d'avance</small></div>
                        <p>Je conçois et livre l'outil interne ou l'agent IA que le diagnostic a désigné.</p>
                        <ul><li>Outils de gestion et back-offices</li><li>Agents IA qui lisent, préparent, mettent à jour</li><li>Testé, documenté, mis en ligne</li><li>Le code source vous est remis</li></ul>
                        <a href="/realisations/" class="link-arrow plain">Voir des réalisations →</a>
                    </div>
                    <div class="offer-card">
                        <div class="step">La vie de l'outil <b>3</b></div>
                        <h3>Abonnement</h3>
                        <div class="price">dès 390 € <small>/ mois, HTVA, sans engagement</small></div>
                        <p>L'outil reste en vie, surveillé, à jour, et continue d'évoluer avec vous.</p>
                        <ul><li>Maintenance et mises à jour</li><li>Correction des bugs</li><li>Petites évolutions incluses chaque mois</li><li>Trois paliers : 390, 890 ou 1 890 €</li></ul>
                        <a href="/tarifs/#abonnements" class="link-arrow plain">Comparer les paliers →</a>
                    </div>
                </div>
                <div class="door">
                    <div class="door-k">ou</div>
                    <div>
                        <h3>Votre application existe déjà, mais elle vieillit ?</h3>
                        <p>Plus de mises à jour de sécurité, un développeur parti, la moindre demande qui devient un chantier. Je reprends toute application web : je la comprends, je la documente, je la remets à jour par paliers testés.</p>
                    </div>
                    <a href="/maintenance/" class="btn btn-line plain">Reprise d'application <span class="arr">→</span></a>
                </div>
            </div>
        </section>

        <section class="sec sec--soft">
            <div class="wrap split">
                <div>
                    <p class="eyebrow">Pour qui</p>
                    <h2 class="h-sec">Pour les entreprises <em>qui portent une mission.</em></h2>
                    <p class="sec-intro">Je ne m'adresse pas à tout le monde. Si vous vous reconnaissez dans ces quatre lignes, on devrait se parler.</p>
                </div>
                <div>
                    <ul class="checks">
                        <li><div><b>De 5 à 100 personnes</b><span>Assez grand pour que les tableurs coincent, assez petit pour qu'un logiciel d'entreprise soit démesuré. Un agent IA prend tout son sens au-delà d'une dizaine de personnes&nbsp;; en dessous, on commence par l'outil interne.</span></div></li>
                        <li><div><b>La durabilité au cœur du modèle</b><span>B Corp, coopérative, PME durable, producteur établi : l'impact fait partie de ce que vous vendez.</span></div></li>
                        <li><div><b>Une organisation bricolée entre Excel et WhatsApp</b><span>Des fichiers partagés, des groupes de messages, et une facture d'abonnements que personne n'a vraiment décidée.</span></div></li>
                        <li><div><b>Quelqu'un qui peut décider</b><span>Une direction ou une coordination prête à investir pour que son équipe gagne du temps.</span></div></li>
                    </ul>
                    <p class="aside-note">Fondation ou ONG établie&nbsp;? Bienvenue aussi, sur devis.</p>
                </div>
            </div>
        </section>

        <section class="sec">
            <div class="wrap">
                <div class="sec-head">
                    <div>
                        <p class="eyebrow">Ce que je construis</p>
                        <h2 class="h-sec">Des outils qui font <em>le travail ingrat.</em></h2>
                    </div>
                </div>
                <div class="missions">
                    <div class="mission"><div class="who">Coopérative</div><p>Le suivi des commandes, des stocks et des livraisons, sans un seul tableur</p></div>
                    <div class="mission"><div class="who">Domaine viticole</div><p>La gestion des parcelles, des vendanges, des stocks et des ventes</p></div>
                    <div class="mission"><div class="who">Producteur</div><p>Une boutique en ligne reliée à la production et aux livraisons</p></div>
                    <div class="mission"><div class="who">PME à impact</div><p>Un CRM interne à la place de trois abonnements qui se recoupent</p></div>
                    <div class="mission"><div class="who">Organisme de formation</div><p>Inscriptions, sessions, formateurs et attestations dans un seul outil</p></div>
                    <div class="mission"><div class="who">Fondation</div><p>Le traitement des appels à projets, de la candidature au suivi</p></div>
                    <div class="mission"><div class="who">ONG</div><p>Un back-office complet pour les dons, les bénévoles et les campagnes</p></div>
                    <div class="mission"><div class="who">Toute équipe</div><p>Un agent IA qui trie les demandes et prépare les réponses à valider</p></div>
                </div>
            </div>
        </section>

        <section class="sec band--mauve">
            <div class="wrap manifesto-grid manifesto">
                <div>
                    <p class="eyebrow">Ma façon de travailler</p>
                    <p class="big">Les agents écrivent le code. <em>Je choisis ce qui reste.</em></p>
                    <p class="sub">J'orchestre une série d'agents IA qui travaillent avec moi. Direction, arbitrages, vérification : rien ne part en ligne sans que je l'aie relu et validé. Une personne responsable, la capacité d'une équipe.</p>
                </div>
                <div class="facts">
                    <div><b>Depuis 2004</b><span>analyste-programmeur, co-fondateur d'une agence web, de startups et d'e-commerces</span></div>
                    <div><b>Depuis 2023</b><span>des applications conçues avec des agents IA, d'abord pour mes propres structures</span></div>
                    <div><b>Un seul interlocuteur</b><span>vous parlez à la personne qui construit</span></div>
                </div>
            </div>
        </section>

        <section class="sec">
            <div class="wrap">
                <div class="sec-head">
                    <div>
                        <p class="eyebrow">Déjà en production</p>
                        <h2 class="h-sec">Des outils <em>qui tournent tous les jours.</em></h2>
                    </div>
                    <a href="/realisations/" class="link-arrow plain">Toutes les réalisations →</a>
                </div>
                <div class="proofs">${proofs("fr")}
                </div>
                <div class="logos"><span class="k">Ils m'ont fait confiance</span>
                    ${REFS}
                </div>
            </div>
        </section>

        <section class="sec sec--soft">
            <div class="wrap">
                <p class="eyebrow">Sans dépendance</p>
                <h2 class="h-sec">Votre outil <em>reste à vous.</em></h2>
                <p class="sec-intro">Travailler avec une seule personne pose une question légitime : et si elle disparaît&nbsp;? La réponse est écrite dans chaque projet.</p>
                <div class="trust">
                    <div class="trust-card">
                        <div class="ic">${ICON_CODE}</div>
                        <h3>Votre code vous appartient</h3>
                        <ul>
                            <li><b>Le code source vous est remis</b>, hébergé sur GitHub, dans un espace à votre nom.</li>
                            <li><b>Des technologies standard</b>, connues de milliers de développeurs.</li>
                            <li><b>Documentation et tests livrés</b> : un autre développeur peut reprendre le projet.</li>
                        </ul>
                    </div>
                    <div class="trust-card">
                        <div class="ic">${ICON_LOCK}</div>
                        <h3>Vos données</h3>
                        <ul>
                            <li><b>Hébergement chez Infomaniak, en Suisse</b>, un hébergeur indépendant.</li>
                            <li><b>Modèle IA&nbsp;: Claude, d'Anthropic</b>, utilisé via son API professionnelle.</li>
                            <li><b>Un agent ne fait que ce qu'on lui permet</b> : ce qui engage l'entreprise passe par une validation humaine.</li>
                        </ul>
                    </div>
                </div>
            </div>
        </section>

        <section class="sec lieu-sec">
            <div class="wrap">
                <div class="sec-head">
                    <p class="eyebrow">D'où j'écris</p>
                    <h2 class="h-sec">Les 4 Sources, <em>notre terrain d'essai.</em></h2>
                    <p class="sec-intro">Un tiers-lieu de 15 hectares à Yvoir&nbsp;: des gîtes et des salles, un verger, des ânes, et un collectif qui y vit. C'est ici que mes outils sont mis à l'épreuve, tous les jours, avant d'arriver chez vous.</p>
                </div>
                <div class="lieu-grid">
                    <img class="lieu-main" src="/assets/lieu/4-sources-vue-aerienne.webp" alt="Vue aérienne du domaine des 4 Sources à Yvoir : prairies, bâtiments et bois" width="1600" height="900" loading="lazy">
                    <img src="/assets/lieu/4-sources-gite.webp" alt="La façade en pierre du gîte des 4 Sources, couverte de vigne" width="1000" height="666" loading="lazy">
                    <img src="/assets/lieu/4-sources-anes.webp" alt="Deux ânes broutent dans une prairie des 4 Sources" width="1000" height="750" loading="lazy">
                </div>
                <div class="lieu-links"><a href="/realisations/claudy/" class="link-arrow plain">Claudy, l'outil qui fait tourner le lieu →</a><a href="https://www.les4sources.be" target="_blank" rel="noopener noreferrer" class="link-arrow plain">Découvrir Les 4 Sources →</a></div>
            </div>
        </section>


        <section class="sec band" id="contact">
            <div class="wrap contact-band">
                <div>
                    <p class="eyebrow">On en parle&nbsp;?</p>
                    <h2 class="h-sec">Parlons de <em>vos tableurs.</em></h2>
                    <p>Trente minutes, sans engagement, pour voir si je peux vous être utile. Pour en tirer le meilleur, gardez en tête ces trois questions&nbsp;:</p>
                </div>
                <div>
                    <ol class="qs">
                        <li>Combien de personnes compte votre équipe&nbsp;?</li>
                        <li>Sur quels tableurs, outils et abonnements tourne-t-elle aujourd'hui&nbsp;?</li>
                        <li>Quelle tâche aimeriez-vous ne plus jamais faire à la main&nbsp;?</li>
                    </ol>
                    <a ${BK("fr")} class="btn btn-light plain">Réserver un call de 30 minutes <span class="arr">→</span></a>
                    <div class="contact-alt"><a href="mailto:team@supergenial.be">team@supergenial.be</a><a href="https://www.linkedin.com/in/michaelhulet/" target="_blank" rel="noopener noreferrer">LinkedIn</a><a href="https://t.me/supergenialdotbe" target="_blank" rel="noopener noreferrer">Telegram</a></div>
                </div>
            </div>
        </section>

`;

const EN = `
        <section class="hero">
            <div class="wrap hero-grid">
                <div>
                    <p class="eyebrow">Custom internal tools and AI agents</p>
                    <h1 class="display">Your custom tools, <em>doing the work for you.</em></h1>
                    <p class="lede">I replace your spreadsheets, your repetitive tasks and your pile of software subscriptions with <strong>internal tools and AI agents built for your company</strong>. You own the code, and your team gets its time back for its mission.</p>
                    <div class="actions">
                        <a ${BK("en")} class="btn btn-primary plain">Book a 30-minute call <span class="arr">→</span></a>
                        <a href="/en/ai-assessment/" class="btn btn-line plain">The AI Assessment</a>
                    </div>
                    <div class="hero-for" aria-label="Who it is for">
                        <span>For impact-driven companies</span><span>5 to 100 people</span>
                    </div>
                </div>
                <figure class="hero-avatar"><img src="/assets/brand/supergenial-avatar.svg" alt="The Super Génial avatar: a smiling black block" width="512" height="512"><figcaption><a href="#letter">Michael Hulet, from Les 4 Sources, in Yvoir</a></figcaption></figure>
            </div>
        </section>

        <section class="sec letter-sec" id="letter">
            <div class="wrap letter">
                <div class="letter-photo-wrap"><img class="letter-photo" src="/assets/lieu/michael-hulet.webp" alt="Portrait of Michael Hulet" width="400" height="400" loading="lazy"></div>
                <div class="letter-body">
                    <p class="eyebrow">A word before we start</p>
                    <p class="letter-hello">Hello, I'm Michael.</p>
                    <p>I have been coding as a freelancer since 2004. What taught me to build useful tools is being one of their users, again and again: a shop, a guest house with venues, an online shop, an association. I know the till that never matches the stock, the booking schedule that overflows, the registrations handled by hand.</p>
                    <p>Since 2023, I have been building with AI agents the tools my own organisations need. <em>Claudy</em> runs Les 4 Sources, the community estate where I live in Yvoir. For the Semisto association, <em>My Semisto</em> drives collective work and <em>Terranova</em> maps the teams' projects. What has proven itself at home, I offer to companies that also carry a sustainable mission.</p>
                    <p>With Super Génial, you get a single point of contact, code you own and tools built to last.</p>
                    <p class="letter-sign">Michael</p>
                </div>
            </div>
            <script>(function(){var w=document.querySelectorAll(".letter-photo-wrap");if(!("IntersectionObserver" in window)){w.forEach(function(e){e.classList.add("in")});return}var o=new IntersectionObserver(function(es){es.forEach(function(e){if(e.isIntersecting){e.target.classList.add("in");o.unobserve(e.target)}})},{threshold:.35});w.forEach(function(e){o.observe(e)})})();</script>
        </section>

        <section class="sec">
            <div class="wrap">
                <p class="eyebrow">What costs a lot without showing</p>
                <h2 class="h-sec">Two silent leaks <em>in your budget.</em></h2>
                <div class="pains">
                    <div class="pain">
                        <div class="num">01</div>
                        <h3>The spreadsheets that run the company</h3>
                        <p>Orders, registrations, stock, schedules: everything goes through a file everyone is afraid to open. It costs nothing to buy. You pay for it in hours of copying, in mistakes and in depending on a single person.</p>
                        <ul><li>The same information typed two or three times</li><li>Versions that contradict each other</li><li>Only one person who knows how it works</li></ul>
                    </div>
                    <div class="pain">
                        <div class="num">02</div>
                        <h3>The subscriptions that pile up</h3>
                        <p>Forms, calendar, e-mailing, CRM, automations to connect it all. Each subscription is reasonable. Their sum no longer is, and it climbs with every new person on the team.</p>
                        <ul><li>A per-user price that follows your growth</li><li>Tiers that jump at the worst moment</li><li>Full products paid for three features</li></ul>
                    </div>
                </div>
                <p class="pains-foot">A custom tool is not for everyone: it has a monthly cost too. <strong>The AI Assessment does the maths with you, over five years, before anything is built.</strong></p>
            </div>
        </section>

        <section class="sec" id="offer">
            <div class="wrap">
                <div class="sec-head">
                    <div>
                        <p class="eyebrow">The offer</p>
                        <h2 class="h-sec">Three steps, <em>one accountable person.</em></h2>
                    </div>
                    <a href="/en/pricing/" class="link-arrow plain">Full pricing →</a>
                </div>
                <div class="offer">
                    <div class="offer-card is-first">
                        <div class="step">The starting point <b>1</b></div>
                        <h3>AI Assessment</h3>
                        <div class="price">€3,500 <small>fixed price, excl. VAT</small></div>
                        <p>Two weeks to find where AI and custom tools save you the most.</p>
                        <ul><li>Interviews with your teams</li><li>Inventory of your spreadsheets and subscriptions</li><li>Top 3 opportunities, costed over five years</li><li>Deducted if we build next</li></ul>
                        <a href="/en/ai-assessment/" class="link-arrow plain">The Assessment in detail →</a>
                    </div>
                    <div class="offer-card">
                        <div class="step">The build <b>2</b></div>
                        <h3>Your custom tool</h3>
                        <div class="price">On quote <small>fixed price, agreed upfront</small></div>
                        <p>I design and deliver the internal tool or AI agent the assessment pointed to.</p>
                        <ul><li>Management tools and back-offices</li><li>AI agents that read, draft and update</li><li>Tested, documented, deployed</li><li>The source code is handed over</li></ul>
                        <a href="/en/case-studies/" class="link-arrow plain">See case studies →</a>
                    </div>
                    <div class="offer-card">
                        <div class="step">The tool's life <b>3</b></div>
                        <h3>Subscription</h3>
                        <div class="price">from €390 <small>/ month, excl. VAT, no lock-in</small></div>
                        <p>The tool stays alive, monitored, up to date, and keeps evolving with you.</p>
                        <ul><li>Maintenance and updates</li><li>Bug fixes</li><li>Small improvements included every month</li><li>Three tiers: €390, €890 or €1,890</li></ul>
                        <a href="/en/pricing/#subscriptions" class="link-arrow plain">Compare tiers →</a>
                    </div>
                </div>
                <div class="door">
                    <div class="door-k">or</div>
                    <div>
                        <h3>You already have an application, but it is ageing?</h3>
                        <p>No more security updates, a developer who left, every small request turning into a project. I take over any web application: I understand it, document it and bring it up to date in tested steps.</p>
                    </div>
                    <a href="/en/maintenance/" class="btn btn-line plain">Application take-over <span class="arr">→</span></a>
                </div>
            </div>
        </section>

        <section class="sec sec--soft">
            <div class="wrap split">
                <div>
                    <p class="eyebrow">Who it is for</p>
                    <h2 class="h-sec">For companies <em>that carry a mission.</em></h2>
                    <p class="sec-intro">I don't work for everyone. If these four lines sound like you, we should talk.</p>
                </div>
                <div>
                    <ul class="checks">
                        <li><div><b>5 to 100 people</b><span>Big enough for spreadsheets to break, small enough for enterprise software to be overkill. An AI agent really pays off beyond ten or so people; below that, we start with the internal tool.</span></div></li>
                        <li><div><b>Sustainability at the core</b><span>B Corp, cooperative, sustainable SME, established producer: impact is part of what you sell.</span></div></li>
                        <li><div><b>An organisation patched together with Excel and WhatsApp</b><span>Shared files, group chats, and a subscriptions bill nobody really decided on.</span></div></li>
                        <li><div><b>Someone who can decide</b><span>Management ready to invest so the team gets its time back.</span></div></li>
                    </ul>
                    <p class="aside-note">An established foundation or NGO? Welcome too, on quote.</p>
                </div>
            </div>
        </section>

        <section class="sec">
            <div class="wrap">
                <div class="sec-head">
                    <div>
                        <p class="eyebrow">What I build</p>
                        <h2 class="h-sec">Tools that do <em>the thankless work.</em></h2>
                    </div>
                </div>
                <div class="missions">
                    <div class="mission"><div class="who">Cooperative</div><p>Tracking orders, stock and deliveries, without a single spreadsheet</p></div>
                    <div class="mission"><div class="who">Wine estate</div><p>Managing plots, harvests, stock and sales</p></div>
                    <div class="mission"><div class="who">Producer</div><p>An online shop connected to production and deliveries</p></div>
                    <div class="mission"><div class="who">Impact SME</div><p>An in-house CRM instead of three overlapping subscriptions</p></div>
                    <div class="mission"><div class="who">Training provider</div><p>Registrations, sessions, trainers and certificates in one tool</p></div>
                    <div class="mission"><div class="who">Foundation</div><p>Handling calls for projects, from application to follow-up</p></div>
                    <div class="mission"><div class="who">NGO</div><p>A complete back-office for donations, volunteers and campaigns</p></div>
                    <div class="mission"><div class="who">Any team</div><p>An AI agent that sorts requests and drafts replies to approve</p></div>
                </div>
            </div>
        </section>

        <section class="sec band--mauve">
            <div class="wrap manifesto-grid manifesto">
                <div>
                    <p class="eyebrow">How I work</p>
                    <p class="big">The agents write the code. <em>I decide what stays.</em></p>
                    <p class="sub">I orchestrate a set of AI agents that work with me. Direction, trade-offs, verification: nothing goes live until I have reviewed and approved it. One accountable person, the capacity of a team.</p>
                </div>
                <div class="facts">
                    <div><b>Since 2004</b><span>analyst-programmer, co-founder of a web agency, start-ups and online shops</span></div>
                    <div><b>Since 2023</b><span>applications built with AI agents, first for my own organisations</span></div>
                    <div><b>One contact</b><span>you talk to the person who builds</span></div>
                </div>
            </div>
        </section>

        <section class="sec">
            <div class="wrap">
                <div class="sec-head">
                    <div>
                        <p class="eyebrow">Already in production</p>
                        <h2 class="h-sec">Tools <em>used every day.</em></h2>
                    </div>
                    <a href="/en/case-studies/" class="link-arrow plain">All case studies →</a>
                </div>
                <div class="proofs">${proofs("en")}
                </div>
                <div class="logos"><span class="k">They trusted me</span>
                    ${REFS}
                </div>
            </div>
        </section>

        <section class="sec sec--soft">
            <div class="wrap">
                <p class="eyebrow">No lock-in</p>
                <h2 class="h-sec">Your tool <em>stays yours.</em></h2>
                <p class="sec-intro">Working with a single person raises a fair question: what if they disappear? The answer is written into every project.</p>
                <div class="trust">
                    <div class="trust-card">
                        <div class="ic">${ICON_CODE}</div>
                        <h3>You own your code</h3>
                        <ul>
                            <li><b>The source code is handed over</b>, hosted on GitHub, in a space in your name.</li>
                            <li><b>Standard technologies</b>, known by thousands of developers.</li>
                            <li><b>Documentation and tests delivered</b>: another developer can take over.</li>
                        </ul>
                    </div>
                    <div class="trust-card">
                        <div class="ic">${ICON_LOCK}</div>
                        <h3>Your data</h3>
                        <ul>
                            <li><b>Hosted by Infomaniak, in Switzerland</b>, an independent provider.</li>
                            <li><b>AI model: Claude, by Anthropic</b>, used through its business API.</li>
                            <li><b>An agent only does what it is allowed to</b>: anything that commits the company goes through human approval.</li>
                        </ul>
                    </div>
                </div>
            </div>
        </section>

        <section class="sec lieu-sec">
            <div class="wrap">
                <div class="sec-head">
                    <p class="eyebrow">Where I write from</p>
                    <h2 class="h-sec">Les 4 Sources, <em>our testing ground.</em></h2>
                    <p class="sec-intro">A 15-hectare community estate in Yvoir, Belgium: lodges and venues, an orchard, donkeys, and a community that lives there. This is where my tools are put to the test, every day, before they reach you.</p>
                </div>
                <div class="lieu-grid">
                    <img class="lieu-main" src="/assets/lieu/4-sources-vue-aerienne.webp" alt="Aerial view of the Les 4 Sources estate in Yvoir: meadows, buildings and woods" width="1600" height="900" loading="lazy">
                    <img src="/assets/lieu/4-sources-gite.webp" alt="The stone front of the Les 4 Sources lodge, covered with vines" width="1000" height="666" loading="lazy">
                    <img src="/assets/lieu/4-sources-anes.webp" alt="Two donkeys grazing in a Les 4 Sources meadow" width="1000" height="750" loading="lazy">
                </div>
                <div class="lieu-links"><a href="/en/case-studies/claudy/" class="link-arrow plain">Claudy, the tool that runs the estate →</a><a href="https://www.les4sources.be" target="_blank" rel="noopener noreferrer" class="link-arrow plain">Discover Les 4 Sources →</a></div>
            </div>
        </section>


        <section class="sec band" id="contact">
            <div class="wrap contact-band">
                <div>
                    <p class="eyebrow">Shall we talk?</p>
                    <h2 class="h-sec">Let's talk about <em>your spreadsheets.</em></h2>
                    <p>Thirty minutes, no commitment, to see whether I can help. To make the most of it, keep these three questions in mind:</p>
                </div>
                <div>
                    <ol class="qs">
                        <li>How many people are on your team?</li>
                        <li>Which spreadsheets, tools and subscriptions does it run on today?</li>
                        <li>Which task would you love to never do by hand again?</li>
                    </ol>
                    <a ${BK("en")} class="btn btn-light plain">Book a 30-minute call <span class="arr">→</span></a>
                    <div class="contact-alt"><a href="mailto:team@supergenial.be">team@supergenial.be</a><a href="https://www.linkedin.com/in/michaelhulet/" target="_blank" rel="noopener noreferrer">LinkedIn</a><a href="https://t.me/supergenialdotbe" target="_blank" rel="noopener noreferrer">Telegram</a></div>
                </div>
            </div>
        </section>

`;

export const home = (lang: Lang) => page({
  lang, path: ALT[lang], alt: ALT, wide: true, bodyClass: "page-home",
  title: lang === "fr" ? "Super Génial · Outils internes et agents IA sur mesure" : "Super Génial · Custom internal tools and AI agents",
  description: lang === "fr"
    ? "Super Génial remplace vos tableurs et vos abonnements empilés par des outils internes et des agents IA sur mesure, pour les entreprises à impact."
    : "Super Génial replaces your spreadsheets and stacked subscriptions with custom internal tools and AI agents, for impact-driven companies.",
  og: "home", ogAlt: lang === "fr" ? "Super Génial : votre équipe est là pour la mission, pas pour recopier des tableurs" : "Super Génial: your team is here for the mission, not to copy spreadsheets",
  jsonld: [orgLd(lang)],
  body: lang === "fr" ? FR : EN,
});
