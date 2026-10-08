# Migrating from upstream Ignite

What a site sees when it moves from `twostraws/Ignite` to this fork.

## Overview

This fork starts from upstream Ignite 0.6.9, and its governing rule is to keep upstream's
public API: new capability is added beside what is there, so that a site written for
upstream should compile against the fork once its Swift tools version is raised. What
differs is what the site *generates*, how a build reports trouble, and how the command-line
tool exits. This article lists every difference a site author will notice. It is drawn from
`CHANGELOG.md` at the root of the package, which has the reasoning behind each one, and
"before" below means that 0.6.9 baseline.

Where a section says a kind of site is unchanged, that is tested: the fork pins what correct
input produced before, so that only the broken cases move.

### Before you build

- The package needs Swift tools 6.2 (upstream: 6.0). The deployment target is still macOS 13.
- Point your site's package at the fork. A site made with `ignite new` depends on
  `https://github.com/twostraws/Ignite`, because the starter template is upstream's; change
  the dependency in its `Package.swift` to `https://github.com/jpurnell/Ignite` on `main`.
- Expect your generated HTML and CSS to differ from upstream's on the first build, for the
  reasons below, and then to be byte-for-byte the same on every build after that.

## Text and markup

Most strings used to be written into the page as they were given. The fork escapes what it
knows to be text or an attribute value, and leaves alone what it knows to be HTML.

- **A string used as an element is still HTML.** `Text("<em>Hi</em>")` and a string in a
  builder are written as given. To show a string exactly as written, use `Text(verbatim:)`,
  or call `escapedForHTML()` on it.
- **Attribute values are escaped.** `&`, `"`, `<` and `>` become `&amp;`, `&quot;`, `&lt;`
  and `&gt;` in every attribute: `id`, `class`, `style`, `href`, `src`, `alt`, `title`,
  `data-*`, `aria-*`, custom attributes and event attributes. An address with `&` in its
  query is written `href="/search?a=1&amp;b=2"`, which a browser reads back as `&`. If you
  wrote character references into an attribute value yourself, write the plain characters
  instead, or they will be shown literally.
- **Plain text is escaped where it cannot be markup:** `Title` and the site's `titleSuffix`,
  text in Markdown, the address and description of a Markdown link or image, `Code` and
  `CodeBlock`, the text of `Link(article)`, `ArticlePreview` descriptions, tag names in
  `Article.tagLinks()`, and a `Table` caption.
- **An article's title and description are plain text.** Taken from Markdown, they have
  their tags removed and every HTML character reference decoded – `&amp;`, `&copy;`,
  `&#8212;` – so a heading `# Tom & Jerry` gives the title `Tom & Jerry` everywhere.
- **JavaScript strings are escaped as JavaScript.** IDs and messages given to `ShowAlert`,
  `ShowModal`, `DismissModal`, `ShowElement`, `HideElement`, `ToggleElementVisibility`,
  `SwitchTheme`, hover effects and the table filter go through `javaScriptStringLiteral()`.
  Use it in an `Action` of your own wherever a Swift string becomes a JavaScript string.
- **`CustomAction` runs the code you give it.** It used to put a backslash before every
  `'`, which broke code such as `document.title = 'Hello'`.
- **`<style>` and `<script>` content cannot close its own element.** `</style` in a
  `MetaStyle` and `</script` in `Script(code:)` are written `<\/style` and `<\/script`.
  JSON-LD writes `<` as `<`.
- **Identifiers given to `Analytics` and `SubscribeForm`** are escaped or percent-encoded
  for the place they are written. A Clicky site ID that is not a number is written as a
  string, with a build warning.
- **Embed IDs** for YouTube, Vimeo and Spotify are percent-encoded into the address.
- **Feeds and the sitemap** XML-escape their addresses and split a `]]>` inside CDATA. The
  RSS feed writes an article's own author when the site has none.

## Generated IDs and class names

