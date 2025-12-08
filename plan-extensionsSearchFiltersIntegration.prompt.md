Goal: Integrate filters mental model from docs/Extensions_Search_Filters.md into docs/public/Verified_VSCode_Publishers.md generation.

Scope: Update src/scripts/generate_verified_markdown.ps1 to add global sections aligned with Marketplace filters, using existing verified data (data/processed/verified_publishers.json). Prioritize performant, readable aggregation. Keep current style and metadata.

---

## Section Skeletons & Anchors

### Updated TOC (insert after Quick Stats link)

```markdown
## 📑 Table of Contents

- [📊 Quick Stats](#-quick-stats)
- [🔥 Popular Extensions](#-popular-extensions)
- [⭐ Top Rated Extensions](#-top-rated-extensions)
- [🆕 Recently Updated](#-recently-updated)
- [🏷️ Extensions by Category](#-extensions-by-category)
- [🔎 Identifier Index](#-identifier-index)
- [🏆 Top 20 Publishers](#-top-20-publishers-by-total-installs)
- [🌐 Top 20 Domains](#-top-20-domains-by-extension-count)
- [📚 All Domains Directory](#-all-domains-directory)
- [🔗 Extensions by Domain](#-extensions-by-domain)
- [ℹ️ About This Document](#-about-this-document)
```

---

### 🔥 Popular Extensions

Anchor: `#-popular-extensions`

```markdown
---

## 🔥 Popular Extensions

> **Top 50 verified extensions by total installs** — mirrors Marketplace `@sort:installs`

| Rank | Extension | Publisher | Domain | Installs | Rating | Last Updated |
|:----:|-----------|-----------|--------|:--------:|:------:|:------------:|
| 🥇 | [**Python**](https://marketplace.visualstudio.com/items?itemName=ms-python.python) | [ms-python](#ms-python) | `microsoft.com` | **194.9M** | ⭐ 4.5 | 2025-12-04 |
| 🥈 | [**Pylance**](https://marketplace.visualstudio.com/items?itemName=ms-python.vscode-pylance) | [ms-python](#ms-python) | `microsoft.com` | **162.8M** | ⭐ 4.3 | 2025-11-28 |
| ... | ... | ... | ... | ... | ... | ... |

<details>
<summary><strong>📂 View all 711 extensions by installs</strong></summary>

| Rank | Extension | Publisher | Domain | Installs | Rating | Last Updated |
|:----:|-----------|-----------|--------|:--------:|:------:|:------------:|
| 51 | ... | ... | ... | ... | ... | ... |

</details>

<p align="right"><a href="#-table-of-contents">⬆️ Back to Top</a></p>
```

---

### ⭐ Top Rated Extensions

Anchor: `#-top-rated-extensions`

```markdown
---

## ⭐ Top Rated Extensions

> **Top 50 verified extensions by average rating** — mirrors Marketplace `@sort:rating` (tie-break: installs)

| Rank | Extension | Publisher | Domain | Rating | Installs | Reviews |
|:----:|-----------|-----------|--------|:------:|:--------:|:-------:|
| 🥇 | [**GitLens**](https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens) | [eamodio](#eamodio) | `gitkraken.com` | ⭐ **5.0** | 45.8M | 12.4K |
| ... | ... | ... | ... | ... | ... | ... |

<p align="right"><a href="#-table-of-contents">⬆️ Back to Top</a></p>
```

---

### 🆕 Recently Updated

Anchor: `#-recently-updated`

```markdown
---

## 🆕 Recently Updated

> **Extensions updated in the last 30 days** — mirrors Marketplace `@sort:updateDate`

| Extension | Publisher | Domain | Last Updated | Version | Installs |
|-----------|-----------|--------|:------------:|:-------:|:--------:|
| [**Python Debugger**](https://marketplace.visualstudio.com/items?itemName=ms-python.debugpy) | [ms-python](#ms-python) | `microsoft.com` | 2025-12-04 | `2025.17.x` | 100.3M |
| ... | ... | ... | ... | ... | ... |

<details>
<summary><strong>📂 View all 711 extensions by update date</strong></summary>

| Extension | Publisher | Domain | Last Updated | Version | Installs |
|-----------|-----------|--------|:------------:|:-------:|:--------:|
| ... | ... | ... | ... | ... | ... |

</details>

<p align="right"><a href="#-table-of-contents">⬆️ Back to Top</a></p>
```

---

### 🏷️ Extensions by Category

Anchor: `#-extensions-by-category`

