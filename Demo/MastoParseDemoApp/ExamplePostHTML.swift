//
//  ExamplePostHTML.swift
//  TestingStrings
//
//  Created by Shannon Hughes on 6/25/25.
//

let examples : [String] = [
    
    "<p>This is a post with a blockquote...</p>\n<blockquote>\n  <p>This thing, here, is a block quote<br>with some <strong>bold</strong> as well</p>\n  <blockquote> I can even nest another blockquote!<blockquote>And then nest yet another one! But we'll keep this one short.</blockquote>\n  <ul>\n    <li>Here is the first item in a list which is still inside the first blockquote</li>\n    <li>\n      and here is a second item with\n      <ul>\n        <li>a second level of list items<blockquote> and a nested blockquote! inside the list item!</blockquote></li>\n        <li>here's another secondary list item</li>\n      </ul>\n    </li>\n  </ul>\n </blockquote> <p>Here is some plaintext after the list. This is still inside the first blockquote.</p><blockquote> Here's another nested blockquote! This could go on and on and on, but just long enough to wrap would be ok.</blockquote></blockquote>",
   
    "<p>This is a post with a list...</p>\n <ul>\n    <li>which has blockquote nested inside this item: <blockquote>Imagine a beautiful quotation!  Isn't it <strong>so</strong> lovely!</blockquote></li>\n    <li>\n      and another list item with\n      <ul>\n        <li>nested</li>\n        <li>items!</li>\n      </ul>\n    </li>\n  </ul>\n <p>Some plaintext after the list.</p><blockquote> And another blockquote! Just another silly blockquote...</blockquote></blockquote>",
    
    "<p>This is a post with a variety of HTML in it</p>\n<p>For instance, <strong>this text is bold</strong> and <b>this one as well</b>, while <del>this text is stricken through</del> and <s>this one as well</s>.</p>\n<blockquote>\n  <p>This thing, here, is a block quote<br>with some <strong>bold</strong> as well</p>\n  <ul>\n    <li>a list item</li>\n    <li>\n      and another with\n      <ul>\n        <li>nested</li>\n        <li>items!</li>\n      </ul>\n    </li>\n  </ul>\n</blockquote>\n<pre><code>// And this is some code\n// with some comments\nlet x = 5</code></pre>\n<p>And this is <code>inline</code> code</p>\n<p>Finally, please observe this Ruby element: <ruby> 明日 <rp>(</rp><rt>Ashita</rt><rp>)</rp> </ruby></p>\n",

    "<p>A blog… <a href=\"https://blog.joinmastodon.org/2025/06/mastodon-dpga/\" target=\"_blank\" rel=\"nofollow noopener\" translate=\"no\"><span class=\"invisible\">https://</span><span class=\"ellipsis\">blog.joinmastodon.org/2025/06/</span><span class=\"invisible\">mastodon-dpga/</span></a></p><p>Can be a great thing to read!</p>",
    
    "<p>This is a post with an unordered list:</p>\n  <ul>\n    <li>a list item</li>\n    <li>\n      and another with\n      <ul>\n        <li>nested</li>\n        <li>items!</li>\n      </ul>\n    </li>\n  </ul>",
   
    "<p>This is a post with an ordered list:</p>\n  <ol>\n    <li>a list item</li>\n    <li>\n      and another with\n      <ol>\n        <li>nested</li>\n        <li>items!</li>\n      </ol>\n    </li>\n <li>a final, unnested list item</li> </ol>",
    
    "<p>This is a self-quote of a remote formatted post</p>\n<p class=\"quote-inline\">RE: <a href=\"https://example.org/foo/bar/baz\" rel=\"nofollow noopener\" target=\"_blank\">https://example.org/foo/bar/baz</a></p>\n"
]
