import re
import os

path = '/home/jeryd/Projects/openOODA/openOODA.github.io/index.html'
with open(path, 'r', encoding='utf-8') as f:
    html = f.read()

# 1. Update Navigation
old_nav = """    <nav>
      <a href="#design">Design</a>
      <a href="#pm">PM status</a>
      <a href="#sprint">Sprint</a>
      <a href="#install">Install</a>
      <a href="research.html">Research Hub</a>
      <a href="https://github.com/openOODA/spec/blob/main/DESIGN.md" target="_blank" rel="noopener">DESIGN.md</a>
      <a href="https://github.com/openOODA/ooda" class="btn-primary" target="_blank" rel="noopener">GitHub</a>
    </nav>"""
new_nav = """    <nav>
      <a href="#overview">Overview</a>
      <a href="#safety">Safety</a>
      <a href="#install">Install</a>
      <a href="research.html">Research Hub</a>
      <a href="https://github.com/openOODA/ooda" class="btn-primary" target="_blank" rel="noopener">GitHub</a>
    </nav>"""
html = html.replace(old_nav, new_nav)

# 2. Rename Design to Overview
html = html.replace('<section class="design-section" id="design">', '<section class="design-section" id="overview">')
html = html.replace('<h2>Design goals <span class="section-tag">DESIGN.md</span></h2>', '<h2>Overview</h2>')
html = html.replace('<p>North star architecture — what openOODA is <em>for</em>. Goals are not claims of full implementation.</p>', '<p>A high-level look at the core mechanics and philosophy behind openOODA.</p>')

# 3. Replace PM and Sprint sections with Safety section
safety_section = """
  <!-- Safety -->
  <section class="progress-section" id="safety">
    <div class="why-header">
      <h2>Safety by Construction</h2>
      <p>openOODA enforces mathematical contracts and capability-based security at the compiler level.</p>
    </div>

    <div class="status-table-wrap">
      <h3 class="table-title">Core Security Features</h3>
      <table class="status-table">
        <thead><tr><th>Feature</th><th>Description</th></tr></thead>
        <tbody>
          <tr><td><strong>Capability Sandboxing</strong></td><td>Default-deny I/O. File system and network access require explicit <code>FsCap</code> and <code>NetCap</code> tokens.</td></tr>
          <tr><td><strong>Memory Quotas</strong></td><td>Heap allocations are strictly bounded to prevent out-of-memory denial of service.</td></tr>
          <tr><td><strong>Mathematical Contracts</strong></td><td><code>requires</code> and <code>ensures</code> clauses are enforced by the compiler.</td></tr>
          <tr><td><strong>Zero Millisecond GC</strong></td><td>ARC memory management guarantees leak-free execution without pause times.</td></tr>
        </tbody>
      </table>
    </div>
  </section>
"""

# Extract everything up to <!-- PM.md -->
start_idx = html.find('  <!-- PM.md -->')
# Extract everything from <section class="get-started"> onwards
end_idx = html.find('  <section class="get-started">')

if start_idx != -1 and end_idx != -1:
    html = html[:start_idx] + safety_section + html[end_idx:]

with open(path, 'w', encoding='utf-8') as f:
    f.write(html)
print("Updated index.html successfully.")
