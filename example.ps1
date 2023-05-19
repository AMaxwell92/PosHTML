Import-Module .\src\PosHTML.psm1

$htmlTemplate = ( get-content .\templates\page.html ) -join "`n"

<#
    Params:
        In : string
            Path to your markdown file
        Out : string
            Desired HTML file output path
        Template : string | $null
            Optional HTML templage file path - the first string formatting token - {0} - will be targeted for translated HTML
#>
ConvertTo-PosHTML -In .\markdown\example.md -Out .\html\example.html -Template $htmlTemplate
