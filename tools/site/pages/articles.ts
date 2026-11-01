// Les articles Ressources de 2026 (FR / EN) et la page Ressources.
// Les anciens articles techniques restent en ligne à leur adresse, sans être listés ici :
// la page Reprise d'application les relie.
import { page, BOOKING, breadcrumbLd, SITE_URL, type Lang } from "../layout.ts";

export type Article = {
  slug: { fr: string; en: string };
  date: string;
  title: Record<Lang, string>;
  description: Record<Lang, string>;
  lead: Record<Lang, string>;
  body: Record<Lang, string>;
  next: Record<Lang, [string, string]>;   // [lien, texte du bouton]
};

export const ARTICLES: Article[] = [
  {
    slug: { fr: "cout-cache-des-tableurs", en: "hidden-cost-of-spreadsheets" },
    date: "2026-10-21",
    title: {
      fr: "Combien vous coûtent vraiment vos tableurs ?",
      en: "What do your spreadsheets really cost you?",
    },
    description: {
      fr: "Un tableur ne coûte rien à l'achat. Il se paie en heures de saisie, en erreurs et en dépendance à une seule personne. Une méthode simple pour le chiffrer.",
      en: "A spreadsheet costs nothing to buy. You pay for it in hours of data entry, in mistakes and in depending on one person. A simple way to put a number on it.",
    },
    lead: {
      fr: "Il ne coûte rien à l'achat. C'est précisément pour ça qu'on ne mesure jamais ce qu'il coûte vraiment.",
      en: "It costs nothing to buy. That is precisely why nobody ever measures what it really costs.",
    },
    body: {
      fr: `<p>Dans la plupart des petites entreprises à impact, l'outil central n'est pas un logiciel. C'est un tableur. Il tient les commandes, les inscriptions, les stocks, les bénévoles, la facturation. Il a été créé par quelqu'un de débrouillard, il a grandi, et aujourd'hui tout le monde en dépend.</p>
<h2>Les trois coûts cachés</h2>
<p><strong>1. Le temps de recopie.</strong> Une commande arrive par e-mail, elle est recopiée dans le tableur, puis dans la comptabilité, puis dans un message au client. Chaque recopie prend quelques minutes. Multipliée par le nombre de commandes et par 52 semaines, elle devient un poste à part entière.</p>
<p><strong>2. Les erreurs.</strong> Une ligne effacée, une formule cassée, deux versions du même fichier. Une erreur coûte rarement cher seule. Mais elle se paie en temps de vérification, en clients relancés, en stress.</p>
<p><strong>3. La dépendance.</strong> Souvent, une seule personne comprend vraiment le fichier. Quand elle part en vacances ou quitte l'entreprise, l'outil devient une boîte noire.</p>
<h2>Le calcul en 15 minutes</h2>
<p>Prenez une semaine type et notez, pour chaque tâche liée au tableur&nbsp;:</p>
<ol>
<li>le temps passé à saisir ou recopier des informations déjà écrites ailleurs&nbsp;;</li>
<li>le temps passé à vérifier, corriger, chercher la bonne version&nbsp;;</li>
<li>le nombre de personnes concernées.</li>
</ol>
<p>Multipliez le total par 46 semaines travaillées et par le coût horaire chargé de ces personnes. <em>Exemple fictif&nbsp;:</em> trois personnes qui passent chacune trois heures par semaine en recopie et en vérification, c'est plus de 400 heures par an, soit un quart de temps plein.</p>
<p>Ce chiffre ne dit pas qu'il faut tout changer. Il dit combien vous pouvez investir pour que ça change.</p>
<h2>Les signaux qu'il est temps de passer à autre chose</h2>
<ul>
<li>Vous avez peur d'ouvrir le fichier quand quelqu'un d'autre l'utilise.</li>
<li>Une information est saisie au moins deux fois.</li>
<li>Une seule personne sait comment le fichier fonctionne.</li>
<li>Vos clients ou vos membres attendent une réponse que le tableur ne sait pas donner.</li>
<li>Vous avez renoncé à un projet parce que «&nbsp;ce serait trop compliqué à suivre&nbsp;».</li>
</ul>
<p>Deux ou trois de ces signaux suffisent.</p>
<h2>Remplacer un tableur ne veut pas dire tout informatiser</h2>
<p>L'objectif n'est pas une usine à gaz. C'est un outil qui fait exactement ce que fait votre tableur, sans recopie, avec un historique et des accès par personne. Avec un agent IA en plus, certaines tâches disparaissent complètement&nbsp;: lire un e-mail de commande, préparer la réponse, mettre à jour le stock.</p>
<p>Votre équipe est là pour la mission, pas pour recopier des tableurs.</p>`,
      en: `<p>In most small impact-driven companies, the central tool isn't software. It's a spreadsheet. It holds orders, registrations, stock, volunteers, invoicing. Someone resourceful created it, it grew, and today everyone depends on it.</p>
<h2>The three hidden costs</h2>
<p><strong>1. Copying time.</strong> An order arrives by e-mail, it is copied into the spreadsheet, then into the accounts, then into a message to the customer. Each copy takes a few minutes. Multiplied by the number of orders and by 52 weeks, it becomes a budget line of its own.</p>
<p><strong>2. Mistakes.</strong> A deleted row, a broken formula, two versions of the same file. A single mistake rarely costs much. But you pay for it in checking time, in customers chased, in stress.</p>
<p><strong>3. Dependency.</strong> Often only one person really understands the file. When they go on holiday or leave, the tool becomes a black box.</p>
<h2>The 15-minute calculation</h2>
<p>Take a typical week and note, for each spreadsheet-related task:</p>
<ol>
<li>the time spent entering or copying information already written elsewhere;</li>
<li>the time spent checking, correcting, looking for the right version;</li>
<li>the number of people involved.</li>
</ol>
<p>Multiply the total by 46 working weeks and by the loaded hourly cost of those people. <em>Fictional example:</em> three people who each spend three hours a week copying and checking add up to more than 400 hours a year, a quarter of a full-time job.</p>
<p>That number doesn't say you should change everything. It tells you how much you can invest to make things change.</p>
<h2>Signs it's time to move on</h2>
<ul>
<li>You are afraid to open the file while someone else is using it.</li>
<li>Some information is entered at least twice.</li>
<li>Only one person knows how the file works.</li>
<li>Your customers or members expect an answer the spreadsheet can't give.</li>
<li>You dropped a project because “it would be too complicated to track”.</li>
</ul>
<p>Two or three of these signs are enough.</p>
<h2>Replacing a spreadsheet doesn't mean computerising everything</h2>
<p>The goal isn't a monster system. It's a tool that does exactly what your spreadsheet does, without copying, with a history and per-person access. Add an AI agent and some tasks disappear entirely: reading an order e-mail, drafting the reply, updating the stock.</p>
<p>Your team is here for the mission, not to copy spreadsheets.</p>`,
    },
    next: {
      fr: ["/diagnostic-ia/", "Le Diagnostic IA chiffre en deux semaines ce que vos outils actuels vous coûtent, et ce qu'on peut automatiser en premier."],
      en: ["/en/ai-assessment/", "In two weeks, the AI Assessment puts a number on what your current tools cost you, and what to automate first."],
    },
  },
  {
    slug: { fr: "agent-ia-pme-par-ou-commencer", en: "ai-agent-small-business-where-to-start" },
    date: "2026-10-21",
    title: {
      fr: "Un agent IA dans une PME à impact : par où commencer ?",
      en: "An AI agent in an impact-driven SME: where to start?",
    },
    description: {
      fr: "Un agent IA n'est pas un robot qui remplace une équipe. C'est un collègue qui prend en charge des tâches précises. Comment choisir la première, et les garde-fous.",
      en: "An AI agent isn't a robot that replaces a team. It's a colleague that takes on precise tasks. How to pick the first one, and which safeguards to set.",
    },
    lead: {
      fr: "La bonne question n'est pas « faut-il de l'IA ? », mais « quelle tâche précise pourrait-elle prendre en charge dès le mois prochain ? ».",
      en: "The right question isn't “do we need AI?”, but “which precise task could it take on as soon as next month?”.",
    },
    body: {
      fr: `<p>«&nbsp;L'IA&nbsp;» est partout, et pourtant beaucoup de petites entreprises ne savent pas quoi en faire concrètement. Elles hésitent entre l'enthousiasme et la méfiance. Les deux sont légitimes.</p>
<h2>Ce qu'est un agent IA, concrètement</h2>
<p>Un agent IA est un programme qui lit, comprend et agit dans vos outils. Il peut lire un e-mail, retrouver une information dans votre base, préparer une réponse, mettre à jour une fiche, puis vous demander de valider. Il ne remplace pas une personne. Il lui retire les tâches qui la détournent de son vrai travail.</p>
<h2>Les bonnes premières tâches</h2>
<p>Une bonne première tâche pour un agent a quatre caractéristiques&nbsp;:</p>
<ol>
<li><strong>Elle revient souvent</strong>&nbsp;: chaque jour ou chaque semaine.</li>
<li><strong>Elle suit des règles</strong>&nbsp;: on peut expliquer à un stagiaire comment la faire.</li>
<li><strong>Elle part d'un texte</strong>&nbsp;: un e-mail, un formulaire, un document, une question.</li>
<li><strong>Une erreur se rattrape</strong>&nbsp;: un humain peut relire avant l'envoi.</li>
</ol>
<p>Quelques exemples typiques&nbsp;: trier et préparer les réponses aux demandes entrantes, résumer une réunion et créer les tâches, préparer un devis à partir d'un e-mail, répondre aux questions internes à partir de vos propres documents.</p>
<h2>Ce qu'il vaut mieux éviter au début</h2>
<ul>
<li>Les décisions qui engagent l'entreprise sans relecture humaine.</li>
<li>Les tâches rares, où l'agent n'apprendrait jamais vos habitudes.</li>
<li>Les données dont vous ne maîtrisez pas l'hébergement.</li>
</ul>
<h2>Les garde-fous</h2>
<p>Un agent utile est un agent cadré. Avant de le mettre en service, trois questions&nbsp;:</p>
<ul>
<li><strong>Qu'a-t-il le droit de faire seul, et qu'est-ce qu'il doit faire valider&nbsp;?</strong></li>
<li><strong>Où sont vos données, et qui y a accès&nbsp;?</strong> Chez Super Génial, les applications sont hébergées chez Infomaniak, en Suisse, et l'IA utilisée est Claude, d'Anthropic.</li>
<li><strong>Comment voit-on ce qu'il a fait&nbsp;?</strong> Chaque action doit laisser une trace lisible.</li>
</ul>
<h2>Commencer petit, mesurer, étendre</h2>
<p>La méthode qui marche&nbsp;: une seule tâche, quelques semaines d'essai, une mesure simple (temps gagné, erreurs évitées). Si c'est concluant, on étend. Sinon, on arrête, et on a appris quelque chose à peu de frais.</p>
<p>Un dernier repère&nbsp;: la taille. En dessous d'une dizaine de personnes, une tâche revient rarement assez souvent pour qu'un agent soit rentable. On commence alors par un outil interne bien fait, et l'agent viendra quand l'équipe grandira.</p>`,
      en: `<p>“AI” is everywhere, and yet many small companies don't know what to do with it in practice. They hesitate between enthusiasm and suspicion. Both are legitimate.</p>
<h2>What an AI agent actually is</h2>
<p>An AI agent is a program that reads, understands and acts in your tools. It can read an e-mail, find information in your database, draft a reply, update a record, then ask you to approve. It doesn't replace a person. It takes away the tasks that pull them away from their real work.</p>
<h2>Good first tasks</h2>
<p>A good first task for an agent has four traits:</p>
<ol>
<li><strong>It comes back often</strong>: every day or every week.</li>
<li><strong>It follows rules</strong>: you could explain it to an intern.</li>
<li><strong>It starts from text</strong>: an e-mail, a form, a document, a question.</li>
<li><strong>A mistake can be caught</strong>: a human can review before sending.</li>
</ol>
<p>Typical examples: sorting incoming requests and drafting replies, summarising a meeting and creating the tasks, preparing a quote from an e-mail, answering internal questions from your own documents.</p>
<h2>What to avoid at first</h2>
<ul>
<li>Decisions that commit the company without human review.</li>
<li>Rare tasks, where the agent would never learn your habits.</li>
<li>Data whose hosting you don't control.</li>
</ul>
<h2>The safeguards</h2>
<p>A useful agent is a well-framed agent. Before putting it to work, three questions:</p>
<ul>
<li><strong>What may it do on its own, and what must it have approved?</strong></li>
<li><strong>Where is your data, and who can access it?</strong> At Super Génial, applications are hosted by Infomaniak, in Switzerland, and the AI used is Claude, by Anthropic.</li>
<li><strong>How do you see what it did?</strong> Every action must leave a readable trace.</li>
</ul>
<h2>Start small, measure, extend</h2>
<p>The method that works: a single task, a few weeks of trial, a simple measure (time saved, mistakes avoided). If it works, extend. If not, stop, having learnt something cheaply.</p>
<p>One last guideline: size. Below ten or so people, a task rarely comes back often enough for an agent to pay off. Start with a well-built internal tool instead, and the agent will come as the team grows.</p>`,
    },
    next: {
      fr: ["/diagnostic-ia/", "C'est le principe du Diagnostic IA : deux semaines pour repérer les tâches où un agent ferait gagner le plus, les chiffrer, et décider par où commencer."],
      en: ["/en/ai-assessment/", "That's the idea behind the AI Assessment: two weeks to spot the tasks where an agent would save the most, cost them, and decide where to start."],
    },
  },
  {
    slug: { fr: "application-qui-vieillit", en: "ageing-business-application" },
    date: "2026-10-21",
    title: {
      fr: "Votre application vieillit : reprendre, mettre à jour ou reconstruire ?",
      en: "Your application is ageing: take over, upgrade or rebuild?",
    },
    description: {
      fr: "Une application métier faite il y a des années, que plus personne ne sait faire évoluer. Les signaux d'alerte, les trois options possibles et comment choisir.",
      en: "A business application built years ago that nobody knows how to change anymore. The warning signs, the three possible options and how to choose.",
    },
    lead: {
      fr: "Elle fonctionne. Mais le développeur est parti, le prestataire a fermé, ou la moindre modification coûte une fortune. Et personne n'ose vraiment y toucher.",
      en: "It works. But the developer has left, the agency has closed, or the smallest change costs a fortune. And nobody really dares to touch it.",
    },
    body: {
      fr: `<p>Beaucoup d'entreprises tournent sur une application faite sur mesure il y a cinq, dix ou quinze ans. Avant de décider quoi en faire, il faut savoir où elle en est.</p>
<h2>Les signaux d'alerte</h2>
<ul>
<li><strong>Les mises à jour de sécurité ne sont plus faites.</strong> Le langage, le framework ou le serveur ne sont plus maintenus par leurs éditeurs.</li>
<li><strong>Personne ne connaît le code.</strong> Il n'y a pas de documentation, ou elle date du premier jour.</li>
<li><strong>Chaque petite demande devient un chantier.</strong> Ajouter un champ prend des semaines.</li>
<li><strong>L'hébergement est une boîte noire.</strong> Vous ne savez pas exactement où tourne l'application ni qui y a accès.</li>
<li><strong>Vous contournez l'outil.</strong> Un tableur ou un carnet complète ce que l'application ne sait plus faire.</li>
</ul>
<h2>Trois options</h2>
<ul>
<li><strong>Reprendre et stabiliser</strong>, quand l'application rend encore le service attendu mais que personne ne la maîtrise. Le risque&nbsp;: repousser une mise à jour devenue urgente.</li>
<li><strong>Mettre à jour par paliers</strong>, quand le code est sain mais que la technologie n'est plus maintenue. Le risque&nbsp;: vouloir tout mettre à jour d'un coup.</li>
<li><strong>Reconstruire</strong>, quand le métier a changé et que l'outil ne correspond plus. Le risque&nbsp;: reconstruire à l'identique les défauts de l'ancien.</li>
</ul>
<p>Dans la plupart des cas, la réponse n'est pas «&nbsp;tout jeter&nbsp;». On commence par reprendre&nbsp;: comprendre le code, documenter, sécuriser. Ensuite, on décide en connaissance de cause.</p>
<h2>Comment se passe une reprise</h2>
<ol>
<li><strong>Un audit</strong>&nbsp;: lire le code, lister les versions utilisées, repérer les risques de sécurité.</li>
<li><strong>Une sauvegarde et un environnement de test</strong>&nbsp;: on ne touche jamais directement à la production.</li>
<li><strong>Des mises à jour par petites étapes testées</strong>, plutôt qu'un grand saut.</li>
<li><strong>Une documentation</strong> qui permet à n'importe quel développeur de reprendre la suite.</li>
</ol>
<p>Les agents IA changent la donne sur ce terrain. Lire et documenter un code inconnu, écrire les tests qui manquent, migrer des centaines de fichiers d'une version à l'autre&nbsp;: ce qui prenait des semaines se fait aujourd'hui en quelques jours, sous contrôle humain.</p>
<h2>Et après&nbsp;?</h2>
<p>Une application reprise ne doit plus vieillir en silence. Un abonnement de maintenance la garde à jour, surveillée et documentée. Vous redevenez propriétaire de votre outil&nbsp;: le code source vous est fourni et peut être repris par un autre développeur.</p>`,
      en: `<p>Many companies run on a custom application built five, ten or fifteen years ago. Before deciding what to do with it, you need to know where it stands.</p>
<h2>The warning signs</h2>
<ul>
<li><strong>Security updates are no longer done.</strong> The language, framework or server are no longer maintained by their publishers.</li>
<li><strong>Nobody knows the code.</strong> There is no documentation, or it dates from day one.</li>
<li><strong>Every small request becomes a project.</strong> Adding a field takes weeks.</li>
<li><strong>Hosting is a black box.</strong> You don't know exactly where the application runs or who has access.</li>
<li><strong>You work around the tool.</strong> A spreadsheet or a notebook fills in what the application can no longer do.</li>
</ul>
<h2>Three options</h2>
<ul>
<li><strong>Take over and stabilise</strong>, when the application still does the job but nobody masters it. The risk: postponing an update that has become urgent.</li>
<li><strong>Upgrade in steps</strong>, when the code is sound but the technology is no longer maintained. The risk: trying to update everything at once.</li>
<li><strong>Rebuild</strong>, when the business has changed and the tool no longer fits. The risk: rebuilding the old one's flaws identically.</li>
</ul>
<p>In most cases the answer isn't “throw it all away”. You start by taking over: understanding the code, documenting, securing. Then you decide with full knowledge.</p>
<h2>How a take-over works</h2>
<ol>
<li><strong>An audit</strong>: reading the code, listing the versions in use, spotting security risks.</li>
<li><strong>A backup and a test environment</strong>: production is never touched directly.</li>
<li><strong>Updates in small tested steps</strong>, rather than one big leap.</li>
<li><strong>Documentation</strong> that lets any developer pick up from there.</li>
</ol>
<p>AI agents change the game here. Reading and documenting unknown code, writing the missing tests, migrating hundreds of files from one version to the next: what took weeks now takes days, under human control.</p>
<h2>And then?</h2>
<p>A taken-over application should no longer age in silence. A maintenance subscription keeps it updated, monitored and documented. You own your tool again: the source code is handed over and can be taken over by another developer.</p>`,
    },
    next: {
      fr: ["/maintenance/", "La page Reprise d'application détaille la démarche, pour toute application web, qu'elle soit écrite en Ruby on Rails, en PHP ou autre."],
      en: ["/en/maintenance/", "The Application take-over page details the approach, for any web application, whether it's written in Ruby on Rails, PHP or anything else."],
    },
  },
  {
    slug: { fr: "abonnements-logiciels", en: "software-subscriptions" },
    date: "2026-10-21",
    title: {
      fr: "Vos abonnements logiciels s'empilent : et si vous arrêtiez de louer vos outils ?",
      en: "Your software subscriptions keep piling up: what if you stopped renting your tools?",
    },
    description: {
      fr: "Formulaires, agenda, e-mailing, CRM, automatisations : chaque abonnement est raisonnable, leur somme ne l'est plus. Quand le sur-mesure revient moins cher.",
      en: "Forms, calendar, e-mailing, CRM, automations: each subscription is reasonable, their sum no longer is. When custom software works out cheaper.",
    },
    lead: {
      fr: "Chacun a été choisi pour une bonne raison. Ensemble, ils forment une facture mensuelle que personne n'a vraiment décidée.",
      en: "Each one was chosen for a good reason. Together, they add up to a monthly bill nobody really decided on.",
    },
    body: {
      fr: `<p>Il y a dix ans, une petite entreprise achetait un logiciel. Aujourd'hui, elle loue une dizaine de services en ligne. Un outil de formulaires, un d'agenda, un d'e-mailing, un CRM, une base de données en ligne, un outil d'automatisation pour les relier.</p>
<h2>Pourquoi la facture grimpe sans qu'on le voie</h2>
<ul>
<li><strong>Le prix par utilisateur.</strong> Chaque nouvelle personne dans l'équipe multiplie le coût de chaque outil.</li>
<li><strong>Les paliers.</strong> Dépasser un nombre de contacts, de formulaires ou d'automatisations fait passer à l'offre supérieure.</li>
<li><strong>Les outils de liaison.</strong> Il faut parfois payer un service de plus uniquement pour faire parler les autres entre eux.</li>
<li><strong>Les hausses de prix.</strong> Vous ne les négociez pas, vous les subissez.</li>
</ul>
<h2>Faire l'inventaire en 30 minutes</h2>
<p>Ouvrez vos relevés bancaires des douze derniers mois et listez chaque abonnement logiciel. Pour chacun, notez&nbsp;:</p>
<ul>
<li><strong>le coût annuel, toutes licences comprises</strong>, pour voir le vrai total&nbsp;;</li>
<li><strong>le nombre d'utilisateurs</strong>, pour repérer ce qui grimpe avec l'équipe&nbsp;;</li>
<li><strong>ce que vous en utilisez vraiment</strong>, souvent une petite partie des fonctions&nbsp;;</li>
<li><strong>les données qu'il contient</strong>, pour savoir ce qui serait à reprendre.</li>
</ul>
<p>Le total surprend souvent. Et la troisième ligne est souvent la plus parlante&nbsp;: on paie un outil complet pour trois fonctions.</p>
<h2>Quand un outil sur mesure revient moins cher</h2>
<p>Un outil sur mesure a aussi un coût&nbsp;: sa construction, puis une maintenance mensuelle. Il ne vaut donc pas toujours la peine. Il devient intéressant quand plusieurs de ces conditions sont réunies&nbsp;:</p>
<ul>
<li>plusieurs abonnements servent un même processus (inscrire, facturer, relancer)&nbsp;;</li>
<li>les coûts augmentent avec le nombre d'utilisateurs ou de contacts&nbsp;;</li>
<li>vous n'utilisez qu'une petite partie de chaque outil&nbsp;;</li>
<li>vous recopiez des informations d'un outil à l'autre.</li>
</ul>
<p>Pour une équipe de cinq personnes qui paie deux petits abonnements, le sur-mesure ne sera pas rentable. Mieux vaut le dire tout de suite.</p>
<h2>Comparer sur cinq ans</h2>
<p>Pour comparer honnêtement, additionnez sur cinq ans&nbsp;:</p>
<ul>
<li><strong>d'un côté</strong>, tous les abonnements concernés, au nombre d'utilisateurs prévu, plus le temps passé à recopier et à contourner&nbsp;;</li>
<li><strong>de l'autre</strong>, la construction de l'outil sur mesure, plus sa maintenance mensuelle.</li>
</ul>
<h2>Au-delà de l'argent</h2>
<p>Pour une entreprise à impact, l'argument n'est pas seulement financier.</p>
<ul>
<li><strong>La souveraineté</strong>&nbsp;: vos données sont dans un seul outil, hébergé où vous l'avez choisi, et le code source vous appartient.</li>
<li><strong>La sobriété numérique</strong>&nbsp;: un outil qui fait exactement ce dont vous avez besoin, plutôt que dix services qui font chacun cent choses.</li>
<li><strong>La simplicité</strong>&nbsp;: un seul endroit où chercher, un seul mot de passe, une seule logique.</li>
</ul>
<h2>Ce qui a changé avec les agents IA</h2>
<p>Construire un outil sur mesure demandait hier une équipe et plusieurs mois. Aujourd'hui, un développeur expérimenté qui orchestre des agents IA livre en quelques semaines ce qui prenait un trimestre. C'est ce qui rend le calcul favorable pour des entreprises de 5 à 100 personnes.</p>
<p>La bonne réponse est souvent mixte. On garde un logiciel du marché pour ce qui est standard (comptabilité, messagerie) et on remplace par un outil sur mesure ce qui s'est empilé autour de votre façon de travailler.</p>`,
      en: `<p>Ten years ago, a small company bought software. Today it rents a dozen online services. A forms tool, a calendar tool, an e-mailing tool, a CRM, an online database, an automation tool to connect them.</p>
<h2>Why the bill climbs without anyone noticing</h2>
<ul>
<li><strong>Per-user pricing.</strong> Every new person on the team multiplies the cost of every tool.</li>
<li><strong>Tiers.</strong> Going past a number of contacts, forms or automations pushes you to the next plan.</li>
<li><strong>Glue tools.</strong> Sometimes you pay for one more service just to make the others talk to each other.</li>
<li><strong>Price increases.</strong> You don't negotiate them, you put up with them.</li>
</ul>
<h2>A 30-minute inventory</h2>
<p>Open your bank statements for the last twelve months and list every software subscription. For each one, note:</p>
<ul>
<li><strong>the annual cost, all licences included</strong>, to see the real total;</li>
<li><strong>the number of users</strong>, to spot what grows with the team;</li>
<li><strong>what you actually use</strong>, often a small share of the features;</li>
<li><strong>the data it holds</strong>, to know what would need migrating.</li>
</ul>
<p>The total is often a surprise. And the third line is often the most telling: a full product paid for three features.</p>
<h2>When a custom tool works out cheaper</h2>
<p>A custom tool has a cost too: building it, then monthly maintenance. So it isn't always worth it. It becomes interesting when several of these conditions are met:</p>
<ul>
<li>several subscriptions serve the same process (registering, invoicing, following up);</li>
<li>costs grow with the number of users or contacts;</li>
<li>you only use a small part of each tool;</li>
<li>you copy information from one tool to another.</li>
</ul>
<p>For a five-person team paying two small subscriptions, custom software won't pay off. Better to say so straight away.</p>
<h2>Compare over five years</h2>
<p>To compare honestly, add up over five years:</p>
<ul>
<li><strong>on one side</strong>, all the subscriptions involved, at the expected number of users, plus the time spent copying and working around;</li>
<li><strong>on the other</strong>, building the custom tool, plus its monthly maintenance.</li>
</ul>
<h2>Beyond money</h2>
<p>For an impact-driven company, the argument isn't only financial.</p>
<ul>
<li><strong>Sovereignty</strong>: your data sits in one tool, hosted where you chose, and you own the source code.</li>
<li><strong>Digital sobriety</strong>: one tool that does exactly what you need, rather than ten services that each do a hundred things.</li>
<li><strong>Simplicity</strong>: one place to look, one password, one logic.</li>
</ul>
<h2>What AI agents changed</h2>
<p>Building a custom tool used to take a team and several months. Today, an experienced developer orchestrating AI agents delivers in a few weeks what used to take a quarter. That's what tips the balance for companies of 5 to 100 people.</p>
<p>The right answer is often mixed. Keep off-the-shelf software for what's standard (accounting, e-mail) and replace with a custom tool what has piled up around the way you work.</p>`,
    },
    next: {
      fr: ["/diagnostic-ia/", "Le Diagnostic IA fait cet inventaire avec vous et chiffre l'économie possible sur cinq ans, avant de construire quoi que ce soit."],
      en: ["/en/ai-assessment/", "The AI Assessment runs this inventory with you and costs the possible savings over five years, before anything is built."],
    },
  },
];

