Import-Module .\src\MDToHTML.psm1

$html_template = ( get-content .\templates\page.html ) -join "`n"

<#
    Params:
        In : string
            Path to your markdown file
        Out : string
            Desired HTML file output path
        Template : string | $null
            Optional HTML templage file path
#>
Convert-MDToHTML -In .\markdown\example.md -Out .\html\example.html -Template $html_template
