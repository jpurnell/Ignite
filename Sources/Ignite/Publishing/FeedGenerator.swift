//
// FeedGenerator.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

struct FeedGenerator {
    var feedConfig: FeedConfiguration
    var site: any Site
    var content: [Article]

    init(config: FeedConfiguration, site: any Site, content: [Article]) {
        self.feedConfig = config
        self.site = site
        self.content = content
    }

    func generateFeed() -> String {
        let contentXML = generateContentXML()
        var result = generateRSSHeader()

        if let image = feedConfig.image {
            result += """
            <image>\
            <url>\(image.url.escapedForXML())</url>\
            <title>\(site.name.escapedForXML())</title>\
            <link>\(site.url.absoluteString.escapedForXML())</link>\
            <width>\(image.width)</width>\
            <height>\(image.height)</height>\
            </image>
            """
        }

        result += """
        \(contentXML)\
        </channel>\
        </rss>
        """

        return result
    }

    private func generateContentXML() -> String {
        content
            .prefix(feedConfig.contentCount)
            .map { item in
                var itemXML = """
                <item>\
                <guid isPermaLink="true">\(item.path(in: site).escapedForXML())</guid>\
                <title>\(item.title.escapedForXML())</title>\
                <link>\(item.path(in: site).escapedForXML())</link>\
                <description>\(item.description.wrappedInCDATA())</description>\
                <pubDate>\(item.date.asRFC822(timeZone: site.timeZone))</pubDate>
                """

                let authorName = item.author ?? site.author

                if authorName.isEmpty == false {
                    itemXML += "<dc:creator>\(authorName.wrappedInCDATA())</dc:creator>"
                }

                item.tags?.forEach { tag in
                    itemXML += "<category>\(tag.wrappedInCDATA())</category>"
                }

                if feedConfig.mode == .full {
                    itemXML += """
                    <content:encoded>\
                    \(item.text.makingAbsoluteLinks(relativeTo: site.url).wrappedInCDATA())\
                    </content:encoded>
                    """
                }

                itemXML += "</item>"
                return itemXML
            }.joined()
    }

    private func generateRSSHeader() -> String {
        """
        <?xml version="1.0" encoding="UTF-8" ?>\
        <rss version="2.0" \
        xmlns:dc="http://purl.org/dc/elements/1.1/" \
        xmlns:atom="http://www.w3.org/2005/Atom" \
        xmlns:content="http://purl.org/rss/1.0/modules/content/">\
        <channel>\
        <title>\(site.name.escapedForXML())</title>\
        <description>\((site.description ?? "").escapedForXML())</description>\
        <link>\(site.url.absoluteString.escapedForXML())</link>\
        <atom:link
            href="\(site.url.appending(path: feedConfig.path).absoluteString.escapedForXML())"
            rel="self" type="application/rss+xml"
        />\
        <language>\(site.language.rawValue)</language>\
        <generator>\(Ignite.version)</generator>
        """
    }
}
