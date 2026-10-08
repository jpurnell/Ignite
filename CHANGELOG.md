# Changelog

Changes to this fork of [Ignite](https://github.com/twostraws/Ignite). The fork
diverges from upstream on purpose; this file records only what the fork changed.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- `PublishingOutput`, which says where a publish writes its results – the
  warnings and errors collected during the build, and whether it completed.
  `.standard` writes to standard output and is the default, `.standardError`
  writes to standard error, and `PublishingOutput(sink:)` hands each line to a
  closure of your own.
- `Site.publish(from:buildDirectoryPath:logOptions:output:)` and
  `Site.publish(sourceDirectory:buildDirectory:logOptions:output:)`, which
  publish a site and write its results to a `PublishingOutput` you choose. The
  existing `publish` methods are unchanged and write to standard output.
- `String.javaScriptStringLiteral()`, which writes a string as a complete,
  quoted JavaScript string literal that no input can end early. Use it in your
  own `Action` types wherever a Swift string becomes a JavaScript string. It is
  safe in an event attribute and inside a `<script>` element.
- `String.escapedForHTML()`, which writes `&`, `<`, `>` and `"` as character
  references so that a string is shown as text. Use it on any string you did
  not write yourself before using it as an element.
- `Text(verbatim:)`, which shows a string exactly as written. `Text("…")` is
  unchanged and still treats its string as HTML.
- `Link(_:sitePath:)`, `Link(sitePath:content:)` and
  `LinkGroup(sitePath:content:)`, which link to a path within the site rather
  than within the host. On a site deployed at `https://example.com/docs`,
  `Link("About", sitePath: "/about")` leads to `/docs/about/`.

### Fixed

- **Two builds of an unchanged site produce identical files.** Several things
  in the output changed from one build to the next:
  - Generated IDs were random. `Accordion` and its `Item`s, `Carousel`, a
    filterable `Table`, `Form`, `SubscribeForm` and `TextField` each took a
    new ID on every build. An ID is now the element's kind and a number –
    `ig-accordion-3`, `ig-accordion-3-item-4`, `ig-field-2` – counting the IDs
    given out on the page, starting again at 1 on each page. IDs are unique
    within a page, and a page that has not changed keeps its IDs. If your own
    CSS or JavaScript matched the old shape (`accordion` or `carousel`
    followed by five characters, `table-` followed by five), give the element
    an ID of your own with `id(_:)`.
  - The CSS rules of a `Style` were written in a different order on each
    build, because they were held in a dictionary. The order of rules decides
    which wins when two apply, so a style with several conditions could look
    different from one build to the next. Rules are now written in the order
    Ignite considers the conditions, every time.
  - The declarations of an `.appear` transition were written in a different
    order on each build. They are now the initial value of each property, in
    the order given, followed by the transition.
  - `Video` and `Audio` chose a file's type by looking for any known
    extension anywhere in its name and taking the first found, in an order
    that changed on each build: `podcast.item.mp3` was `audio/mpeg` on one
    build and `audio/it` on the next, and `clip.asfplugin` was sometimes
    `video/x-ms-asf`. The type now comes from the file's own extension,
    whatever its case and ignoring a query or fragment, so `clip.MP4` and
    `clip.mp4?v=2` are recognised too. A name whose extension is not a known
    type is still searched for one, and the longest found is used.
  - Articles with the same date were ordered as the file system listed them,
    which differs between machines. Within a date they are now ordered by
    path. This is the order of `allContent`, of the feeds and of tag pages.
  - An Atom feed with no entries carried the time of the build in `updated`.
    It now carries `1970-01-01T00:00:00Z`; a feed with entries is dated by
    its newest entry, as before.
  - The `srcset` of an `Image` listed its variants in the order the file
    system returned them. They are listed by name.
- **Every transition and animation has its own CSS class.** The class was
  derived from the type of the animation, not from what it does, so every
  `Transition` on a site was given the same class – and likewise every
  `Animation` – and the rules of the last one registered applied to them all.
  A page with a fade and a slide showed two of whichever came last. The class
  is now derived from the animation itself: the same animation shares a class,
  different ones do not. The class names in your HTML and in `animations.min.css`
  change as a result.
- A font family, a font file's address, an `@import` address and a
  `background(image:)` address cannot end the CSS string they are written in.
  A `'` or a backslash in one is escaped (`\'`, `\\`); it used to close
  the string, and the rest of the value became CSS. Values without those
  characters are unchanged.
- **On a site deployed in a subdirectory, links to the site's own pages lead
  to them.** `Link(_:target:)` given a page or an article, `Link(article)`,
  `LinkGroup(target:)` given a page or an article, and the tag links of
  `Article.tagLinks()` wrote the page's path from the root of the host, so on
  `https://example.com/subsite` a link to the About page went to
  `https://example.com/about/`, outside the site. They now include the site's
  path: `/subsite/about/`. If you had been writing the subdirectory into a
  page's `path` yourself, remove it, or it will appear twice. Sites at the
  root of their host are unchanged.

  A string target – `Link("About", target: "/about")` – is still written as
  you give it, since it may be meant for the host: `/about` is the host's
  `/about` on a subsite too. Use the new `Link(_:sitePath:)` for a path
  within the site.
- A link's trailing slash is added to its path and to nothing else.
  `/about#team` is written `/about/#team` where it was `/about#team/`, and
  `/about?tab=2` is `/about/?tab=2`. Addresses with a scheme other than
  `http`, `https` or `mailto` – `tel:+15551234`, `sms:` – and
  protocol-relative addresses (`//cdn.example.com/a`) no longer gain a slash
  at the end. Plain paths, `https:` and `mailto:` addresses are unchanged.
- A privacy-sensitive `Link` or `LinkGroup` is written as an element. Its
  opening tag was missing its `<`, so the page showed the text
  `a href="#" …>` instead of a link.
- **`useRelativePaths` writes paths relative to the page.** It removed the
  leading slash and nothing more, which is only right for a page at the root
  of a site at the root of its host:
  - On a subsite the paths began with the subsite's name
    (`subsite/css/bootstrap.min.css`), which from a page already inside that
    folder points at `subsite/subsite/…`. They no longer do: `css/…`.
  - From a page below the root the paths climb back to it: `/about` reaches
    its stylesheet as `../css/bootstrap.min.css` and links home as `../`. They
    were written `css/…`, which resolved inside `/about/`.
  - A link to the site's root is `./` (or `../` from deeper). It was `/`,
    the root of the disk or the host.
  - A protocol-relative address is left alone. Its first slash was removed,
    turning `//cdn.example.com/a.js` into a local path.
  - Font files in `@font-face` rules are addressed relative to the stylesheet
    (`../fonts/a.woff2`); they kept a path from the root, which does not
    survive the site being moved.

  A single-page site at the root of its host – what the option was written
  for – generates the same output as before.
- Addresses in metadata are absolute. Crawlers and feed readers do not see
  the page an address was written in, so a path means nothing to them:
  - `og:image` and `twitter:image` from a page's or an article's `image`. A
    path such as `/images/share.png` is written
    `https://example.com/images/share.png`, including the site's path on a
    subsite. An image that is already an absolute address is unchanged.
  - The feed image in the RSS (`<image><url>`), Atom (`<icon>`, `<logo>`) and
    JSON (`icon`, `favicon`) feeds.
  - The `image` of `StructuredData.article()`, when it is a path with no
    leading slash; a path with one was already made absolute.

  `og:url`, the canonical link, feed item links, sitemap locations and the
  JSON-LD `url` were already absolute, on subsites too, and are now tested.
- A site published under a path no longer writes a `robots.txt`. Crawlers
  request `/robots.txt` from the root of a host and nowhere else, so
  `https://example.com/subsite/robots.txt` was never read and its rules never
  applied. The build now warns instead, naming the host's `robots.txt`, the
  prefix each path needs there, and the `Sitemap:` line to add. The sitemap
  is still written. Sites at the root of their host are unchanged.
- **`Color(hex:)` reads the alpha of an eight-digit color as CSS defines it,
  and this changes the opacity of every `#RRGGBBAA` color.** The last two
  digits are alpha on the same `00`–`FF` scale as the color channels; they
  were read as a percentage. `#FF800032` is now 20% opaque (0x32 is 50 of
  255), where it was 50%; `#FF800080` is 50%, where it was 100%; only `FF` is
  100%. If you chose the last two digits to get a particular percentage, use
  `Color(hex: "#FF8000").opacity(0.5)` or work out the CSS value (percentage
  × 255 ÷ 100, in hex). Six-digit colors are unchanged. Also:
  - The shorthand forms `#RGB` and `#RGBA` are read, each digit standing for
    itself doubled (`#F80` is `#FF8800`). They used to give black.
  - A string containing anything but hex digits after the `#` gives opaque
    black, as documented. `#12G45678` used to be read as far as the `G`.
  - `Color.opacity` is a whole percentage, so alpha is rounded to the nearest
    percent: `#FF800032` is written `rgb(255 128 0 / 20%)`, not 19.6%.
- A close button has an accessible name. `Button().role(.close)`, and the
  close buttons Ignite adds to modals, carried `label="Close"`, which is not
  an HTML attribute; it is now `aria-label="Close"`.
- A role produces only classes that Bootstrap defines. The colored variants of
  alerts, badges, list items, buttons and links exist for Bootstrap's eight
  theme colors, and a role that is not one of them – `.default`, `.none`,
  `.close` – no longer produces a class named after itself. Elements with one
  of the eight theme-color roles are unchanged. Removed from the output:
  - `Alert`: `alert-none`, `alert-close`.
  - `Badge`: `text-bg-none`, `text-bg-close`, the `-none-` and `-close-`
    forms of the subtle styles, and, for a badge with no role in a subtle
    style, `bg-subtle`, `text-emphasis` and `border-subtle`. A subtle bordered
    badge keeps `border`.
  - `ListItem`: `list-group-item-default`, `list-group-item-none`,
    `list-group-item-close`.
  - `Button`, `Dropdown` and a `Link` styled as a button: `btn-none`.
    `btn-close` is a Bootstrap class and is kept.
  - `Link`: `link-close`. `link-plain`, which `.none` produces, is Ignite's
    own class and is kept.
- `Image` finds the `@2x`, `~dark` and `~light` variants of a file the same
  way on every machine. File names were compared using the build machine's
  locale, under which – in Turkish, for one – `ICON@2x.png` is not a variant
  of `icon.png`. Under an English locale the same variants are found as
  before.
- `ignite build` and `ignite new` decide whether a command worked by its exit
  status. They searched what it wrote to standard error for `error:` or
  `fatal` instead, so a failure that printed neither was reported as
  ✅ success with an exit status of 0, and a successful build whose warnings
  mentioned `error:` was reported as ❌ failed.
  - `ignite build` fails, with exit status 1, when `swift build` or the site's
    own `swift run` exits with a non-zero status, whatever was printed; and
    succeeds when both exit with 0. A site that calls `exit(1)` without a
    message now fails the build.
  - `ignite new` fails when `git clone` exits with a non-zero status.
  - Compiler diagnostics are relayed to standard error as before. When a
    command fails, everything it wrote to standard error is shown, not only
    output containing `error:`.
  - `ignite new` says so if it could not remove the template's `.git`
    directory; it used to ignore that.
- Identifiers given to `Analytics` and `SubscribeForm` can no longer change the
  code or the address they are written into. Identifiers made of letters,
  digits, `-`, `.`, `_` and `~` generate the same output as before.
  - Clicky wrote its site ID into a script as JavaScript, unquoted, so any
    text given as the ID was run as code. An ID made of digits is still written
    as a number. Anything else is written as a JavaScript string, which cannot
    run, and the build warns that a Clicky site ID is a number.
  - The Fathom site ID, the Plausible domain and the TelemetryDeck app ID are
    escaped as attribute values.
  - The Google Analytics measurement ID is percent-encoded in the address of
    the `gtag/js` script, so it cannot add query items to it.
  - The Mailchimp, Kit, SendFox and Buttondown identifiers of `SubscribeForm`
    are percent-encoded into the form's address, so an identifier cannot add a
    path, a query item or another host.
- **Attribute values are escaped.** Every attribute Ignite writes – `id`,
  `class`, `style`, `data-*`, `aria-*`, `href`, `src`, `alt`, `title`, the
  `content` of a `MetaTag`, anything set with `customAttribute` or `attribute`,
  and event attributes – has `&`, `"`, `<` and `>` in its value written as
  `&amp;`, `&quot;`, `&lt;` and `&gt;`. Values were written between double
  quotes as they were given, so a `"` in an article title, an image
  description or a tag ended the attribute, and whatever followed was read as
  more attributes or as markup. Values containing none of those four
  characters are written exactly as before. What changes:
  - An address with `&` in its query is written with `&amp;`:
    `href="/search?a=1&amp;b=2"`. Browsers read that back as `&`. Written bare,
    `&copy=2` could be read as `©=2`. This applies to `Link`, `Image`, `Script`,
    `MetaLink`, `Embed` (including the Spotify address Ignite builds) and the
    Mailchimp address of `SubscribeForm`.
  - `hint(markdown:)` and `hint(html:)` write the hint's HTML into
    `data-bs-title` with its angle brackets escaped
    (`Why, &lt;em&gt;hello&lt;/em&gt; there!`). Bootstrap reads the attribute
    back as the same HTML and shows it as before.
  - Hand-written JavaScript in an event attribute – `CustomAction`, or an
    `Action` of your own – has `&`, `<` and `>` escaped as well as `"`. The
    browser turns them back before running the code, so `if (a && b < c)` runs
    as written. If you had written character references into such code
    yourself to get it through the attribute, write the plain characters
    instead. JavaScript that Ignite generates contains none of the four
    characters and is unchanged.
  - A value that already contains a character reference is text like any
    other: `customAttribute(name: "title", value: "&quot;")` now shows `&quot;`
    rather than `"`.
  - The names of attributes and of `Tag` elements lose any character that
    cannot be part of a name – whitespace, quotes, `<`, `>`, `/`, `=` – since a
    name cannot be escaped. Valid names are unchanged.
  - The attributes Ignite writes by hand are escaped the same way: the `src` of
    `Audio` and `Video` sources, the dark-mode `srcset` of `Image`, the `src`
    and `title` of `Embed`, the placeholder of a `Table` filter, the icon class
    of `Button(_:systemImage:)`, and the `<base target>` of
    `Head.defaultLinkTarget`.
- **Plain text is escaped where Ignite knows it is plain text.** A string used
  as an element (`Text("…")`, a string in a builder) is HTML and is still
  written as given; these are not elements, and were written unescaped:
  - `Title`, and the site's `titleSuffix`: `<title>Tom &amp; Jerry</title>`. A
    title containing `</title>` used to end the element.
  - Text in Markdown. `Tom & Jerry` is written `Tom &amp; Jerry`, and a tag
    written as text – `&lt;script&gt;` or `\<script\>` – stays text; it used to
    be written into the page as a real tag. HTML written in Markdown is still
    passed through.
  - The address of a Markdown link, the address and description of a Markdown
    image, and the language of a fenced code block, which are attributes.
  - Code: `Code`, `CodeBlock`, and Markdown code spans and code blocks escape
    `<`, `>` and `&`, so `Array<Int>` is shown rather than read as a tag.
    Character references already in the code (`&lt;`, `&#60;`) are left alone
    and still show the character they name, so code written the way earlier
    versions asked renders as it did.
  - An article's `title` and `description` taken from its first heading and
    paragraph are plain text: tags are removed, as before, and `&amp;`, `&lt;`,
    `&gt;`, `&quot;`, `&apos;` and numeric references are decoded. A heading
    `# Tom & Jerry` gives the title `Tom & Jerry` in the page title, the
    metadata and the feeds alike.
  - `Link(article)` shows the article's title as text, `ArticlePreview` shows
    its description as text, and `Article.tagLinks()` shows each tag as text.
    A title, description or tag containing HTML is now shown as written
    instead of being rendered.
  - `Table.accessibilityLabel(_:)`: the caption is text.
- JSON-LD from `StructuredData` can no longer close its own `<script>`
  element. Every `<` in the JSON is written as `<`, which means the same
  character inside a JSON string, so a name or description containing
  `</script>` stays data. JSON-LD with no `<` in it is unchanged.
- The RSS feed, the Atom feed and the sitemap stay well-formed whatever an
  article contains:
  - Addresses are XML-escaped (`&` as `&amp;`): item links and GUIDs, the
    site's address, the feed's own address, the feed image, and sitemap `loc`
    entries.
  - A description, author, tag or article body containing `]]>` no longer ends
    its CDATA section; the section is split around it and reads back as the
    same text.
  - The RSS feed writes an article's own author when the site has no author.
    It only wrote `dc:creator` when the site had one.
- A site with only a dark theme has its theme written into `:root`. The
  `:root` ruleset that carries the theme's CSS variables was built and then
  dropped, so `ignite-core.min.css` contained the theme's media queries and
  global rules but none of its colors, fonts or sizes, and the site rendered
  with Bootstrap's defaults. Sites with a light theme, or with alternate
  themes, generate the same CSS as before.
- A font whose source string is not a URL no longer crashes the build. The font
  is created without a source file, referenced by name only, and a warning is
  added to the build.
- Front matter with CRLF or CR line endings is parsed; previously only LF was
  recognised as a line break.
- Front matter that opens with `---` and never closes it no longer crashes. The
  file is treated as having no front matter.
- `Color` no longer traps on a component that is NaN, infinite, or outside the
  range of `Int`. NaN is treated as 0.
- `Carousel` no longer traps on a slide duration that is NaN, infinite, or too
  large to express in whole milliseconds. Such a duration renders as no
  interval.
- `aspectRatio(0)` no longer emits an infinite percentage. A ratio that is not
  positive falls back to square.
- `Transition.speed(0)` no longer produces an infinite duration. A speed that
  is not positive leaves the duration unchanged.
- `Article.date` returns the same instant on every read when the article has no
  date. It used to return the current time afresh on each read, so two reads of
  the same article disagreed. Articles that declare a date, and articles loaded
  from a file, are unaffected.
- The command-line tool's process helper reads both of a command's pipes while
  it runs, so a command that writes more than a pipe holds no longer stalls.
- Numbers written into HTML attributes and CSS no longer follow the locale of
  the machine running the build. They were formatted for a reader, so a value
  of 1,000 or more gained a grouping separator under `en_US` (`5,000`), a
  different one elsewhere (`5.000`, `5 000`), and under locales with their own
  digits even small values changed (`٤٠٠` for a font weight of 400). Values
  below 1,000 built under `en_US` are written exactly as before. Affected:
  - `Carousel` `data-bs-interval`: a slide duration of one second or more.
    Five seconds is now `5000`; it was `5,000`, which Bootstrap cannot read.
  - `CodeBlock.lineNumberVisibility` and the site-wide line number setting on
    `Body`, `data-start`: a first line of 1,000 or more.
  - `Column.columnSpan`, `colspan`: a span of 1,000 or more.
  - `Text.lineLimit`, `--ig-max-line-length`: a limit of 1,000 or more.
  - `lineSpacing` with an exact value, `line-height`: 1,000 or more
    (`1234.5`, not `1,234.5`). The same format writes `opacity`, whose values
    never reach 1,000 and are unchanged.
  - `font-weight` from `fontWeight` and `font`, and the underline opacity
    classes of `Link`: unchanged under `en_US`; fixed under locales that do
    not use ASCII digits.
- Front-matter dates are read in the Gregorian calendar whatever the locale of
  the machine running the build. Under a locale with another calendar the same
  `date: 2024-03-05` was read as a different year (1481 under `th_TH`). Dates
  parsed under Gregorian-calendar locales are unchanged.
- An element ID or message can no longer break out of the JavaScript an action
  generates. `ToggleElementVisibility`, `ShowElement`, `HideElement`,
  `DismissModal` and `ShowModal` wrote the ID straight into a single-quoted
  string, so an ID containing `'`, a backslash, a line break or `</script>`
  ended the string and ran as code; `ShowAlert` escaped `'` but not a backslash
  or a line break. All of them, along with `SwitchTheme`, hover effect values,
  the table filter and the Google Analytics measurement ID, now go through
  `javaScriptStringLiteral()`. IDs and messages made of letters, digits,
  spaces and ordinary punctuation generate the same JavaScript as before.
  - `ShowAlert` writes a double quote in its message as `\u0022` where it wrote
    `&quot;`. Both show a `"` in the alert.
  - A hover effect whose value contains a quote, such as a quoted font family,
    used to generate JavaScript that did not parse; the quote is now escaped.
- `CustomAction` no longer rewrites the JavaScript it is given. It put a
  backslash before every `'`, which is only right inside a string, so
  `CustomAction("document.title = 'Hello'")` produced code that did not parse.
  `compile()` now returns the code as written.
- The JavaScript of every event attribute (`onclick` and the rest) has its
  double quotes written as `&quot;`, so JavaScript containing a `"` cannot end
  the attribute. `CustomAction` used to do this for itself and its markup is
  unchanged; an `Action` of your own that returns a `"` is now handled too.
- `BreakpointQuery` values that are equal now hash alike. `==` compared the
  themes of two queries by prefix – the left theme's ID starting with the
  right's – which is not symmetric, while `hash(into:)` hashed the whole ID, so
  two queries could be equal one way round and not the other, and equal queries
  could land in different buckets of a `Set` or `Dictionary`. Two queries are
  now equal when they have the same breakpoint and the same theme ID, or no
  theme. Nothing in Ignite relied on the prefix match – themed queries are
  created and turned straight into media features – and generated CSS is
  unchanged.
- `Card.cardStyle(.solid)` and `.cardStyle(.bordered)` on a card with no role
  no longer emit `text-bg-default` and `border-default`, which are not
  Bootstrap classes. Bootstrap defines those classes for its eight theme colors
  only, so a card whose role is `.default`, `.none` or `.close` now carries
  `card` alone and looks like a default card. Cards with any other role are
  unchanged.
- `Modal` no longer points `aria-labelledby` at an element that does not exist.
  Every modal carried `aria-labelledby="modalLabel"` and nothing had that ID. A
  modal with a header now gives the header the ID `<modal ID>-label` and refers
  to that, so two modals on a page are labelled separately; a modal with no
  header, or with an empty ID, has no `aria-labelledby` attribute.
- robots.txt follows the Robots Exclusion Protocol (RFC 9309) more closely:
  - `DisallowRule(name:)` and `DisallowRule(robot:)` write `Disallow: /`. They
    wrote `Disallow: *`, which is not a path and matches nothing.
  - A path given without its leading slash is written with one: `private`
    becomes `Disallow: /private`. Paths that begin with `/` are unchanged.
  - A rule for the user agent `*` replaces the closing `User-agent: *` /
    `Allow: /` group instead of being followed by it. Crawlers merge groups for
    the same agent and prefer `Allow` when both match equally, so the closing
    group cancelled `DisallowRule(name: "*")`.
  - The `Sitemap` line has one slash before `sitemap.xml` when the site's URL
    ends in a slash; it had two.
  - A robot name or path containing a line break can no longer start a new
    line of the file.
- `Color(red:green:blue:opacity:)` with `Int` components clamps them, as the
  `Double` initializers do: red, green and blue to 0 through 255, opacity to 0%
  through 100%. Out-of-range values used to pass straight into the CSS, as in
  `rgb(300 -5 128 / 150%)`, and an opacity that was not a number stopped the
  build. In-range colors are unchanged. (Eight-digit hex colors, which this
  clamp first touched, are now read as CSS defines them – see the entry on
  `Color(hex:)` above.)
- A site deployed in a subdirectory (`https://example.com/subsite`) now finds
  all of its own files. Images and stylesheets were already given the
  subdirectory's path; these were not, and so were requested from the root of
  the host, where they do not exist:
  - `Script(file:)` with a path starting with `/`, including the Bootstrap,
    syntax-highlighting and `ignite-core.js` scripts Ignite adds to every
    `Body`: `/js/ignite-core.js` is now `/subsite/js/ignite-core.js`.
  - `Audio` and `Video` sources.
  - `background(image:)`.
  - Font files in `@font-face` rules.

  If you had been writing the subdirectory into one of these paths yourself,
  remove it, or it will appear twice. Sites at the root of their host generate
  the same output as before, as do paths that do not start with `/` and
  addresses on other hosts.
- A site whose `url` ends in a slash (`https://example.com/`) no longer writes
  its stylesheets and images as `//css/…`, which a browser reads as a file on a
  host named `css`. They are written as `/css/…`.
- A protocol-relative address (`//cdn.example.com/…`) is no longer prefixed
  with a subsite's path in a stylesheet link or an image.
- The command-line tool exits with a non-zero status when a command fails.
  `ignite build`, `ignite new` and `ignite run` wrote their ❌ message and then
  exited with 0, so a script or a CI step calling `ignite build` could not tell
  that the build had failed. Every path that writes ❌ now exits with 1: no
  `Package.swift`, a compile error, a failure while generating the site, a
  template address that is not https, a folder that already exists, a failed
  clone, no directory to serve, no free port, and a missing server script. The
  messages are unchanged and still go to standard error; successful commands
  still exit with 0.

### Changed

- `AnimationManager.shared` and `CSSManager.shared` are removed. Both were
  internal, and nothing in the library called either; the managers are reached
  through the publishing context.
- `BoolMatrix.flattened` and `Array2D.flattened` are removed from the command-line
  tool. Nothing read either; a stale index unit had been hiding that from the
  unreachable-code check.

- Force unwraps, `fatalError` calls and other traps were removed from the
  library, the command-line tool and the tests, in favour of thrown errors,
  build warnings and safe fallbacks. No `fatalError` or `precondition` is left
  in the library. The last of them now behave as follows:
  - `KeyframeProxy.callAsFunction` – and so every keyframe – moves a position
    outside 0%–100% to the nearer end and adds a build warning. A position that
    is not a number goes to 0%.
  - `Text(placeholderLength:)` asked for fewer than 1 word produces empty text
    and adds a build warning.
  - `Article.type` is the empty string for content with no type: a Markdown
    file directly in Content, and the empty article a non-article page reads
    from `@Environment(\.article)`.
  - A type of your own that conforms to `NavigationItem` or `FormItem` renders
    its `body`, like any other element you write.
  - `FeedConfiguration.FeedImage` given a size beyond the RSS limit of 144 by
    400 pixels declares the image at the limit and adds a build warning.
  - An accordion `Item` rendered outside an `Accordion` renders on its own and
    adds a build warning.
  - A `Layout` whose `body` is not a document, a `Body` or block HTML – only
    possible by bypassing `@DocumentBuilder` – is rendered as the content of a
    body.
  - `Percentage.roundedValue` returns 0 for a percentage that is not a number,
    and the nearest `Int` for one beyond `Int`'s range.
  - Rendering with no publish in progress – calling `markup()` from a test or a
    script of your own – no longer stops the process. Elements that read site
    settings see a placeholder site with every default, and anything they
    record is discarded, since there is no build to report it to. A warning goes
    to the unified log. Inside `Site.publish()` nothing changes.
- The publish pipeline throws `PublishingError` where it used to stop the
  process with `fatalError`.
- Out-of-range `Color` components given as `Double` are clamped: red, green,
  blue and white to 0 through 255, opacity to 0% through 100%. A component
  above 1 used to pass through as a value above 255. The initializer that
  takes `Int` components clamps to the same ranges.
- Vimeo, YouTube and Spotify embed IDs are percent-encoded into the path of the
  embed address, so an ID cannot change the host or the query.
- The command-line tool runs commands as argument arrays, directly, rather than
  as a string handed to `bash -c`. Every run has a timeout; a command that
  outlives it is sent SIGTERM and then SIGKILL, and reading its output is given
  a bounded time to finish after it exits.
- `Text(placeholderLength:)` produces the same placeholder text on every build
  instead of different text each time, so a generated site is reproducible. A
  new initializer, `Text(placeholderLength:using:)`, takes a caller's random
  number generator.
- The command-line tool writes its ❌ failure messages, and the compiler errors
  it relays from a failed build, to standard error rather than standard
  output.
- Diagnostics – what failed underneath a warning, and why – also go to the
  unified log, under the subsystem `org.roseclub.ignite`. Read them with
  `log stream --predicate 'subsystem == "org.roseclub.ignite"'`.
- Internal declarations that nothing referenced were removed. No public API
  and no generated HTML or CSS changes as a result.
- Tests assert exact expected values, and tests that draw random input use a
  seeded generator.
- `swift-tools-version` is raised from 6.0 to 6.2.
- The package depends on `swift-docc-plugin`, so its documentation can be built
  and checked with `swift package generate-documentation`.

## [0.6.9] - 2026-04-21

The upstream release this fork last tagged, and the baseline the entries above
are measured from. It is not a release of this fork: see the
[upstream release notes](https://github.com/twostraws/Ignite/releases/tag/0.6.9)
for what it contains. The fork's own commits since that tag – Atom and JSON
feeds, the `StructuredData` element, and Swift 6 `Sendable` adoption – predate
this file and are recorded in the Git history.

[Unreleased]: https://github.com/jpurnell/Ignite/compare/0.6.9...HEAD
[0.6.9]: https://github.com/twostraws/Ignite/releases/tag/0.6.9
