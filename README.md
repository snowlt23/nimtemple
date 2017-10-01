
# nimtemple

**warning**: This library is still in development.

nimtemple is a template engine by pure Nim implementation.  
Syntax is Jinja and Go template like.

# Syntax

### variable
```
{{ $varname }}
```

### if
```
{{ if $boolvar }}
TRUE!
{{ else }}
FALSE!
{{ end }}
```

### for
```
{{ for elem in $seqvar }}
<li>{{ $elem }}</li>
{{ end }}
```


### strip
```
{{ - if $boolvar }}
DO IT
{{ end }}
```

### extends
```
<!-- extends.html -->
{{ extends "parent.html" }}
{{ define title }}
ZUNDA
{{ end }}

<!-- parent.html -->
<title>{{ - define title }}{{ end }}</title>

<!-- output => -->
<title>ZUNDA</title>
```

### include
```
{{ include "header.html" }}
```

# Install

```
nimble install https://github.com/snowlt23/nimtemple
```

# Usage

```
var tmpl = initTempleRenderer()
tmpl["persons"] = %* ["Yukari", "Maki", "Akane", "Aoi"]
echo tmpl.renderFile("for.html")
```

