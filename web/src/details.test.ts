import assert from "node:assert/strict";
import test from "node:test";
import {
  buildDetailsPageUrl,
  collapseDuplicatedTitle,
  decodeQueryValue,
  normalizeTitle,
  parseDetailsSearchParams,
  posterImageUrl,
  renderDetailsPage,
} from "./details.ts";

test("decodeQueryValue unwraps double-encoded titles", () => {
  assert.equal(
    decodeQueryValue("Spider-Man:%2520Brand%2520New%2520Day"),
    "Spider-Man: Brand New Day"
  );
});

test("collapseDuplicatedTitle removes accidental repeats", () => {
  assert.equal(
    collapseDuplicatedTitle("Spider-Man: Brand New Day Spider-Man: Brand New Day"),
    "Spider-Man: Brand New Day"
  );
});

test("normalizeTitle fixes the broken production share URL", () => {
  const broken =
    "Spider-Man:%2520Brand%2520New%2520Day%20Spider-Man:%20Brand%20New%20Day";
  assert.equal(normalizeTitle(broken), "Spider-Man: Brand New Day");
});

test("posterImageUrl normalizes leading slash", () => {
  assert.equal(
    posterImageUrl("/bjiS5ipwxb9JFy3XRRN4OAilSeX.jpg"),
    "https://image.tmdb.org/t/p/w780/bjiS5ipwxb9JFy3XRRN4OAilSeX.jpg"
  );
});

test("posterImageUrl strips title accidentally appended by share targets", () => {
  assert.equal(
    posterImageUrl("7WsyChQLEftFiDOVTGkv3hFpyyt.jpg Avengers: Infinity War"),
    "https://image.tmdb.org/t/p/w780/7WsyChQLEftFiDOVTGkv3hFpyyt.jpg"
  );
});

test("parseDetailsSearchParams renders clean title and poster", () => {
  const params = new URLSearchParams(
    "id=969681@0&img=/bjiS5ipwxb9JFy3XRRN4OAilSeX.jpg&title=Spider-Man:%2520Brand%2520New%2520Day%20Spider-Man:%20Brand%20New%20Day"
  );
  const details = parseDetailsSearchParams(params);
  assert.equal(details.title, "Spider-Man: Brand New Day");
  assert.equal(details.mediaTypeLabel, "Movie");
  assert.equal(
    details.posterUrl,
    "https://image.tmdb.org/t/p/w780/bjiS5ipwxb9JFy3XRRN4OAilSeX.jpg"
  );
});

test("buildDetailsPageUrl encodes title once", () => {
  const url = buildDetailsPageUrl({
    id: "969681@0",
    title: "Spider-Man: Brand New Day",
    img: "bjiS5ipwxb9JFy3XRRN4OAilSeX.jpg",
  });
  assert.equal(
    url,
    "https://www.cronica.watch/details?id=969681%400&title=Spider-Man%3A+Brand+New+Day&img=bjiS5ipwxb9JFy3XRRN4OAilSeX.jpg"
  );
  const parsed = parseDetailsSearchParams(new URL(url).searchParams);
  assert.equal(parsed.title, "Spider-Man: Brand New Day");
});

test("parseDetailsSearchParams ignores invalid media type suffixes", () => {
  const params = new URLSearchParams("id=123@9&title=Mystery");
  const details = parseDetailsSearchParams(params);
  assert.equal(details.mediaTypeLabel, "");
  assert.equal(details.tmdbUrl, null);
  assert.equal(details.deepLinkUrl, "cronica://123@9");
});

test("parseDetailsSearchParams uses cronica deep link for Open in Cronica", () => {
  const params = new URLSearchParams("id=969681@0&title=Test");
  const details = parseDetailsSearchParams(params);
  assert.equal(details.deepLinkUrl, "cronica://969681@0");
});

test("renderDetailsPage uses clean social title", () => {
  const html = renderDetailsPage(
    new URL(
      "https://www.cronica.watch/details?id=969681@0&img=bji.jpg&title=Spider-Man%3A%20Brand%20New%20Day"
    )
  );
  assert.match(html, /<title>Spider-Man: Brand New Day — Cronica<\/title>/);
  assert.match(html, /property="og:title" content="Spider-Man: Brand New Day"/);
  assert.match(html, /href="cronica:\/\/969681@0"/);
  assert.doesNotMatch(html, /%20|%2520/);
});