const base = (l: Lang) => (l === "fr" ? "/ressources/" : "/en/resources/");
const path = (a: Article, l: Lang) => `${base(l)}${a.slug[l]}/`;
const fmtDate = (d: string, l: Lang) =>
  new Date(d + "T12:00:00Z").toLocaleDateString(l === "fr" ? "fr-BE" : "en-GB", { day: "numeric", month: "long", year: "numeric" });

export function articlePage(a: Article, lang: Lang): string {
  const fr = lang === "fr";
  const alt = { fr: path(a, "fr"), en: path(a, "en") };
  const others = ARTICLES.filter((x) => x !== a);
  const ld = {
    "@context": "https://schema.org",
    "@type": "BlogPosting",
    headline: a.title[lang],
    description: a.description[lang],
    datePublished: a.date,
    dateModified: a.date,
    inLanguage: lang,
    url: SITE_URL + alt[lang],
    mainEntityOfPage: SITE_URL + alt[lang],
    author: { "@type": "Person", name: "Michael Hulet", url: "https://www.linkedin.com/in/michaelhulet/" },
    publisher: { "@id": SITE_URL + "/#business" },
    isPartOf: { "@type": "Blog", name: fr ? "Super Génial · Ressources" : "Super Génial · Resources", url: SITE_URL + base(lang) },
  };
  const body = `
        <article class="article">
            <p class="eyebrow"><a href="${base(lang)}" class="plain">${fr ? "Ressources" : "Resources"}</a></p>
            <h1>${a.title[lang]}</h1>
            <p class="meta-date">${fr ? "Michael Hulet" : "Michael Hulet"} · <time datetime="${a.date}">${fmtDate(a.date, lang)}</time></p>
            <p class="article-lead">${a.lead[lang]}</p>
            <div class="article-body">
${a.body[lang]}
            </div>
            <div class="cta-box">
                <p>${a.next[lang][1]}</p>
                <div class="actions">
                    <a href="${BOOKING[lang]}" class="btn btn-primary plain" data-booking target="_blank" rel="noopener noreferrer">${fr ? "Réserver un call de 30 minutes" : "Book a 30-minute call"} <span class="arr">→</span></a>
                    <a href="${a.next[lang][0]}" class="link-arrow plain">${fr ? "En savoir plus →" : "Learn more →"}</a>
                </div>
            </div>
            <nav class="related" aria-label="${fr ? "À lire aussi" : "Read next"}">
                <h2>${fr ? "À lire aussi" : "Read next"}</h2>
                <ul>${others.map((o) => `<li><a href="${path(o, lang)}">${o.title[lang]}</a></li>`).join("")}</ul>
            </nav>
        </article>`;
  return page({
    lang, path: alt[lang], alt, type: "article", published: a.date,
    title: `${a.title[lang]} · Super Génial`,
    description: a.description[lang],
    og: "ressources", ogAlt: fr ? "Ressources Super Génial" : "Super Génial resources",
    jsonld: [ld, breadcrumbLd([["Super Génial", fr ? "/" : "/en/"], [fr ? "Ressources" : "Resources", base(lang)], [a.title[lang], alt[lang]]])],
    body,
  });
}

