￼mcanouil left a comment (quarto-dev/quarto-web#2087)

@songwupei If I may, once all resources properly sets in the extension manifest or removed if not used, I suggest to:

create "template.qmd" which can be used as a reference document for you to ensure your format extension works and help users start with your extension.

make a new tag/release to ensure users don't use your old invalid version. (Quarto Wizard uses latest tag/release by default).

—
Reply to this email directly, view it on GitHub, or unsubscribe.
You are receiving this because you were mentioned.￼


@cderv requested changes on this pull request.

Thank you for re-submitting.

Can you first reply to songwupei/quarto-gbt9704#1 to confirm what you fixed before we can accept ?

I do believe this is not yet working

See https://github.com/songwupei/quarto-gbt9704/blob/a9e7572ca8505976578d1b8f50fb2c6205932621/_extensions/gbt9704/_extension.yml#L8

formats: docx: reference-doc: assets/reference-gbt9704.docx 

I know Claude Code can be useful, but please do ask it to verify the work against documentation. See
https://github.com/quarto-dev/quarto-cli?tab=contributing-ov-file#using-ai-tools-to-investigate for pointers on what to do.

You can also ask it to test the rendering with your extension to verify it works.

Thanks.

—
Reply to this email directly, view it on GitHub, or unsubscribe.
You are receiving this because you authored the thread.￼
￼cderv left a comment (quarto-dev/quarto-web#2087)

Thank you for re-submitting.

Can you first reply to songwupei/quarto-gbt9704#1 to confirm what you fixed before we can adapt ?

I do believe this is not yet working

See https://github.com/songwupei/quarto-gbt9704/blob/a9e7572ca8505976578d1b8f50fb2c6205932621/_extensions/gbt9704/_extension.yml#L8

formats: docx: reference-doc: assets/reference-gbt9704.docx 

I know Claude Code can be useful, but please do ask it to verify the work against documentation. See
https://github.com/quarto-dev/quarto-cli?tab=contributing-ov-file#using-ai-tools-to-investigate for pointers on what to do.

You can also ask it to test the rendering with your extension to verify it works.

Thanks.

—
Reply to this email directly, view it on GitHub, or unsubscribe.
You are receiving this because you authored the thread.￼


