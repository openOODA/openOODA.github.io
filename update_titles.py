import os
import re
import json

base_dir = "/home/jeryd/Projects/openOODA/openOODA.github.io"
research_dir = os.path.join(base_dir, "research")
html_path = os.path.join(base_dir, "research.html")

papers = []
for filename in sorted(os.listdir(research_dir)):
    if filename.startswith("RP-") and filename.endswith(".oot"):
        path = os.path.join(research_dir, filename)
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
            title = filename
            m = re.search(r'^#\s+(.+)$', content, re.MULTILINE)
            if m:
                title = m.group(1).strip()
            # fallback if no H1, maybe they used Title: or something
            elif "Abstract" in content:
                # keep filename as title if no H1
                pass
            
            papers.append({
                "file": "research/" + filename,
                "title": title
            })

papers_json = json.dumps(papers)

with open(html_path, "r", encoding="utf-8") as f:
    html = f.read()

# Replace the papers array
new_html = re.sub(r'const papers = \[.*?\];', f'const papers = {papers_json};', html, flags=re.DOTALL)

with open(html_path, "w", encoding="utf-8") as f:
    f.write(new_html)

print("Updated research.html with new titles.")
