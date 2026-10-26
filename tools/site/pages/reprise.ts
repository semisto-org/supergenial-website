// Reprise d'application FR / EN (URL historique /maintenance/, hors menu).
import { page, BOOKING, faqHtml, faqLd, breadcrumbLd, type Lang } from "../layout.ts";

const ALT = { fr: "/maintenance/", en: "/en/maintenance/" };
const BK = (l: Lang) => `href="${BOOKING[l]}" data-booking target="_blank" rel="noopener noreferrer"`;

const GUIDES: Record<Lang, [string, string][]> = {
  fr: [
    ["/ressources/application-qui-vieillit/", "Votre application vieillit : reprendre, mettre à jour ou reconstruire ?"],
    ["/ressources/reprendre-application-sans-documentation/", "Reprendre une application web sans documentation ni développeur d'origine"],
    ["/ressources/cout-mise-a-niveau-rails/", "Combien coûte la mise à niveau d'une application Rails ?"],
    ["/ressources/rails-7-1-fin-de-support/", "Rails 7.1 est en fin de support : qu'est-ce que ça change pour vous ?"],
    ["/ressources/migrer-rails-6-vers-7/", "Migrer de Rails 6 à Rails 7 : le guide pour ne rien casser"],
    ["/ressources/rails-8-nouveautes/", "Rails 8 : quoi de neuf et pourquoi ça vaut la mise à niveau"],
    ["/ressources/ruby-3-2-fin-de-vie/", "Ruby 3.2 en fin de vie : pourquoi passer à Ruby 3.3 sans attendre"],
    ["/ressources/ubuntu-20-04-fin-de-support/", "Ubuntu 20.04 en fin de support : faut-il migrer votre serveur ?"],
    ["/ressources/webpacker-vers-esbuild/", "Webpacker est abandonné : comment migrer vers esbuild"],
    ["/ressources/delayedjob-vers-solid-queue/", "DelayedJob a fait son temps : passer à Solid Queue"],
    ["/ressources/utf8mb3-vers-utf8mb4-mysql/", "Emoji cassés, caractères perdus : le problème utf8mb3 dans MySQL"],
  ],
  en: [
    ["/en/resources/ageing-business-application/", "Your application is ageing: take over, upgrade or rebuild?"],
    ["/en/resources/take-over-a-rails-app-without-documentation/", "Taking over a web application with no documentation and no original developer"],
    ["/en/resources/rails-upgrade-cost/", "How much does a Rails upgrade cost?"],
    ["/en/resources/rails-7-1-end-of-life/", "Rails 7.1 has reached end of life: what does that mean for you?"],
    ["/en/resources/upgrade-rails-6-to-7/", "Upgrading from Rails 6 to Rails 7: the guide to breaking nothing"],
    ["/en/resources/rails-8-whats-new/", "Rails 8: what's new and why it's worth the upgrade"],
    ["/en/resources/ruby-3-2-end-of-life/", "Ruby 3.2 has reached end of life: why you should move to Ruby 3.3 now"],
    ["/en/resources/ubuntu-20-04-end-of-life/", "Ubuntu 20.04 reaching end of life: should you migrate your server?"],
    ["/en/resources/webpacker-to-esbuild/", "Webpacker is deprecated: how to migrate to esbuild"],
    ["/en/resources/delayedjob-to-solid-queue/", "DelayedJob has had its day: moving to Solid Queue"],
    ["/en/resources/utf8mb3-to-utf8mb4-mysql/", "Broken emoji, lost characters: the utf8mb3 problem in MySQL"],
  ],
};
const guides = (l: Lang) => `<ul class="guides">${GUIDES[l].map(([h, t]) => `<li><a href="${h}">${t}</a></li>`).join("")}</ul>`;

