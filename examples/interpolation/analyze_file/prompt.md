# File Analysis

I'm going to analyze the file at: <%= workflow.file %>

First, let me gather some basic information about the file:

1. File name: `<%= File.basename(workflow.file) %>`
2. File extension: `<%= File.extname(workflow.file).sub('.', '') %>`
3. File size: `<%= File.size(workflow.file) %> bytes`

---

Can you read the file for me so I can analyze it?