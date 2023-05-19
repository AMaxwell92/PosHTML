import-module .\src\poshtml.psm1

$siteParams    = @{
    docroot    = 'D:\Cloud\personal\Profile\Documents\Repositories\PosHTML\markdown'
    outdir     = 'D:\Cloud\personal\Profile\Documents\Repositories\PosHTML\docs' }

# generate the site
new-poshtmlsite  @siteParams

# copy the stylesheet
copy-item '.\src\style.css' '.\docs\assets\css\style.css'
