# Deployment

This describes how a Trefle API release goes from a tagged commit to
production. The pattern is the canary deploy that shipped v2.0.2: verify the
new image on a deployment that shares production secrets and the production
database, then roll production onto the same tag. There is no isolated
staging environment — at this project's size it costs more than it catches.

## Release

Pushing a `v*` tag triggers the `Release` workflow
(`.github/workflows/release.yml`), which builds the Docker image and
publishes it to `ghcr.io/treflehq/api`, tagged with the version and
`latest`.

```bash
git tag v2.x.y
git push origin v2.x.y
```

Wait for the workflow to finish and the image to land in the registry before
touching any deployment.

## Canary

Point the canary deployment at the new tag and scale it up:

```bash
kubectl set image deployment/trefle-api-next trefle-api-next=ghcr.io/treflehq/api:v2.x.y
kubectl scale deployment/trefle-api-next --replicas=1
```

`trefle-api-next` shares production secrets and the production database with
`trefle-api` — that's what makes the check meaningful instead of synthetic.
Its pod runs `bin/post-start` on boot, which runs `bin/rails db:migrate`;
that's the moment any pending migration actually lands against production
data, not a no-op. See [Migrations](#migrations) below before tagging a
release that includes one.

### Smoke checklist

Hit the canary directly (bypass the main ingress — port-forward or hit the
pod/service address) and confirm:

- [ ] `/`, `/explore`, and `/explore/species/:slug` return 200 and load their
      fingerprinted assets (`*-<hash>.js`/`.css`) without a 404 — a stale
      asset manifest is the most common canary-specific failure.
- [ ] `POST /api/auth/claim` with a valid token returns a JWT, and that JWT
      authenticates a `GET /api/v1/species` call (200).
- [ ] The API response carries `RateLimit-Limit` / `RateLimit-Remaining` /
      `RateLimit-Reset` headers (`config/initializers/rack_attack.rb`).
- [ ] An intentionally unknown filter/order/range key (e.g.
      `GET /api/v1/species?filter[not_a_real_field]=x`) returns 400 with the
      offending key named in `message`.
- [ ] The footer shows the expected tag. `APP_REVISION` is baked into the
      image at build time from the tag (`Dockerfile`, `ENV APP_REVISION`) and
      rendered by `app_revision`/`app_revision_url` in
      `app/helpers/application_helper.rb` — this confirms the pod is
      actually running the new image, not a cached one.

Once all of the above passes, scale the canary back down:

```bash
kubectl scale deployment/trefle-api-next --replicas=0
```

Leaving it running past the switch just means it drifts from `trefle-api`
until the next release, with both serving different code against the same
database in the meantime.

## Switch

Roll the same tag out to production, API first, then the worker:

```bash
kubectl set image deployment/trefle-api trefle-api=ghcr.io/treflehq/api:v2.x.y
kubectl rollout status deployment/trefle-api

kubectl set image deployment/trefle-sidekiq trefle-sidekiq=ghcr.io/treflehq/api:v2.x.y
kubectl rollout status deployment/trefle-sidekiq
```

Watch logs on both during and right after the rollout for `Completed 500`
(or a failing Sidekiq job) — that's the earliest signal of something the
canary's traffic didn't exercise:

```bash
kubectl logs -f deployment/trefle-api --tail=200
kubectl logs -f deployment/trefle-sidekiq --tail=200
```

## Rollback

Deployments are pinned to explicit tags, never `:latest`, specifically so a
rollback is just re-pointing at the previous known-good tag:

```bash
kubectl set image deployment/trefle-api trefle-api=ghcr.io/treflehq/api:v2.x.<previous>
kubectl set image deployment/trefle-sidekiq trefle-sidekiq=ghcr.io/treflehq/api:v2.x.<previous>
```

This only undoes the code. A migration that already ran during the canary
step is not undone by rolling the image back — see below.

## Migrations

Because the canary runs `db:migrate` against the production database before
the switch, **only additive migrations** may ship in a release that goes
through this flow: new tables/columns, new indexes — nothing that drops or
renames something the currently-running `trefle-api`/`trefle-sidekiq` pods
still read. Old code and new code both run against the migrated schema for
as long as the canary is up, and a rollback puts the old code back against a
schema that has already moved forward.

A destructive migration (drop/rename a column, backfill-then-remove) needs
its own plan, not this flow: restore a recent backup into a scratch database
and rehearse the migration together with the corresponding code change
before it ever touches production.