- **IDs are numbered, not random.** `Accordion` and its items, `Carousel`, a filterable
  `Table`, `Form`, `SubscribeForm`, `TextField` and a labelled `ControlGroup` take IDs such
  as `ig-accordion-3`, `ig-accordion-3-item-4` and `ig-field-2`, counting from 1 on each
  page. If your own CSS or JavaScript matched the old shape (`accordion` followed by five
  random characters), give the element an ID of your own with `id(_:)`.
- **Animation classes are derived from the animation.** The class used to come from the
  animation's type, so every `Transition` on a site shared one class and the last one
  registered won. The class names in your HTML and in `animations.min.css` change.
- **The rules of a `Style`, the declarations of an `.appear` transition, the `srcset` of an
  `Image`, and articles with the same date** are all written in a fixed order.
- **`Text(placeholderLength:)`** produces the same text on every build.
- **An Atom feed with no entries** is dated `1970-01-01T00:00:00Z`, not the time of the build.

Two builds of an unchanged site now produce identical files.

## Links and paths

### Sites deployed in a subdirectory

On a site whose `url` has a path, such as `https://example.com/docs`:

- Links to the site's own pages include that path. `Link(_:target:)` given a page or an
  article, `Link(article)`, `LinkGroup`, tag links, the logo of a `NavigationBar` and the
  links of `FeedLink` all lead to `/docs/…`. They used to be written from the root of the
  host.
- Every file the site serves is found under that path: scripts (including the ones Ignite
  adds to every `Body`), `Audio` and `Video` sources, `background(image:)` and font files,
  as well as the images and stylesheets, which already were.
- **A string target is still written as you give it.** `Link("About", target: "/about")` is
  the host's `/about`. For a path within the site, use `Link(_:sitePath:)`,
  `Link(sitePath:content:)` or `LinkGroup(sitePath:content:)`. The same holds for a link or
  an image written from the root in Markdown.
- **No `robots.txt` is written.** Crawlers only read `/robots.txt` at the root of a host, so
  the build warns instead and names the lines to add to the host's own file. The sitemap is
  still written.
- If you had been writing the subdirectory into a path yourself, remove it, or it will
  appear twice.

Sites at the root of their host are unchanged by all of the above.

### Relative paths

With `useRelativePaths`, a site is meant to open from a folder. In the fork it does:

- Paths are relative to the page being rendered, climbing to the root from deeper pages
  (`../css/bootstrap.min.css`), and never include a subdirectory's name.
- A link to a page names its file – `about/index.html`, and `index.html` for the home page –
  because `file://` does not open a directory's `index.html`.
- Links and images written from the root in Markdown are made relative to the page showing
  the article.
- Font files in `@font-face` rules are addressed relative to the stylesheet.

### Everywhere

- A link's trailing slash is added to its path only: `/about#team` becomes `/about/#team`,
  where it used to be `/about#team/`. `tel:`, `sms:` and protocol-relative addresses gain
  no slash.
- A `file:` address given to `Link` or `Script` is written as given.
- A privacy-sensitive `Link` is written as an element; its opening tag used to lack its `<`.
- A site whose `url` ends in a slash no longer writes `//css/…`.

## Metadata, feeds and structured data

- `og:image`, `twitter:image`, the feed images and the `image` of `StructuredData.article()`
  are absolute addresses.
- The addresses given to `StructuredData`'s convenience methods and node builders – `url`,
  `image`, `sameAs`, breadcrumb items, `@id` and references to one – are completed with the
  site's address. An address that already has a scheme is unchanged, and the generic
  initializers write what they are given.
- The JSON feed is titled `JSON Feed`, not `JSON Feed Feed`.
- `robots.txt` follows RFC 9309: `DisallowRule(name:)` writes `Disallow: /` (it wrote
  `*`), paths gain a leading slash, and a rule for `*` replaces the closing group instead of
  being cancelled by it.
- `Video` and `Audio` take a file's type from its own extension.
- Front matter may use CRLF or CR line endings, and its dates are read in the Gregorian
  calendar whatever the locale of the machine.