const FAQ: Record<Lang, [string, string][]> = {
  fr: [
    ["Mon application n'est pas en Rails, c'est possible quand même ?", "Oui. Ruby on Rails est ma spécialité de longue date, mais le principe est le même pour toute application web : PHP, Node, Python, Django, Laravel… L'audit dit précisément ce qui est faisable et à quel prix."],
    ["Mon application n'a aucun test automatisé. C'est grave ?", "C'est le cas de la plupart des applications reprises. Avant de toucher quoi que ce soit, je pose des tests sur vos parcours critiques : ils servent de filet de sécurité pendant toute la mise à niveau, et ils restent à vous après."],
    ["Qu'est-ce qui peut casser pendant la mise à niveau ?", "Rien en production : tout se passe d'abord sur un environnement de test, version par version. La bascule n'a lieu que quand chaque étape est validée, et on peut revenir en arrière à tout moment."],
    ["Le développeur d'origine n'est plus joignable et il n'y a pas de documentation.", "Situation classique. Il me faut seulement l'accès au code et au serveur : les agents IA reconstituent le fonctionnement de l'application en lisant l'intégralité du code. La documentation, c'est moi qui la produis en sortie."],
    ["Faut-il déplacer mon application chez un autre hébergeur ?", "Pas forcément. Votre serveur peut rester où il est ; si l'hébergement actuel pose problème, je peux proposer une migration vers Infomaniak, en Suisse. Dans tous les cas, vous gardez le contrôle et la propriété de votre infrastructure."],
  ],
  en: [
    ["My application isn't built with Rails. Is it still possible?", "Yes. Ruby on Rails is my long-standing speciality, but the approach is the same for any web application: PHP, Node, Python, Django, Laravel… The audit says exactly what is feasible and at what price."],
    ["My application has no automated tests. Is that a problem?", "That is the case for most applications I take over. Before touching anything, I add tests on your critical paths: they act as a safety net throughout the upgrade, and they stay yours afterwards."],
    ["What can break during the upgrade?", "Nothing in production: everything happens first on a test environment, version by version. The switch only happens once each step is validated, and we can roll back at any time."],
    ["The original developer is gone and there is no documentation.", "A classic situation. I only need access to the code and the server: AI agents reconstruct how the application works by reading all of its code. I produce the documentation as an output."],
    ["Do I need to move my application to another host?", "Not necessarily. Your server can stay where it is; if the current hosting is a problem, I can offer a migration to Infomaniak, in Switzerland. Either way, you keep control and ownership of your infrastructure."],
  ],
};

