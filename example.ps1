Import-Module .\src\PosHTML.psm1

<#
    Params:
        In : string
            Path to your markdown file
        Out : string
            Desired HTML file output path
        Template : string | $null
            Optional HTML templage file path - the first string formatting token - {0} - will be targeted for translated HTML
#>
# ConvertTo-PosHTML -In .\markdown\example.md -Out .\html\example.html

# generate the site
new-poshtmlsite -docroot 'D:\Cloud\personal\Profile\Documents\Repositories\PosHTML\markdown' -outdir 'D:\Cloud\personal\Profile\Documents\Repositories\PosHTML\docs' -pathprefix '/PosHTML'

# copy the stylesheet
copy-item '.\src\style.css' '.\docs\style.css'