## Bootstrap markup and accessibility

- **Roles produce only classes Bootstrap defines.** `alert-none`, `text-bg-none`,
  `btn-none`, `list-group-item-default`, `text-bg-default`, `border-default` and the like
  are no longer written.
- **A close button is `class="btn-close"` with `aria-label="Close"`.** It used to be
  `btn btn-close` with `label="Close"`.
- **Buttons inside components have no `btn`:** an accordion's header, a carousel's
  indicators and controls, a navigation bar's toggler.
- **Icons are named or hidden.** `Image(systemName:description:)` writes `role="img"` and
  `aria-label` when it has a description and `aria-hidden="true"` when it has none.
  `Label` and `Button(_:systemImage:)` hide their icons, since the text beside them says the
  same, and `Label(_:image:)` writes `alt=""`.
- **Tables:** header cells carry `scope="col"`, and a filter field has `aria-label` and
  `aria-controls`.
- **Forms:** a `TextField` whose label is not shown keeps it as `aria-label`, and a
  `ControlGroup`'s label and help text are tied to the group.
- **A `Modal`** is labelled by its own header (`<modal ID>-label`), not by an ID nothing had.
- **A site with only a dark theme** has its theme written into `:root`; it used to be dropped.

## Colors and numbers

- **`Color(hex:)` reads eight-digit colors as CSS does.** The last two digits are alpha from
  `00` to `FF`: `#FF800080` is 50% opaque, where the digits used to be read as a percentage
  and gave 100%.
  `#RGB` and `#RGBA` are read, and a string with anything but hex digits gives opaque black.
- **Color components are clamped** to 0–255 and opacity to 0–100%, for `Int` and `Double`
  alike. NaN is 0.
- **Numbers in markup do not follow the build machine's locale.** A five-second carousel
  interval is `5000`, not `5,000`; font weights are ASCII digits everywhere.
- `aspectRatio(0)`, `Transition.speed(0)` and a carousel duration that is not finite fall
  back to safe values instead of writing infinity.

## When something is wrong

- **The library does not stop the process.** Every `fatalError` and `precondition` is gone.
  A mistake in a site becomes a build warning with a safe fallback – a keyframe outside
  0–100%, a font whose source is not a URL, an accordion `Item` outside an `Accordion`,
  an oversized feed image – or a thrown `PublishingError`.
- **New warnings** point at things that used to pass in silence: an icon with no description, a
  `Button` with nothing for a screen reader to announce, a `TextField` with no label.
- **Rendering outside a publish** – calling `markup()` from a test – uses a placeholder site
  instead of trapping.
- **You choose where results are written.** `Site.publish(from:buildDirectoryPath:logOptions:output:)`
  takes a ``PublishingOutput``: standard output (the default), standard error, or a closure.
- Diagnostics also go to the unified log, under the subsystem `org.roseclub.ignite`.

## The command-line tool

- **A failed command exits with a non-zero status.** `ignite build`, `ignite new` and
  `ignite run` exit with 1 on every path that writes ❌; they used to exit with 0.
- **Failure is the child's exit status, not its words.** A build whose warnings mention
  `error:` succeeds; a site that exits with 1 and says nothing fails.
- **❌ messages and compiler errors go to standard error.** Progress and ✅ go to standard
  output.
- `ignite run` fails if the local server stops with an error, and `make install` fails if it
  cannot install.
- Commands are run directly, with a time limit, rather than through `bash -c`.

## API added by the fork

These are additions, in keeping with that rule.

- ``PublishingOutput`` and the `publish` methods that take one.
- `Text(verbatim:)`, `String.escapedForHTML()` and `String.javaScriptStringLiteral()`.
- `Link(_:sitePath:)`, `Link(sitePath:content:)` and `LinkGroup(sitePath:content:)`.
- `Text(placeholderLength:using:)`, which takes a random number generator.
- ``StructuredData``, with its `@graph` support and node builders, and the Atom and JSON
  feed formats of ``FeedConfiguration``, which predate the changelog.
