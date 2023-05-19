
# default html skeleton
$htmlFormat = @'
    <!DOCTYPE html>
    <html>
    <head>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="style.css" />
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Roboto%20Mono"/>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Roboto" />
    </head>
    <body>
    <header></header>
    <div class="content-container">
    {0}</div>
    <footer></footer>
    </body>
    </html>
'@

# callout html format
$calloutFormat = @'
    <callout>
    <callout-icon>
    💡
    </callout-icon>
    <callout-content>
    {0}
    </callout-content>
    </callout>
'@

function ConvertTo-PosHTML {
    param(
        [ parameter( mandatory = $true  ) ] [ string ] $In,
        [ parameter( mandatory = $true  ) ] [ string ] $Out,
        [ parameter( mandatory = $false ) ] [ string ] $Template = $htmlFormat
    )

    $page          = ''
    $indent        = ''
    $ulLevel       = 0
    $tableLevel    = 0
    $quoteLevel    = 0
    $codeBlockOpen = $false

    # iterate file lines
    Get-Content $In | % {

        # capture pipeline input
        $line = $_

        try {

            # get leading spaces
            $spaces = ( select-string -pattern '^(\s+)' -inputobject $line ).matches.groups[ 1 ].value }

        catch {

            # set a default value
            $spaces = '' }

        finally {

            # trim string
            $line = $line.trim()

            # get indent level
            $indentLevel = [ system.math ]::floor( $spaces.length / 4 ) }

        # bold text
        $pattern = '\*{2}(?!\*)(.+?)\*{2}'
        if ( $line -match $pattern ) {
            $line = $line -replace $pattern, "<b>`$1</b>" }

        # italicized text
        $pattern = '\*(?!\*)(.+?)\*'
        if ( $line -match $pattern ) {
            $line = $line -replace $pattern, "<i>`$1</i>" }

        # hyperlinks
        $pattern = '\[(.*?)\]\((.+?)\)'
        if ( $line -match $pattern ) {
            $line = $line -replace $pattern, "<a href=`"`$2`">`n`$1`n</a>`n" }

        # underlined text
        $pattern = '_(.*?)_'
        if ( $line -match $pattern ) {
            $line = $line -replace $pattern, "<u>`$1</u>" }

        # headings
        $pattern = '^(#{1,})\s(.*)'
        if ( $line -match $pattern ) {
            $headingLevel = ( select-string $pattern -inputobject $line ).matches.groups[ 1 ].value.length
            $page += $line -replace $pattern, "<h$headingLevel>`n`$2`n</h$headingLevel>`n"
            return }

        # unordered lists
        $pattern = '^\-\s'
        if ( $line -match $pattern ) {

            # set offset for ulLevel to indentLevel comparison
            $ulOffset = $ulLevel - 1

            # open the unordered list, if necessary
            if ( $indentLevel -gt $ulOffset ) {
                $ulLevel += 1
                $page += "<ul>`n" }

            # close the unordered list on deindent
            elseif ( $indentLevel -lt $ulOffset ) {
                $page += "</ul>`n" * ( $ulOffset - $indentLevel )
                $ulLevel -= $ulOffset - $indentLevel }

            # create the list item
            $line = "<li>`n$( $line -replace $pattern )`n</li>`n" }

        # close any open lists
        elseif ( $ulLevel -gt 0 ) {
            $page += "</ul>`n" * $ulLevel
            $ulLevel = 0 }

        # callouts
        $pattern = '^\{(.*?)\}'
        if ( $line -match $pattern ) {
            $line = $line -replace $pattern, '$1'
            $page += $calloutFormat -f $line.trim()
            return }

        # tables
        $pattern = '^\|.*\|$'
        if ( $line -match $pattern ) {

            if ( $tableLevel -eq 0 ) {

                # open the table
                $page += "<table>`n"

                $tableLevel += 1

                # get column headers
                $headers = $line -split '\|' | % {

                    $header = $_.trim()

                    if ( $header.length -gt 0 ) {

                        "<th>`n$header`n</th>`n" } }

                # close the table row
                $page += "<tr>`n$headers</tr>`n"

                return }

            else {

                # skip the buffer rows ( | --- | )
                if ( $line -match '[^\|\-\s]' ) {

                    $cols = $line -split '\|' | % {

                        # capture and trim pipeline output
                        $data = $_.trim()

                        if ( $data.length -gt 0 ) {
                            # td wrap
                            "<td>`n$data`n</td>`n" } }

                    $page += "<tr>`n$( $cols -join '' )</tr>`n"
                    return }

                else { return } } }

        elseif ( $tableLevel -gt 0 ) {
            $page += "</table>`n" * ( $tableLevel )
            $tableLevel = 0 }

        # quotes
        $pattern = '^(>{1,})\s'
        if ( $line -match $pattern ) {

            # get delta of current line quote level vs. current quote level
            $quoteLevelDelta = ( select-string -pattern $pattern -inputobject $line ).matches.groups[ 1 ].value.length - $quoteLevel
            $quoteLevelDelta = [ system.math ]::max( $quoteLevelDelta, 0 )
            $quoteLevel += $quoteLevelDelta

            # open the quote tags
            $page += '<div class="quote">' * $quoteLevelDelta

            # add the quote
            $page += "$( $line -replace $pattern )`n"
            return }

        elseif ( $quoteLevel -gt 0 ) {
            $page += "</div>`n" * $quoteLevel
            $quoteLevel = 0 }

        # code block
        $pattern = '```'

        # open the code block
        if ( $line -match $pattern -and !$codeBlockOpen ) {

            $line = $line -replace $pattern, '<div class="code-block">'

            $codeBlockOpen = $true

            if ( $line.trim().length -gt 0 ) {
                $page += $line }

            return }

        # close the code block
        elseif ( $line -match $pattern -and $codeBlockOpen ) {

            $page += $line -replace $pattern, '</div>'

            $codeBlockOpen = $false

            return }

        # add line in the code block
        elseif ( $codeBlockOpen ) {
            $page += $line
            return }

        # inline code
        $pattern = '`(.+?)`'
        if ( $line -match $pattern ) {
            $page += $line -replace $pattern, '<div class="code-inline">$1</div>'
            return }

        # horizontal rule
        if ( $line -eq '---' ) {
            $page += "<hr></hr>`n"
            return }

        # append line
        if ( $line.length -gt 0 ) {
            $page += if ( $line.endswith( "`n" ) ) {
                $line } else { "$line`n" } } }

    if ( $tableLevel -gt 1 ) {
        $page += "</table>`n" * $tableLevel }

    if ( $ulLevel -gt 1 ) {
        $page += "</ul>`n" * $ulLevel }

    set-content -path $Out -value ( $Template -f $page ) }

# --! Export Module Member(s) !--

Export-ModuleMember -Function ConvertTo-PosHTML
