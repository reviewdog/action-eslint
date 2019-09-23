# GitHub Action: Run eslint with reviewdog

[![Docker Image CI](https://github.com/reviewdog/action-eslint/workflows/Docker%20Image%20CI/badge.svg)](https://github.com/reviewdog/action-eslint/actions)
[![Release](https://img.shields.io/github/release/reviewdog/action-eslint.svg?maxAge=43200)](https://github.com/reviewdog/action-eslint/releases)

This action runs [eslint](https://github.com/eslint/eslint) with
[reviewdog](https://github.com/reviewdog/reviewdog) on pull requests to improve
code review experience.

[![github-pr-check sample](https://user-images.githubusercontent.com/3797062/65406379-54848e00-de1a-11e9-8464-1037e1cacf80.png)](https://github.com/reviewdog/action-eslint/pull/1)
[![github-pr-review sample](https://user-images.githubusercontent.com/3797062/65406408-6d8d3f00-de1a-11e9-90dd-d39aa3e19e7f.png)](https://github.com/reviewdog/action-eslint/pull/1)

## Inputs

### `github_token`

**Required**. Must be in form of `github_token: ${{ secrets.github_token }}`'.

### `level`

Optional. Report level for reviewdog [info,warning,error].
It's same as `-level` flag of reviewdog.

### `reporter`

Reporter of reviewdog command [github-pr-check,github-pr-review].
Default is github-pr-check.
github-pr-review can use Markdown and add a link to rule page in reviewdog reports.

### `eslint_flags`

Optional. Flags and args of eslint command. Default: '.'

## Example usage

You also need to install [eslint](https://github.com/eslint/eslint).

```shell
# Example
$ npm install eslint -D
```

You can create [eslint
config](https://eslint.org/docs/user-guide/configuring)
and this action uses that config too.

### [.github/workflows/reviewdog.yml](.github/workflows/reviewdog.yml)

```yml
name: reviewdog
on: [pull_request]
jobs:
  eslint:
    name: runner / eslint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v1
      - name: eslint
        uses: reviewdog/action-eslint@v1
        with:
          github_token: ${{ secrets.github_token }}
          reporter: github-pr-review # Change reporter.
          eslint_flags: 'src/'
```
