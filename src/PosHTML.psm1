
#region Markdown-HTML Token Mapping

# html tag management
class Tag {

    [ string ] $_tag
    [ string ] $_attributes

    # default class constructor
    Tag( [ string ] $tag ) {

        $this._tag = $tag

    }

    # class constructor, overloaded with attributes param
    Tag( [ string ] $tag, [ string[] ] $attributes ) {

        $this._tag        = $tag
        $this._attributes = $attributes

    }

    # format tag open string
    [ string ] Open() {

        # determine attributes
        $attr_str = if ( $this._attributes ) { ' ' + $this._attributes -join ' ' } else { '' }

        return @( '<', $this._tag, $attr_str, '>' ) -join ''

    }

    # format tag close string
    [ string ] Close() {

        return @( '</', $this._tag, '>' ) -join ''

    }

    # format attribute string
    [ string ] Attributes() {

        if ( $this._attributes ) { return ' ' + $this._attributes -join ' ' } else { return '' }

    }

    # check if the tag has attributes
    [ boolean ] HasAttributes() {

        return [ bool ]( $this._attributes )

    }

    # value-less tag wrap
    [ string ] wrap() {

        return $this.Open(), $this.Close(), "`n" -join ''

    }

    # tag wrap with value
    [ string ] wrap( [ string ] $value ) {

        return $this.Open(), $value.trim(), $this.Close(), "`n" -join ''

    }

    # tag wrap with value and no newline
    [ string ] wrap( [ string ] $value, [ bool ] $no_newline ) {

        return $this.Open(), $value.trim(), $this.Close() -join ''

    }
}

class LinkTag : Tag {


    LinkTag() : base( 'a' ) { }

    # hyperlink-only
    [ string ] wrap( [ string ] $link ) {

        return '<a href="', $link, '">', $link.trim(), '</a>' -join ''

    }

    # hyperlink with display text
    [ string ] wrap( [ string ] $link_text, [ string ] $link ) {

        return '<a href="', $link, '">', $link_text.trim(), '</a>' -join ''

    }
}

class PosHTMLDoc {

    [ string ] $page_title

    # html tags
    $h1        = [ Tag ]::new( 'h1'   )
    $h2        = [ Tag ]::new( 'h2'   )
    $h3        = [ Tag ]::new( 'h3'   )
    $div       = [ Tag ]::new( 'div'  )
    $span      = [ Tag ]::new( 'span' )
    $ul        = [ Tag ]::new( 'ul'   )
    $li        = [ Tag ]::new( 'li'   )
    $ol        = [ Tag ]::new( 'ol'   )
    $td        = [ Tag ]::new( 'td'   )
    $th        = [ Tag ]::new( 'th'   )
    $table     = [ Tag ]::new( 'table')
    $tr        = [ Tag ]::new( 'tr'   )
    $quote     = [ Tag ]::new( 'quote')
    $bold      = [ Tag ]::new( 'b'    )
    $italics   = [ Tag ]::new( 'i'    )
    $underline = [ Tag ]::new( 'u'    )
    $cb        = [ Tag ]::new( 'cb'   )
    $code      = [ Tag ]::new( 'code' )
    $hr        = [ Tag ]::new( 'hr'   )
    $link      = [ LinkTag ]::new()

    PosHTML( [ string ] $page_title ) {
        $this.page_title = $page_title
    }
}

# establish html tags

$h1        = [ Tag ]::new( 'h1'   )
$h2        = [ Tag ]::new( 'h2'   )
$h3        = [ Tag ]::new( 'h3'   )
$div       = [ Tag ]::new( 'div'  )
$span      = [ Tag ]::new( 'span' )
$ul        = [ Tag ]::new( 'ul'   )
$li        = [ Tag ]::new( 'li'   )
$ol        = [ Tag ]::new( 'ol'   )
$td        = [ Tag ]::new( 'td'   )
$th        = [ Tag ]::new( 'th'   )
$table     = [ Tag ]::new( 'table')
$tr        = [ Tag ]::new( 'tr'   )
$quote     = [ Tag ]::new( 'quote')
$bold      = [ Tag ]::new( 'b'    )
$italics   = [ Tag ]::new( 'i'    )
$underline = [ Tag ]::new( 'u'    )
$cb        = [ Tag ]::new( 'cb'   )
$code      = [ Tag ]::new( 'code' )
$hr        = [ Tag ]::new( 'hr'   )
$link      = [ LinkTag ]::new()

