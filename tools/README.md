# tools

`og-card.html` génère les cartes de partage social de `assets/og/`. Ce n'est pas une page du site.

Servir la racine du projet, puis ouvrir le template avec les paramètres `t` (titre), `s` (sous-titre) et `i` (chemin de l'illustration), et capturer en 1200×630 :

```
python3 -m http.server 8899 --bind 127.0.0.1
agent-browser set viewport 1200 630 2
agent-browser open "http://127.0.0.1:8899/tools/og-card.html?t=Titre&s=Sous-titre&i=/assets/illustrations/laptop-mug.png"
agent-browser screenshot assets/og/nom.png
sips -z 630 1200 assets/og/nom.png
sips -s format jpeg -s formatOptions 82 assets/og/nom.png --out assets/og/nom.jpg && rm assets/og/nom.png
```

Paramètres optionnels : `u` remplace la ligne de pied (défaut « supergenial.be · outils internes et agents IA sur mesure ») ; dans `t`, `*mot*` passe en italique mauve.

## Générer le site

Les pages principales, les articles de Ressources et les redirections sont écrites par `tools/site/build.ts`. La coquille commune (menu, pied de page, `<head>`, Plausible, lien de réservation `BOOKING`) vient d'une seule source : `tools/site/layout.ts`. Pipeline complet, idempotent :

```
bun realisations/build.ts && bun realisations/en-build.ts && bun tools/site/build.ts && bun ressources/langswitch.ts && bun ressources/mainnav.ts && bun ressources/seo.ts
```

Pour changer le lien « Réserver un call », modifier `BOOKING` dans `tools/site/layout.ts` puis relancer le pipeline.

## Déploiement sur le serveur Semisto (Coolify)

`Dockerfile` + `deploy/nginx.conf` : nginx sert les fichiers du dépôt tels quels (aucune étape de build, les pages sont commitées). `.dockerignore` écarte les sources (`*.ts`, `_drafts`, `tools/`, notes). L'apex `supergenial.be` redirige en 301 vers `www.supergenial.be` ; tout autre hôte (sous-domaine d'essai) est servi tel quel. En ligne depuis le 24/10/2026 : app Coolify sur dash.semisto.org (build pack Dockerfile, **port 80**), déployée à chaque push sur `main`. DNS chez Cloudflare (`@` et `www` en A proxifiés vers le VPS, SSL/TLS Full) ; le pare-feu du VPS n'accepte que Cloudflare, donc un `curl` direct sur l'IP expire.
