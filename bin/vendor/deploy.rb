#!/usr/bin/env ruby

ANALYTICS_FILE = File.join(File.dirname(__FILE__), 'analytics.html')
LAYOUT_FILE = File.join(File.dirname(__FILE__), '..', '..', 'views', 'layout.slim')

# Replace analytics script in layout
layout_content = File.read(LAYOUT_FILE)
analytics_content = File.read(ANALYTICS_FILE)

layout_content.gsub!('<!--ANALYTICS-->', analytics_content)

File.write(LAYOUT_FILE, layout_content)