const FR = `
        <section class="page-hero">
            <div class="wrap page-hero-grid">
                <div>
                    <p class="eyebrow">Reprise d'application</p>
                    <h1 class="display display--page">Votre application fait le travail. <em>Plus personne n'ose y toucher.</em></h1>
                    <p class="lede">Elle tourne depuis des années. Mais le framework a plusieurs versions de retard, le serveur n'est plus mis à jour, et la personne qui l'a construite n'est plus là. Je reprends toute application web&nbsp;: je la comprends, je la documente, je la remets à jour par paliers testés, puis je la fais évoluer.</p>
                    <div class="actions">
                        <a ${BK("fr")} class="btn btn-primary plain">Réserver un call de 30 minutes <span class="arr">→</span></a>
                    </div>
                </div>
                <img class="illu-side" src="/assets/illustrations/sg-reprise.webp" decoding="async" alt="Illustration au trait : un petit robot rempote la plante fanée qui sort d'un vieil ordinateur portable" width="800" height="800">
            </div>
        </section>

        <section class="sec">
            <div class="wrap">
                <p class="eyebrow">Les signaux d'alerte</p>
                <h2 class="h-sec">Vous reconnaissez <em>au moins deux de ces phrases&nbsp;?</em></h2>
                <div class="tiles">
                    <div class="tile"><b>« On ne fait plus les mises à jour. »</b><span>Le langage, le framework ou le serveur ne reçoivent plus de correctifs de sécurité.</span></div>
                    <div class="tile"><b>« Personne ne connaît le code. »</b><span>Pas de documentation, ou elle date du premier jour. Le développeur d'origine est parti.</span></div>
                    <div class="tile"><b>« Ajouter un champ prend des semaines. »</b><span>Chaque petite demande devient un chantier, et un devis qui fait peur.</span></div>
                    <div class="tile"><b>« On a un tableur à côté. »</b><span>L'équipe contourne l'outil pour ce qu'il ne sait plus faire.</span></div>
                </div>
            </div>
        </section>

        <section class="sec sec--soft">
            <div class="wrap cols-2">
                <div>
                    <p class="eyebrow">Pourquoi maintenant</p>
                    <h2 class="h-sec">Les horloges <em>tournent déjà.</em></h2>
                    <p class="prose">Une application à jour est un actif. Une application figée est un compte à rebours&nbsp;: chaque mois qui passe rend la remise à niveau plus coûteuse, et l'incident plus probable.</p>
                </div>
                <div>
                    <div class="eol-table">
                        <div class="eol-row"><div class="eol-label">Ruby on Rails 7.1 et antérieurs<small>Le framework de milliers d'applications métier</small></div><div class="eol-date">fin de support · octobre 2025</div></div>
                        <div class="eol-row"><div class="eol-label">Ruby 3.2 et antérieurs<small>Le langage sous le framework</small></div><div class="eol-date">fin de support · mars 2026</div></div>
                        <div class="eol-row"><div class="eol-label">Ubuntu 20.04 LTS<small>Le système de très nombreux serveurs</small></div><div class="eol-date">fin de support · mai 2025</div></div>
                    </div>
                    <p class="fine">Et ce n'est pas propre à Rails&nbsp;: PHP, Node, Python, Django, Laravel ont tous leur calendrier de fin de support.</p>
                </div>
            </div>
        </section>

        <section class="sec">
            <div class="wrap">
                <p class="eyebrow">La démarche</p>
                <h2 class="h-sec">Trois étapes, <em>des prix connus d'avance.</em></h2>
                <ol class="timeline timeline--3">
                    <li><b>L'audit · prix fixe annoncé d'avance</b>Je lis le code et le serveur&nbsp;: versions, dépendances, failles connues, sauvegardes. Vous recevez un rapport lisible et un plan de remise à niveau chiffré, même si vous ne continuez pas avec moi.</li>
                    <li><b>La remise à niveau · sur devis, au forfait</b>Montée de version par étapes, testée à chaque palier sur un environnement de test, jamais directement en production. Application, dépendances et serveur remis à jour, documentation produite.</li>
                    <li><b>La suite · abonnement dès 390 € / mois</b>Surveillance, mises à jour continues, correction des bugs, petites évolutions. Votre application ne reprendra plus dix ans de retard d'un coup. <a href="/tarifs/#abonnements">Les paliers</a>.</li>
                </ol>
                <div class="callout"><b>Pourquoi c'est abordable.</b> Lire un code inconnu, écrire les tests qui manquent, migrer des centaines de fichiers d'une version à l'autre&nbsp;: les agents IA font en quelques jours ce qui prenait des semaines, sous ma supervision. Le même résultat qu'une équipe spécialisée, à un prix accessible.</div>
            </div>
        </section>

        <section class="sec sec--soft">
            <div class="wrap">
                <p class="eyebrow">Bon à savoir</p>
                <h2 class="h-sec">Questions fréquentes</h2>
                ${faqHtml(FAQ.fr)}
            </div>
        </section>

        <section class="sec">
            <div class="wrap cols-2">
                <div>
                    <p class="eyebrow">Pour aller plus loin</p>
                    <h2 class="h-sec">Les guides <em>techniques.</em></h2>
                    <p class="prose">Des articles pour comprendre ce qui se joue avant de décider. Les plus techniques s'adressent à votre développeur, ou à celui que vous n'avez plus.</p>
                </div>
                ${guides("fr")}
            </div>
        </section>

        <section class="sec band">
            <div class="wrap contact-band">
                <div>
                    <p class="eyebrow">On en parle&nbsp;?</p>
                    <h2 class="h-sec">Votre application <em>mérite un avenir.</em></h2>
                </div>
                <div>
                    <p>Dites-moi ce qu'elle fait, sur quoi elle tourne et ce qui vous inquiète. En trente minutes, on sait si un audit a du sens.</p>
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
                    <p class="eyebrow">Application take-over</p>
                    <h1 class="display display--page">Your application does the job. <em>Nobody dares to touch it anymore.</em></h1>
                    <p class="lede">It has been running for years. But the framework is several versions behind, the server no longer gets updates, and the person who built it is gone. I take over any web application: I understand it, document it, bring it up to date in tested steps, then keep it evolving.</p>
                    <div class="actions">
                        <a ${BK("en")} class="btn btn-primary plain">Book a 30-minute call <span class="arr">→</span></a>
                    </div>
                </div>
                <img class="illu-side" src="/assets/illustrations/sg-reprise.webp" decoding="async" alt="Line drawing: a small robot repots the wilting plant growing out of an old laptop" width="800" height="800">
            </div>
        </section>

        <section class="sec">
            <div class="wrap">
                <p class="eyebrow">Warning signs</p>
                <h2 class="h-sec">Do at least two <em>of these sound familiar?</em></h2>
                <div class="tiles">
                    <div class="tile"><b>“We stopped doing updates.”</b><span>The language, framework or server no longer receive security fixes.</span></div>
                    <div class="tile"><b>“Nobody knows the code.”</b><span>No documentation, or it dates from day one. The original developer has left.</span></div>
                    <div class="tile"><b>“Adding a field takes weeks.”</b><span>Every small request becomes a project, with a scary quote.</span></div>
                    <div class="tile"><b>“We keep a spreadsheet on the side.”</b><span>The team works around the tool for what it can no longer do.</span></div>
                </div>
            </div>
        </section>

        <section class="sec sec--soft">
            <div class="wrap cols-2">
                <div>
                    <p class="eyebrow">Why now</p>
                    <h2 class="h-sec">The clocks <em>are already ticking.</em></h2>
                    <p class="prose">An up-to-date application is an asset. A frozen one is a countdown: every month makes the upgrade more expensive, and an incident more likely.</p>
                </div>
                <div>
                    <div class="eol-table">
                        <div class="eol-row"><div class="eol-label">Ruby on Rails 7.1 and earlier<small>The framework behind thousands of business apps</small></div><div class="eol-date">end of support · October 2025</div></div>
                        <div class="eol-row"><div class="eol-label">Ruby 3.2 and earlier<small>The language under the framework</small></div><div class="eol-date">end of support · March 2026</div></div>
                        <div class="eol-row"><div class="eol-label">Ubuntu 20.04 LTS<small>The system of countless servers</small></div><div class="eol-date">end of support · May 2025</div></div>
                    </div>
                    <p class="fine">And it is not just Rails: PHP, Node, Python, Django and Laravel all have their end-of-support calendars.</p>
                </div>
            </div>
        </section>

        <section class="sec">
            <div class="wrap">
                <p class="eyebrow">The approach</p>
                <h2 class="h-sec">Three steps, <em>prices known upfront.</em></h2>
                <ol class="timeline timeline--3">
                    <li><b>The audit · fixed price, agreed upfront</b>I read the code and the server: versions, dependencies, known vulnerabilities, backups. You get a readable report and a costed upgrade plan, even if you don't continue with me.</li>
                    <li><b>The upgrade · on quote, fixed price</b>Step-by-step version upgrades, tested at each stage on a test environment, never straight in production. Application, dependencies and server brought up to date, documentation produced.</li>
                    <li><b>What comes next · subscription from €390 / month</b>Monitoring, continuous updates, bug fixes, small improvements. Your application will never fall ten years behind again. <a href="/en/pricing/#subscriptions">The tiers</a>.</li>
                </ol>
                <div class="callout"><b>Why it is affordable.</b> Reading unknown code, writing the missing tests, migrating hundreds of files from one version to the next: AI agents do in days what used to take weeks, under my supervision. The same result as a specialised team, at an accessible price.</div>
            </div>
        </section>

        <section class="sec sec--soft">
            <div class="wrap">
                <p class="eyebrow">Good to know</p>
                <h2 class="h-sec">Frequently asked questions</h2>
                ${faqHtml(FAQ.en)}
            </div>
        </section>

        <section class="sec">
            <div class="wrap cols-2">
                <div>
                    <p class="eyebrow">Going further</p>
                    <h2 class="h-sec">Technical <em>guides.</em></h2>
                    <p class="prose">Articles to understand what is at stake before deciding. The most technical ones are written for your developer, or the one you no longer have.</p>
                </div>
                ${guides("en")}
            </div>
        </section>

        <section class="sec band">
            <div class="wrap contact-band">
                <div>
                    <p class="eyebrow">Shall we talk?</p>
                    <h2 class="h-sec">Your application <em>deserves a future.</em></h2>
                </div>
                <div>
                    <p>Tell me what it does, what it runs on and what worries you. In thirty minutes we know whether an audit makes sense.</p>
                    <div class="actions"><a ${BK("en")} class="btn btn-light plain">Book a 30-minute call <span class="arr">→</span></a></div>
                    <div class="contact-alt"><a href="mailto:team@supergenial.be">team@supergenial.be</a></div>
                </div>
            </div>
        </section>
`;

export const reprise = (lang: Lang) => page({
  lang, path: ALT[lang], alt: ALT, wide: true,
  title: lang === "fr" ? "Reprise d'application web : audit et mise à niveau · Super Génial" : "Web application take-over and upgrades · Super Génial",
  description: lang === "fr"
    ? "Votre application web vieillit et plus personne n'ose y toucher ? Je la reprends, la documente et la remets à jour par paliers testés, Rails, PHP ou autre."
    : "Your web application is ageing and nobody dares touch it? I take it over, document it and upgrade it in tested steps, Rails, PHP or otherwise.",
  og: "maintenance", ogAlt: lang === "fr" ? "Reprise d'application : votre application fait le travail, plus personne n'ose y toucher" : "Application take-over: your application does the job, nobody dares touch it",
  jsonld: [faqLd(FAQ[lang]), breadcrumbLd([["Super Génial", lang === "fr" ? "/" : "/en/"], [lang === "fr" ? "Reprise d'application" : "Application take-over", ALT[lang]]])],
  body: lang === "fr" ? FR : EN,
});
