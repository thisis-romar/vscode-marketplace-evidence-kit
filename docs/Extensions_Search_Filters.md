# VS Code Extensions Search Filters

A practical, cited guide to the Extensions view search filters and sorting syntax in Visual Studio Code. These filters work in the Extensions sidebar (`Ctrl+Shift+X`) search box.

> Official documentation: VS Code Extension Marketplace — Extensions view filters  
> https://code.visualstudio.com/docs/editor/extension-marketplace#_extensions-view-filters

---

## Why use filters?

Filters help you quickly find, manage, and refine extension results by status, popularity, category, tags, and more. They can be **combined** (space-separated) and support **sorting**.

---

## Core Filters

- `@installed`: Show installed extensions
- `@enabled`: Show installed and enabled extensions
- `@disabled`: Show installed and disabled extensions
- `@updates`: Show installed extensions with available updates
- `@deprecated`: Show deprecated extensions
- `@builtin`: Show built-in extensions (shipped with VS Code)
- `@workspaceUnsupported`: Show extensions unsupported for this workspace

Source: https://code.visualstudio.com/docs/editor/extension-marketplace#_extensions-view-filters

---

## Discovery Filters

- `@featured`: Show **featured** extensions (curated by VS Code/Microsoft)
- `@popular`: Show **globally popular** extensions (by install count)
- `@recentlyPublished`: Show recently published extensions on the Marketplace
- `@recommended`: Show recommended extensions  
  - Grouped as Workspace Recommendations and Other Recommendations

Source: https://code.visualstudio.com/docs/editor/extension-marketplace#_extensions-view-filters

---

## Category and Tag Filters

- `@category:<name>`: Filter by extension category
  - Examples: `@category:themes`, `@category:linters`, `@category:formatters`, `@category:snippets`
  - If the category has spaces, use quotes: `@category:"SCM Providers"`
- `tag:<name>`: Filter by an extension-defined tag (free-form text)

Supported categories list and IntelliSense in the search box:  
https://code.visualstudio.com/docs/editor/extension-marketplace#_categories-and-tags

---

## Identifier Filter

- `@id:publisher.extension`: Filter by exact extension identifier
  - Example: `@id:ms-python.python`

Source: https://code.visualstudio.com/docs/editor/extension-marketplace#_search-for-an-extension

---

## Sorting Filters

Use `@sort:<key>` to sort results:

- `@sort:installs` — Sort by install count (descending)
- `@sort:rating` — Sort by Marketplace rating (descending)
- `@sort:name` — Sort alphabetically
- `@sort:publishedDate` — Sort by published date
- `@sort:updateDate` — Sort by last update date

Source: https://code.visualstudio.com/docs/editor/extension-marketplace#_sorting

---

## Combination Examples

Combine filters by separating them with spaces:

```text
@featured @category:themes @sort:rating
```

- Show featured theme extensions, sorted by rating

```text
@installed @category:linters @sort:installs
```

- Show installed linter extensions, sorted by install count

```text
@popular tag:ai @sort:installs
```

- Show popular extensions tagged with "ai", sorted by installs

```text
@enabled @updates
```

- Show enabled extensions that have updates available

```text
@builtin @category:"Programming Languages" @sort:name
```

- Show built-in language features, sorted by name

---

## Practical Search Tips

- Type `@` in the Extensions search box to see **IntelliSense for filters and categories**
- Use `@id:<publisher.extension>` when you know the exact extension you want
- Categories support IntelliSense; tags do not (review Marketplace pages for useful tags)
- Filters are evaluated in the Extensions view, not the Marketplace web UI

Sources:
- Extensions view filters: https://code.visualstudio.com/docs/editor/extension-marketplace#_extensions-view-filters
- Sorting: https://code.visualstudio.com/docs/editor/extension-marketplace#_sorting
- Categories and tags: https://code.visualstudio.com/docs/editor/extension-marketplace#_categories-and-tags
- Identifier search: https://code.visualstudio.com/docs/editor/extension-marketplace#_search-for-an-extension

---

## Featured vs Popular

- `@featured`: Curated showcase by the VS Code team; high-quality, notable extensions  
- `@popular`: Extensions ranked by **install count** across all users

Source: https://code.visualstudio.com/docs/editor/extension-marketplace#_extensions-view-filters

---

## Workspace Recommendations

VS Code can recommend extensions based on your workspace files or a shared `.vscode/extensions.json` file.

- View recommendations: `@recommended`
- Configure workspace recommendations:  
  https://code.visualstudio.com/docs/editor/extension-marketplace#_workspace-recommended-extensions

---

## Command-Line Management (Bonus)

List, install, and uninstall extensions from the command line:

```bash
code --list-extensions
code --show-versions
code --install-extension ms-python.python
code --uninstall-extension esbenp.prettier-vscode
```

Source: https://code.visualstudio.com/docs/editor/extension-marketplace#_command-line-extension-management

---

## FAQ

- If the network uses a proxy, configure VS Code proxy settings:  
  https://code.visualstudio.com/docs/setup/network#_proxy-server-support
- Built-in extensions are grouped by type; use `@builtin` to view them
- Pre-release versions: install via the extension details dropdown

General page: https://code.visualstudio.com/docs/editor/extension-marketplace
