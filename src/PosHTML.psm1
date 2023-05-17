
#region Markdown-HTML Token Mapping

# html tag management
class Tag {

    [ string ] $tag
    [ string ] $_attributes

    # default class constructor
    Tag( [ string ] $tag ) {

        $this.tag = $tag

    }

    # class constructor, overloaded with attributes param
    Tag( [ string ] $tag, [ string[] ] $attributes ) {

        $this.tag = $tag
        $this._attributes = $attributes

    }

    # format tag open string
    [ string ] Open() {

        # determine attributes
        $attr_str = if ( $this._attributes ) { ' ' + $this._attributes -join ' ' } else { '' }

        return @( '<', $this.tag, $attr_str, '>' ) -join ''

    }

    # format tag close string
    [ string ] Close() {

        return @( '</', $this.tag, '>' ) -join ''

    }

    # format attribute string
    [ string ] Attributes() {

        if ( $this._attributes ) { return ' ' + $this._attributes -join ' ' } else { return '' }

    }

    # check if the tag has attributes
    [ boolean ] HasAttributes() {

        return [ bool ]( $this._attributes )

    }

    [ string ] Wrap( [ string ] $value ) {

        return $this.Open(), $value.Trim(), $this.Close(), "`n" -join ''

    }

    [ string ] Wrap( [ string ] $value, [ bool ] $no_newline ) {

        return $this.Open(), $value.Trim(), $this.Close() -join ''

    }
}

class LinkTag : Tag {


    LinkTag() : base( 'a' ) { }

    # hyperlink-only
    [ string ] Wrap( [ string ] $link ) {

        return '<a href="', $link, '">', $link.Trim(), '</a>' -join ''

    }

    # hyperlink with display text
    [ string ] Wrap( [ string ] $link_text, [ string ] $link ) {

        return '<a href="', $link, '">', $link_text.Trim(), '</a>' -join ''

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
$link      = [ LinkTag ]::new()

# base html file format
$html_format = @'
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
$callout_format = @'
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

function Convert-MDToHTML {
    param(
        [ parameter( mandatory = $true ) ]
        [ string ] $In,
        [ parameter( mandatory = $true ) ]
        [ string ] $Out,
        [ string ] $Template = $html_format
    )

    # read markdown file by line and translate

    $page        = ''
    $indent      = ''
    $ul_level  = 1
    $table_level = 1
    $quote_level = 1

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
            $indent_level = [ system.math ]::Floor( $spaces.length / 4 )

        }

        # bold text
        $pattern = '\*\*(?!\*)(.*?)\*\*'
        if ( $line -match $pattern ) {

            $repl = $bold.Wrap( ( select-string $pattern -inputobject $line ).matches.groups[ 1 ].value, $true )
            $line = $line -replace $pattern, $repl

        }

        # italicized text
        $pattern = '\*(?!\*)(.*?)\*'
        if ( $line -match $pattern ) {

            $repl = $italics.Wrap( ( select-string $pattern -inputobject $line ).matches.groups[ 1 ].value, $true )
            $line = $line -replace $pattern, $repl

        }

        # hyperlinks
        $pattern = '\[(.*?)\]\((.*?)\)'
        if ( $line -match $pattern ) {

            $match = select-string $pattern -inputobject $line
            $text, $url = $match.matches.groups[ 1 ].value.Trim(), $match.matches.groups[ 2 ].value.Trim()
            $repl = $link.Wrap( $text, $url )
            $line = $line -replace $pattern, $repl

        }

        # underlined text
        $pattern = '_(.*?)_'
        if ( $line -match $pattern ) {

            $repl = $underline.Wrap( ( select-string $pattern -inputobject $line ).matches.groups[ 1 ].value, $true )
            $line = $line -replace $pattern, $repl

        }

        # h3
        $pattern = '^###\s'
        if ( $line -match $pattern ) {

            $line = $line -replace $pattern, ''
            $page += $h3.Wrap( $line )
            return

        }

        # h2
        $pattern = '^##\s'
        if ( $line -match $pattern ) {

            $line = $line -replace $pattern, ''
            $page += $h2.Wrap( $line )
            return

        }

        # h1
        $pattern = '^#\s'
        if ( $line -match $pattern ) {

            $line = $line -replace $pattern, ''
            $page += $h1.Wrap( $line )
            return

        }

        # unordered lists
        $pattern = '^-\s'
        if ( $line -match $pattern ) {

            $line = $line -replace $pattern, ''

            # open the unordered list, if necessary
            if ( $ul_level -eq 1 -or $indent_level -gt $ul_level ) {

                $ul_level += 1
                $page += "$( $ul.Open() )`n"

            }

            # add the list item
            $page += $li.Wrap( $line )
            return

        # close any open lists
        } elseif ( $ul_level -gt 1 ) {

            $page += ( "$( $ul.Close() )`n" ) * ( $ul_level - 1 )
            $ul_level = 1

        }

        # callouts
        $pattern = '^\{(.*?)\}'
        if ( $line -match $pattern ) {

            $line = $line -replace $pattern, '$1'
            $page += $callout_format -f $line.Trim()
            return

        }

        # tables
        $pattern = '^\|.*\|$'
        if ( $line -match $pattern ) {

            if ( $table_level -eq 1 ) {

                $page += "$( $table.Open() )`n"
                $table_level += 1

                # get column headers
                $headers = $line -split '\|' | % {

                    $header = $_.Trim()

                    if ( $header.length -gt 0 ) {

                        $th.Wrap( $_ )

                    }
                }

                # close the table row
                $page += $tr.Wrap( $headers )
                return

            } else {

                # skip the buffer rows
                if ( $line -match '[A-Za-z0-9]' ) {

                    $cols = $line -split '\|' | % {

                        # capture and trim pipeline output
                        $data = $_

                        if ( $data.length -gt 0 ) {

                            # td wrap
                            $td.Wrap( $data )

                        }
                    }

                    $page += $tr.Wrap( $cols -join '' )
                    return

                }
            }
        } elseif ( $table_level -gt 1 ) {

            $page += ( "$( $table.Close() )`n" ) * ( $table_level - 1 )
            $table_level = 1

        }

        # quotes
        $pattern = '^>{1,}\s'
        if ( $line -match $pattern ) {

            $line = $line -replace $pattern, ''
            $page += $quote.Wrap( $line )
            return

        }

        # append standard text lines
        $page += $line
    }

    if ( $table_level -gt 1 ) {

        $page += ( "$( $table.Close() )`n" ) * ( $table_level - 1 )

    }

    if ( $ul_level -gt 1 ) {

        $page += ( "$( $ul.Close() )`n" ) * ( $ul_level - 1 )

    }

    set-content -path $Out -value ( $Template -f $page )
}

#endregion

# --! Export Module Member(s) !--

Export-ModuleMember -Function Convert-MDToHTML