export function resourcesIndex(lang: Lang): string {
  const fr = lang === "fr";
  const alt = { fr: "/ressources/", en: "/en/resources/" };
  const items = ARTICLES.map((a, i) => `
                    <a href="${path(a, lang)}" class="res-card plain">
                        <span class="n">0${i + 1}</span>
                        <h2>${a.title[lang]}</h2>
                        <p>${a.description[lang]}</p>
                        <span class="link-arrow">${fr ? "Lire l'article →" : "Read the article →"}</span>
                    </a>`).join("");
  const body = `
        <section class="page-hero">
            <div class="wrap page-hero-grid">
                <div>
                    <p class="eyebrow">${fr ? "Ressources" : "Resources"}</p>
                    <h1 class="display display--page">${fr ? "Avant d'appeler, <em>de quoi y voir clair.</em>" : "Before you call, <em>a few things to see clearly.</em>"}</h1>
                    <p class="lede">${fr ? "Des articles courts pour les dirigeants d'entreprises à impact&nbsp;: ce que coûtent vraiment vos outils, par où commencer avec l'IA, que faire d'une application qui vieillit." : "Short articles for leaders of impact-driven companies: what your tools really cost, where to start with AI, what to do with an ageing application."}</p>
                </div>
                <img class="illu-side" src="/assets/illustrations/lampe-mug.webp" decoding="async" alt="${fr ? "Illustration au trait : une lampe de bureau allumée à côté d'une tasse" : "Line drawing: a lit desk lamp next to a mug"}" width="800" height="800">
            </div>
        </section>
        <section class="sec">
            <div class="wrap">
                <div class="res-grid">${items}
                </div>
                <p class="fine">${fr ? `Vous cherchez les guides techniques sur Rails, Ruby ou Ubuntu&nbsp;? Ils sont rassemblés sur la page <a href="/maintenance/">Reprise d'application</a>.` : `Looking for the technical guides on Rails, Ruby or Ubuntu? They are gathered on the <a href="/en/maintenance/">Application take-over</a> page.`}</p>
            </div>
        </section>`;
  return page({
    lang, path: alt[lang], alt, wide: true,
    title: fr ? "Ressources : outils, IA et abonnements · Super Génial" : "Resources: tools, AI and subscriptions · Super Génial",
    description: fr
      ? "Articles pour les entreprises à impact : le coût caché des tableurs, un premier agent IA, les abonnements logiciels empilés, les applications qui vieillissent."
      : "Articles for impact-driven companies: the hidden cost of spreadsheets, a first AI agent, piling software subscriptions, ageing applications.",
    og: "ressources", ogAlt: fr ? "Ressources Super Génial" : "Super Génial resources",
    jsonld: [breadcrumbLd([["Super Génial", fr ? "/" : "/en/"], [fr ? "Ressources" : "Resources", alt[lang]]])],
    body,
  });
}

export const articlePaths = (a: Article) => ({ fr: path(a, "fr"), en: path(a, "en") });
