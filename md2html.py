#!/usr/bin/python
# covert markdown to html

import sys
import markdown

text = sys.stdin.read()
html = markdown.markdown(text, ['markdown.extensions.extra'])
print("<style>\ntable, th, td {\n border: 1px solid black;\n }</style>")
print(html)
