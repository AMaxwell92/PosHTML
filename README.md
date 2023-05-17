# PosHTML

## Summary

PosHTML ( pronounced "posh-tee-em-el" ) is a simple PowerShell module designed to convert a lightly enriched Markdown syntax to static HTML.

This project was originally created to provide a more visually appealing and easily readable format to review notes I prepared for meetings and similar. Development for this project will continually expand and eventually be folded into a separate tool that will allow generation of entire static websites with.

## Token Support Status

| Markdown Token                   | Interpretation         | Supported |
| -------------------------------- | ---------------------- | --------- |
| 1., 2., 3., ..                   | Ordered list           | ❌        |
| \-                               | Unordered List         | ✅        |
| \#, \#\#, \#\#\#, ..             | Headings ( 1-6 )       | ✅        |
| \*\*text\*\*                     | Bold                   | ✅        |
| \*text\*                         | Italics                | ✅        |
| \>                               | Line Quote             | ✅        |
| \>\>                             | Nested Quotes          | ❌        |
| \`some code\`                    | Inline Code            | ❌        |
| \`\`\`some code\`\`\`            | Code Block             | ❌        |
| \-\-\-                           | Horizontal Rule        | ❌        |
| \[ text \]\( link \)             | Hyperlink              | ✅        |
| \<user@example.com\>             | Mailto: Link           | ❌        |
| \<https://example.com>           | Hyperlink Shorthand    | ❌        |
| \!\[text\]\(example.com/img.png) | Embedded Image         | ❌        |

## Questions & Feedback

This is a hobby project of mine, but I certainly welcome any and all feedback! Have features you'd like to see? Identify a bug in my token parsing? Feel free to reach out via email: <am@hades.so>!