```markdown
---

## 🏷️ Extensions by Category

> **Browse verified extensions grouped by Marketplace category** — mirrors `@category:"..."`

### Category Index

| Category | Extensions | Top Extension |
|----------|:----------:|---------------|
| [Programming Languages](#category-programming-languages) | 142 | Python (194.9M) |
| [Debuggers](#category-debuggers) | 87 | Python Debugger (100.3M) |
| [Linters](#category-linters) | 45 | ESLint (32.1M) |
| [Themes](#category-themes) | 38 | vscode-icons (22.8M) |
| ... | ... | ... |

---

### <a id="category-programming-languages"></a>📂 Programming Languages

| Extension | Publisher | Installs | Rating |
|-----------|-----------|:--------:|:------:|
| [**Python**](https://marketplace.visualstudio.com/items?itemName=ms-python.python) | [ms-python](#ms-python) | 194.9M | ⭐ 4.5 |
| ... | ... | ... | ... |

<p align="right"><a href="#-extensions-by-category">⬆️ Back to Categories</a> · <a href="#-table-of-contents">⬆️ Back to Top</a></p>

---

### <a id="category-debuggers"></a>🐛 Debuggers

| Extension | Publisher | Installs | Rating |
|-----------|-----------|:--------:|:------:|
| ... | ... | ... | ... |

<p align="right"><a href="#-extensions-by-category">⬆️ Back to Categories</a> · <a href="#-table-of-contents">⬆️ Back to Top</a></p>
```

---

### 🔎 Identifier Index

Anchor: `#-identifier-index`

```markdown
---

## 🔎 Identifier Index

> **Alphabetical listing by extension identifier** — use with Marketplace `@id:publisher.extension`

<details>
<summary><strong>📂 Click to expand all 711 identifiers (A–Z)</strong></summary>

| # | Identifier | Name | Publisher | Links |
|--:|------------|------|-----------|:-----:|
| 1 | `42crunch.vscode-openapi` | OpenAPI (Swagger) Editor | 42Crunch | [🏪](https://marketplace.visualstudio.com/items?itemName=42crunch.vscode-openapi) |
| 2 | `alefragnani.project-manager` | Project Manager | alefragnani | [🏪](https://marketplace.visualstudio.com/items?itemName=alefragnani.project-manager) |
| ... | ... | ... | ... | ... |

</details>

<p align="right"><a href="#-table-of-contents">⬆️ Back to Top</a></p>
```

---

### 🏅 Domain Leaderboards (optional enhancement)

Anchor: `#-domain-leaderboards`

```markdown
---

## 🏅 Domain Leaderboards

> **Verified domains ranked by total install count across all their extensions**

| Rank | Domain | Publishers | Extensions | Total Installs | Top Extension |
|:----:|--------|:----------:|:----------:|:--------------:|---------------|
| 🥇 | `microsoft.com` | 56 | 224 | **2.1B** | Python (194.9M) |
| 🥈 | `github.com` | 1 | 10 | **182M** | GitHub Copilot (98.2M) |
| 🥉 | `gitkraken.com` | 1 | 1 | **45.8M** | GitLens |
| ... | ... | ... | ... | ... | ... |

<p align="right"><a href="#-table-of-contents">⬆️ Back to Top</a></p>
```

---

## Implementation Plan

### Phase 1: Data Aggregation Helpers
- [ ] Add `Build-GlobalExtensionsList` — flatten all publisher extensions into single array
- [ ] Add `Group-ExtensionsByCategory` — hashtable keyed by category
- [ ] Add `Get-UniqueCategories` — sorted list of all categories
- [ ] Add `Format-ExtensionTableRow` — reusable row formatter

### Phase 2: Popular Extensions Section
- [ ] Insert TOC entry after Quick Stats
- [ ] Add section skeleton after Quick Stats
- [ ] Sort global list by installs desc; render top 50 + collapsible rest

### Phase 3: Top Rated Extensions Section
- [ ] Add section skeleton
- [ ] Sort by rating desc, installs desc; render top 50

### Phase 4: Recently Updated Section
- [ ] Add section skeleton
- [ ] Sort by lastUpdated desc; render extensions from last 30 days + collapsible full list

### Phase 5: Extensions by Category Section
- [ ] Add section skeleton with category index table
- [ ] Loop each category; render subsection with anchor and table

### Phase 6: Identifier Index Section
- [ ] Add section skeleton
- [ ] Sort alphabetically by id; render collapsible full list

### Phase 7: Domain Leaderboards (optional)
- [ ] Add section skeleton
- [ ] Aggregate installs per domain; render ranked table

### Phase 8: Validation & Polish
- [ ] Run locally; verify anchor navigation
- [ ] Check BUILD_METADATA includes new counts
- [ ] Confirm CI timing acceptable

---

## Acceptance Criteria
- [ ] TOC links resolve to all new sections
- [ ] Popular, Top Rated, Recently Updated, By Category, Identifier Index sections present
- [ ] Collapsibles wrap tables > 50 rows
- [ ] Anchors use `ConvertTo-Anchor` output (lowercase, hyphenated)
- [ ] BUILD_METADATA includes: publishers, extensions, domains, categories
- [ ] Footer Build line preserved
- [ ] CI completes within time budget