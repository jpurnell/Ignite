# ``Ignite``

A static site generator for Swift developers.

## Overview

Ignite is a static site builder for Swift developers, offering an expressive, powerful API to build beautiful websites that work great on all devices.

Ignite doesn't try to convert SwiftUI code to HTML, or simply map HTML tags to Swift code. Instead, it aims to use SwiftUI-like syntax to help you build great websites even if you have no knowledge of HTML or CSS.

This is a fork of [Ignite](https://github.com/twostraws/Ignite), maintained separately from it. Its rule is to keep upstream's public API, and it differs in what a site generates, in how a build reports trouble, and in how the command-line tool exits: strings that are text are escaped, generated IDs and class names are the same on every build, links work on a site deployed in a subdirectory and on one opened from a folder, mistakes in a site become build warnings rather than stopping the process, and a failed command exits with a non-zero status. <doc:MigratingFromUpstream> lists every difference.

## Topics

### Essentials

- <doc:MigratingFromUpstream>

### Actions

- ``Action``
- ``CustomAction``
- ``DismissModal``
- ``EventType``
- ``HideElement``
- ``ShowElement``
- ``ShowModal``
- ``ShowAlert``
- ``SwitchTheme``
- ``ToggleElementVisibility``

### Components

- ``FeedLink``
- ``IgniteFooter``

### Elements

- ``Abbreviation``
- ``Accordion``
- ``Alert``
- ``ArticlePreview``
- ``ArticlePreviewStyle``
- ``Audio``
- ``Badge``
- ``Body``
- ``Button``
- ``ButtonGroup``
- ``Card``
- ``Carousel``
- ``Code``
- ``CodeBlock``
- ``Column``
- ``ControlGroup``
- ``Divider``
- ``Dropdown``
- ``DropdownItem``
- ``Embed``
- ``Emphasis``
- ``EmptyHTML``
- ``ForEach``
- ``Form``
- ``Grid``
- ``Group``
- ``Head``
- ``HStack``
- ``Image``
- ``Include``
- ``InlineForEach``
- ``InlineGroup``
- ``Item``
- ``Label``
- ``Link``
- ``LinkGroup``
- ``List``
- ``ListItem``
- ``MetaLink``
- ``MetaStyle``
- ``MetaTag``
- ``Modal``
- ``NavigationBar``
- ``NavigationItemGroup``
- ``PlainDocument``
- ``Quote``
- ``Row``
- ``Script``
- ``Section``
- ``StructuredData``
- ``Slide``
- ``Spacer``
- ``Span``
- ``Strikethrough``
- ``Strong``
- ``SubscribeForm``
- ``Table``
- ``Tag``
- ``Text``
- ``TextField``
- ``Time``
- ``Title``
- ``Underline``
- ``UnderlineProminence``
- ``Video``
- ``VStack``
- ``ZStack``

### Framework

- <doc:Analytics-collection>
- <doc:Animations>
- <doc:ElementTypes>
- <doc:Environment-collection>
- <doc:Queries>
- <doc:Robots>
- ``AnyHTML``
- ``AnyInlineElement``
- ``AriaType``
- ``Article``
- ``ArticleLoader``
- ``ArticlePage``
- ``BorderStyle``
- ``Color``
- ``ControlLabelStyle``
- ``ControlSize``
- ``CoreAttributes``
- ``DecodeAction``
- ``DefaultLayout``
- ``EmailPlatform``
- ``EmptyErrorPage``
- ``EmptyInlineElement``
- ``EmptyLayout``
- ``EmptyTagPage``
- ``ErrorPage``
- ``FeedConfiguration``
- ``HeadForEach``
- ``HighlighterLanguage``
- ``HighlighterTheme``
- ``Language``
- ``Layout``
- ``LayoutContent``
- ``LengthUnit``
- ``LinkRelationship``
- ``LinkTarget``
- ``Markup``
- ``Material``
- ``NavigationBarVisibility``
- ``Property``
- ``Query``
- ``Role``
- ``Site``
- ``StaticPage``
- ``SyntaxHighlighterConfiguration``
- ``TagPage``

### Modifiers

- ``AspectRatio``
- ``BackgroundPosition``
- ``BackgroundImageContentMode``
- ``ContentMode``
- ``Cursor``
- ``EmptyHTMLHoverEffect``
- ``EmptyInlineElementHoverEffect``
- ``ForegroundStyle``
- ``HorizontalAlignment``
- ``LazyLoadable``
- ``LineSpacing``
- ``Position``
- ``PrivacyEncoding``
- ``ResponsiveBoolean``
- ``TextDecoration``
- ``TextSelection``

### Publishing

- ``BootstrapOptions``
- ``PublishingLogOptions``
- ``PublishingOutput``
- ``bundle``
- ``version``

### Rendering

- <doc:Category-collection>
- <doc:Markdown>
- <doc:ResponseErrors>
- <doc:ResultBuilders>
- ``PageMetadata``
- ``SiteMetadata``
- ``TabFocus``
- ``SourceBuildDirectories``

### Styles

- ``Style``
- ``StyledHTML``

### Themes

- <doc:Fonts>
- ``Theme``

### Types

- ``Alignment``
- ``AnchorPoint``
- ``Angle``
- ``Animation``
- ``AnimationOption``
- ``Axis``
- ``ColorScheme``
- ``ColorWeight``
- ``DiagonalEdge``
- ``Edge``
- ``EnvironmentConditions``
- ``FillMode``
- ``Gradient``
- ``HorizontalAlignment``
- ``ImageFit``
- ``OrderedListMarkerStyle``
- ``Percentage``
- ``ResponsiveValues``
- ``Rotation``
- ``SpacingAmount``
- ``Transition``
- ``UnitPoint``
- ``UnorderedListMarkerStyle``
- ``VerticalAlignment``

