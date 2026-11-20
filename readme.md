# publish-pwsh-module-action

Publish a PowerShell module to the PowerShell Gallery for an exact release tag. The action writes
the module manifest with the tag's version, tests it, and publishes with PSResourceGet on the
pinned PowerShell from [setup-pwsh-action](https://github.com/vhco-pro/setup-pwsh-action).

It does not check out code, compute a version or create tags. Run it from a release workflow that
starts on an exact tag, such as one `vhco-pro/version-workflow` pushes.

```yaml
steps:
  - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
    with:
      persist-credentials: false
  - uses: michielvha/publish-pwsh-module-action@FULL_COMMIT_SHA # vX.Y.Z
    with:
      module-path: src/MyModule
      tag: ${{ github.ref_name }}
      api-key: ${{ secrets.PSGALLERY_API_KEY }}
      root-module: MyModule
      description: What the module does
      company-name: My Company
      author: My Name
      release-notes: https://github.com/owner/repo/releases/tag/${{ github.ref_name }}
```

Replace the placeholder with a released commit and its tag.

## Inputs

| Input | Default | Purpose |
| --- | --- | --- |
| `module-path` | required | Directory holding `<root-module>.psm1` |
| `tag` | required | Exact stable tag such as `v1.2.3` |
| `api-key` | required | API key for the repository |
| `root-module` | required | Module name; the manifest becomes `<root-module>.psd1` |
| `description` | required | Manifest description |
| `company-name` | required | Manifest company name |
| `author` | required | Manifest author |
| `release-notes` | empty | Manifest release notes, such as a link to the GitHub Release |
| `repository` | `PSGallery` | PSResourceGet repository to publish to |

## Behaviour

| Situation | Result |
| --- | --- |
| `v1.2.3` | Publishes version `1.2.3` |
| Prerelease tag, tag without `v`, or not three-part | Fails before writing the manifest |
| Version already in the repository | Ends as already published; nothing is published again |

A published Gallery version cannot change, so a retried release run is safe.

## Upgrading from v2

v3 is release-only. It no longer runs GitVersion, pushes tags or reads the last commit message, and
it publishes only the tag it is given. The inputs change: `psd1Path`, `psm1Path`, `rootModule`,
`companyName` and `apiKey` become `module-path`, `root-module`, `company-name` and `api-key`, and
`tag`, `author`, `release-notes` and `repository` are new. Callers move the version decision to their
release workflow.

## Tests

`tests/` holds Pester tests: unit tests for the tag conversion and an end-to-end publish to a local
folder repository. [`test.yml`](.github/workflows/test.yml) runs them through
`vhco-pro/pwsh-ci-action`, lints the workflows, and runs the action itself against a local repository
twice to prove the second run publishes nothing.
