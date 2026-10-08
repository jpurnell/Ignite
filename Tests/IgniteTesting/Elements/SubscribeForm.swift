//
// SubscribeForm.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Testing
@testable import Ignite

/// Tests for the `SubscribeForm` element.
@Suite("Subscribe Form Tests")
class SubscribeFormTests: IgniteTestSuite {
    @Test("Basic Subscribe Form", .publishingContext())
    func form() async throws {
        let element = SubscribeForm(.sendFox(listID: "myListID", formID: "myID"))
            .emailFieldLabel("MyLabel")
            .labelStyle(.floating)

        let output = element.markupString()

        #expect(output == """
        <form id="myID" method="post" target="_blank" action="https://sendfox.com/form/myListID/myID" \
        class="sendfox-form row g-3" data-async data-recaptcha="true">\
        <div class="col">\
        <div class="form-floating">\
        <input id="sendfox_form_email" placeholder="MyLabel" \
        type="text" name="email" class="form-control col" />\
        <label for="sendfox_form_email">MyLabel</label>\
        </div>\
        </div>\
        <div class="col-auto d-flex align-items-stretch">\
        <button type="submit" class="col-auto w-100 btn btn-primary">Subscribe</button>\
        </div>\
        <fieldset style="position: absolute; left: -5000px;" aria-hidden="true">\
        <div class="form-floating">\
        <input type="text" name="a_password" tabindex="-1" value="" autocomplete="off" \
        class="form-control" />\
        </div>\
        </fieldset>\
        </form>\
        <script charset="utf-8" src="https://cdn.sendfox.com/js/form.js"></script>
        """)
    }

    @Test("Mailchimp form uses correct endpoint and form ID", .publishingContext())
    func mailchimpForm() async throws {
        let element = SubscribeForm(.mailchimp(username: "user", uValue: "abc", listID: "123"))
        let output = element.markupString()
        // The address's `&` is written as `&amp;`, as it must be inside an attribute; a
        // browser reads it back as `&`. It was written bare, which HTML does not allow.
        #expect(output.contains("action=\"https://user.us1.list-manage.com/subscribe/post?u=abc&amp;id=123\""))
        #expect(output.contains("id=\"mc-embedded-subscribe-form\""))
        #expect(output.contains("name=\"mc-embedded-subscribe-form\""))
    }

    @Test("Kit form uses correct endpoint and email field name", .publishingContext())
    func kitForm() async throws {
        let element = SubscribeForm(.kit("myToken"))
        let output = element.markupString()
        #expect(output.contains("action=\"https://app.convertkit.com/forms/myToken/subscriptions\""))
        #expect(output.contains("name=\"email_address\""))
    }

    @Test("Buttondown form uses correct endpoint and form class", .publishingContext())
    func buttondownForm() async throws {
        let element = SubscribeForm(.buttondown("myuser"))
        let output = element.markupString()
        #expect(output.contains("action=\"https://buttondown.com/api/emails/embed-subscribe/myuser\""))
        #expect(output.contains("embeddable-buttondown-form"))
    }

    @Test("Custom subscribe button label renders correctly", .publishingContext())
    func customButtonLabel() async throws {
        let element = SubscribeForm(.sendFox(listID: "x", formID: "y"))
            .subscribeButtonLabel("Join Now")
        let output = element.markupString()
        #expect(output.contains(">Join Now</button>"))
    }

    // MARK: - Form style

    @Test("Stacked form style changes layout to vertical", .publishingContext())
    func stackedFormStyle() async throws {
        let element = SubscribeForm(.sendFox(listID: "x", formID: "y"))
            .formStyle(.stacked)
        let output = element.markupString()
        #expect(output.contains("col-md-12"))
        #expect(output.contains("w-100"))
    }

    // MARK: - Control size

    @Test("Small control size adds small classes", .publishingContext())
    func smallControlSize() async throws {
        let element = SubscribeForm(.sendFox(listID: "x", formID: "y"))
            .controlSize(.small)
        let output = element.markupString()
        #expect(output.contains("form-control-sm"))
        #expect(output.contains("btn-sm"))
    }

    @Test("Large control size adds large classes", .publishingContext())
    func largeControlSize() async throws {
        let element = SubscribeForm(.sendFox(listID: "x", formID: "y"))
            .controlSize(.large)
        let output = element.markupString()
        #expect(output.contains("form-control-lg"))
        #expect(output.contains("btn-lg"))
    }

    // MARK: - Button customization

    @Test("Custom button role changes button class", .publishingContext())
    func customButtonRole() async throws {
        let element = SubscribeForm(.sendFox(listID: "x", formID: "y"))
            .subscribeButtonRole(.danger)
        let output = element.markupString()
        #expect(output.contains("btn-danger"))
        #expect(!output.contains("btn-primary"))
    }

    // MARK: - Provider-specific behavior

    @Test("Mailchimp form includes honeypot field with correct name", .publishingContext())
    func mailchimpHoneypot() async throws {
        let element = SubscribeForm(.mailchimp(username: "user", uValue: "abc", listID: "123"))
        let output = element.markupString()
        #expect(output.contains("name=\"b_abc_123\""))
        #expect(output.contains("aria-hidden=\"true\""))
    }

    @Test("Kit form has no honeypot field and no external script", .publishingContext())
    func kitNoHoneypotNoScript() async throws {
        let element = SubscribeForm(.kit("myToken"))
        let output = element.markupString()
        #expect(!output.contains("aria-hidden"))
        #expect(!output.contains("<script"))
    }

    @Test("A newsletter identifier cannot add to the form's address", .publishingContext(), arguments: [
        (EmailPlatform.mailchimp(username: "user", uValue: "a&b=c", listID: "1#2"),
         "https://user.us1.list-manage.com/subscribe/post?u=a%26b%3Dc&id=1%232"),
        (EmailPlatform.mailchimp(username: "evil.example/x?", uValue: "a", listID: "1"),
         "https://evil.example%2Fx%3F.us1.list-manage.com/subscribe/post?u=a&id=1"),
        (EmailPlatform.kit("abc/../def?x"), "https://app.convertkit.com/forms/abc%2F..%2Fdef%3Fx/subscriptions"),
        (EmailPlatform.sendFox(listID: "1/2", formID: "3?4"), "https://sendfox.com/form/1%2F2/3%3F4"),
        (EmailPlatform.buttondown("me#you"), "https://buttondown.com/api/emails/embed-subscribe/me%23you")
    ])
    func identifiersAreEncoded(platform: EmailPlatform, expected: String) {
        #expect(platform.endpoint == expected)
    }

    @Test("Ordinary newsletter identifiers give the same address as before", .publishingContext(), arguments: [
        (EmailPlatform.mailchimp(username: "user", uValue: "abc", listID: "123"),
         "https://user.us1.list-manage.com/subscribe/post?u=abc&id=123"),
        (EmailPlatform.kit("a1b2c3"), "https://app.convertkit.com/forms/a1b2c3/subscriptions"),
        (EmailPlatform.sendFox(listID: "my-list", formID: "form_1"), "https://sendfox.com/form/my-list/form_1"),
        (EmailPlatform.buttondown("user.name"), "https://buttondown.com/api/emails/embed-subscribe/user.name")
    ])
    func ordinaryIdentifiers(platform: EmailPlatform, expected: String) {
        #expect(platform.endpoint == expected)
    }
}