# default html skeleton
$htmlFormat = @'
<!DOCTYPE html>
<html>
    <head>
        <link rel="stylesheet" href="style.css">
        <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Roboto%20Mono">
        <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Roboto">
    </head>
    <body>
        <div class="header"></div>
        <div class="content-container">
            {0}
        </div>
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

#endregion

#region Markdown to HTML

function ConvertTo-PosHTML {
    param(
        [ parameter( mandatory = $true ) ]
        [ string ] $In,
        [ parameter( mandatory = $true ) ]
        [ string ] $Out,
        [ string ] $Template = $htmlFormat
    )

    # read markdown file by line and translate

    $page        = ''
    $indent      = ''
    $ulLevel    = 1
    $tableLevel = 1
    $quoteLevel = 0
    $cbOpen     = $false

    # iterate file lines
    Get-Content $In | % {

        # capture pipeline input
        $line = $_

        # get leading spaces
        try {

            $spaces = ( select-string -pattern '^(\s+)' -inputobject $line ).Matches.groups[ 1 ].value

        } catch {

            $spaces = ''

        } finally {

            # trim string
            $line = $line.trim()

            # get indent level
            $indentLevel = [ system.math ]::Floor( $spaces.length / 4 )

        }

        # bold text
        $pattern = '\*\*(?!\*)(.*?)\*\*'
        if ( $line -match $pattern ) {

            $repl = $bold.wrap( ( select-string $pattern -inputobject $line ).matches.groups[ 1 ].value, $true )
            $line = $line -replace $pattern, $repl

        }

        # italicized text
        $pattern = '\*(?!\*)(.*?)\*'
        if ( $line -match $pattern ) {

            $repl = $italics.wrap( ( select-string $pattern -inputobject $line ).matches.groups[ 1 ].value, $true )
            $line = $line -replace $pattern, $repl

        }

        # hyperlinks
        $pattern = '\[(.*?)\]\((.*?)\)'
        if ( $line -match $pattern ) {

            $mgroups = ( select-string $pattern -inputobject $line ).matches.groups
            $text, $url = $mgroups[ 1 ].value.trim(), $mgroups[ 2 ].value.trim()
            $repl = $link.wrap( $text, $url )
            $line = $line -replace $pattern, $repl

        }

        # underlined text
        $pattern = '_(.*?)_'
        if ( $line -match $pattern ) {

            $repl = $underline.wrap( ( select-string $pattern -inputobject $line ).matches.groups[ 1 ].value, $true )
            $line = $line -replace $pattern, $repl

        }

        # h3
        $pattern = '^###\s'
        if ( $line -match $pattern ) {

            $line = $line -replace $pattern
            $page += $h3.wrap( $line )
            return

        }

        # h2
        $pattern = '^##\s'
        if ( $line -match $pattern ) {

            $line = $line -replace $pattern
            $page += $h2.wrap( $line )
            return

        }

        # h1
        $pattern = '^#\s'
        if ( $line -match $pattern ) {

            $line = $line -replace $pattern
            $page += $h1.wrap( $line )
            return

        }

        # unordered lists
        $pattern = '^-\s'
        if ( $line -match $pattern ) {

            $line = $line -replace $pattern

            # open the unordered list, if necessary
            if ( $ulLevel -eq 1 -or $indentLevel -gt $ulLevel ) {

                $ulLevel += 1
                $page += "$( $ul.Open() )`n"

            }

            # add the list item
            $page += $li.wrap( $line )
            return

        # close any open lists
        } elseif ( $ulLevel -gt 1 ) {

            $page += ( "$( $ul.Close() )`n" ) * ( $ulLevel - 1 )
            $ulLevel = 1

        }

        # callouts
        $pattern = '^\{(.*?)\}'
        if ( $line -match $pattern ) {

            $line = $line -replace $pattern, '$1'
            $page += $calloutFormat -f $line.trim()
            return

        }

        # tables
        $pattern = '^\|.*\|$'
        if ( $line -match $pattern ) {

            if ( $tableLevel -eq 1 ) {

                $page += "$( $table.Open() )`n"
                $tableLevel += 1

                # get column headers
                $headers = $line -split '\|' | % {

                    $header = $_.trim()

                    if ( $header.length -gt 0 ) {

                        $th.wrap( $_ )

                    }
                }

                # close the table row
                $page += $tr.wrap( $headers )
                return

            } else {

                # skip the buffer rows ( | --- | )
                if ( $line -match '[A-Za-z0-9]' ) {

                    $cols = $line -split '\|' | % {

                        # capture and trim pipeline output
                        $data = $_

                        if ( $data.length -gt 0 ) {

                            # td wrap
                            $td.wrap( $data )

                        }
                    }

                    $page += $tr.wrap( $cols -join '' )
                    return

                } else { return }
            }
        } elseif ( $tableLevel -gt 1 ) {

            $page += ( "$( $table.Close() )`n" ) * ( $tableLevel - 1 )
            $tableLevel = 1

        }

        # quotes
        $pattern = '^(>{1,})\s'
        if ( $line -match $pattern ) {

            # get number of leading symbols
            $quoteLevelDelta = ( select-string $pattern -inputobject $line ).matches.groups[ 1 ].value.length - $quoteLevel
            $quoteLevelDelta = [ system.math ]::Max( $quoteLevelDelta, 0 )
            $quoteLevel += $quoteLevelDelta
            $page += "$( $quote.Open() )" * $quoteLevelDelta
            $line = $line -replace $pattern
            $page += "$( $line )`n"
            return

        } elseif ( $quoteLevel -gt 0 ) {

            $page += "$( $quote.Close() )`n" * ( $quoteLevel )
            $quoteLevel = 0

        }

        # code block
        $pattern = '```'
        if ( $line -match $pattern -and -not $cbOpen ) {

            $cbOpen = $true

            $line = $line -replace $pattern

            $page += "$( $cb.Open() )"
            if ( $line.trim().length -gt 0 ) {
                $page += "$( $line )`n" }
            return

        } elseif ( $line -match $pattern -and $cbOpen ) {

            $line = $line -replace $pattern
            if ( $line.trim().length -gt 0 ) {
                $page += "$( $line )`n" }

            $page += "$( $cb.Close() )`n"

            $cbOpen = $false

            return

        } elseif ( $cbOpen ) {

            $line = $line -replace $pattern
            if ( $line.trim().length -gt 0 ) {
                $page += "$( $line )`n" }

            return

        }

        # inline code
        $pattern = '`(.+?)`'
        if ( $line -match $pattern ) {

            $line = $line -replace $pattern, '$1'
            $page += $code.Wrap( $line )
            return

        }


        # horizontal rule
        if ( $line.trim() -eq '---' ) {

            $page += "$( $hr.Wrap() )`n"
            return

        }

        # append standard text lines
        $page += $line
    }

    if ( $tableLevel -gt 1 ) {

        $page += ( "$( $table.Close() )`n" ) * ( $tableLevel - 1 )

    }

    if ( $ulLevel -gt 1 ) {

        $page += ( "$( $ul.Close() )`n" ) * ( $ulLevel - 1 )

    }

    set-content -path $Out -value ( $Template -f $page )
}

#endregion

# --! Export Module Member(s) !--

Export-ModuleMember -Function ConvertTo-PosHTML
